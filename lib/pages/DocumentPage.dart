import 'dart:ui';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:igm_self_kyc/IgmNetworkHelper.dart';
import 'package:igm_self_kyc/utils/GuiUtils.dart';
import 'package:igm_self_kyc/utils/ImageUtils.dart';
import 'package:image/image.dart' as imgLib;
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:igm_self_kyc/ThemeConstants.dart';
import 'package:igm_self_kyc/models/DocumentDTO.dart';
import 'package:igm_self_kyc/models/DocumentFileDTO.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';

class DocumentPage extends StatefulWidget {
  DocumentPage({Key key, @required this.documentType}) : super(key: key);

  final DocumentType documentType;

  @override
  _DocumentPageState createState() {
    return _DocumentPageState();
  }
}

class _DocumentPageState extends State<DocumentPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // to show the options of where to upload images from
  var _imagePickerOptions = false;
  File _selfieFile;
  File _frontFile;
  File _backFile;
  String _loadingMessage;
  bool _showCloseWindowButton = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DocumentDTO currentDocument;
    String pageTitle;
    bool canUseSelectFiles = false;
    List<String> cardTitles;
    List<String> cardTutorialImageLocations;

    switch (widget.documentType) {
      case DocumentType.idBook:
        currentDocument = IgmNetworkHelper.getInstance().currentProfileObject.getIdBook();
        pageTitle = "ID Book";
        cardTitles = ["Selfie with ID book", "Inside of ID Book"];
        cardTutorialImageLocations = ["idBook_selfie", "idBook_inside"];
        canUseSelectFiles = true;
        break;

      case DocumentType.idCard:
        currentDocument = IgmNetworkHelper.getInstance().currentProfileObject.getIdCard();
        pageTitle = "ID Card";
        cardTitles = ["Selfie with ID Card", "Front of ID Card", "Back of ID Card"];
        cardTutorialImageLocations = ["idCard_selfie", "idCard_front", "idCard_back"];
        canUseSelectFiles = true;
        break;

      case DocumentType.passport:
        currentDocument = IgmNetworkHelper.getInstance().currentProfileObject.getPassport();
        pageTitle = "Passport";
        cardTitles = ["Selfie with Passport", "Inside of Passport"];
        cardTutorialImageLocations = ["passport_selfie", "passport_inside"];
        canUseSelectFiles = true;
        break;

      case DocumentType.proofOfResidence:
        currentDocument = IgmNetworkHelper.getInstance().currentProfileObject.getPor();
        pageTitle = "Proof of Address";
        cardTitles = ["Photo of the full document"];
        cardTutorialImageLocations = ["proof_of_residence"];
        canUseSelectFiles = true;
        break;
    }

    List<Widget> cards = [];

    // go through each type and build its configuration
    for (int i = 0; i < cardTitles.length; i++) {
      DocumentFileDTO fileInQuestion;
      File imageFile;

      if (widget.documentType == DocumentType.proofOfResidence) {
        i = 1; // POR only used the front file here
      }

      switch (i) {
        case 0:
          fileInQuestion = currentDocument.getSelfie();
          imageFile = _selfieFile;
          break;
        case 1:
          fileInQuestion = currentDocument.getFront();
          imageFile = _frontFile;
          break;
        case 2:
          fileInQuestion = currentDocument.getBack();
          imageFile = _backFile;
          break;
      }

      // defaults
      bool canUpload = true;
      String statusString = "tap to add";
      Color cardColor = ThemeConstants.cardColorNew;

      switch (currentDocument.getStatus()) {
        case DocumentStatus.partial:
          if (fileInQuestion != null) {
            statusString = "captured";
            canUpload = false;
            cardColor = ThemeConstants.cardColorSelected;
          } else {
            statusString = "tap to add";
            canUpload = true;
            cardColor = ThemeConstants.cardColorNew;
          }
          break;

        case DocumentStatus.complete:
          canUpload = false;
          statusString = "verified";
          cardColor = ThemeConstants.cardColorPass;
          break;

        case DocumentStatus.pending:
          canUpload = false;
          if (currentDocument.delayed) {
            statusString = "pending manual validation";
          } else {
            statusString = "pending validation";
          }
          cardColor = ThemeConstants.cardColorPending;
          break;

        case DocumentStatus.error:
          canUpload = true;
          if (imageFile != null) {
            statusString = "tap to change";
            cardColor = ThemeConstants.cardColorSelected;
            fileInQuestion = DocumentFileDTO();
          } else {
            statusString = "tap to add";
            cardColor = ThemeConstants.cardColorError;
          }
          break;

        case DocumentStatus.none:
          canUpload = true;
          if (imageFile != null) {
            cardColor = ThemeConstants.cardColorSelected;
            statusString = "tap to change";
          } else {
            cardColor = ThemeConstants.cardColorNew;
            statusString = "tap to add";
          }
          break;
      }

      cards.add(StatusCardWithTutorial(
        title: cardTitles[widget.documentType == DocumentType.proofOfResidence ? 0 : i],
        status: statusString,
        cardColor: cardColor,
        isSelectable: canUpload,
        onTap: () {
          if (canUpload) {
            _cardTapped(type: DocumentFileType.values[i], canUseCamera: canUseSelectFiles);
          }
        },
        tutorialImageLocation: "assets/images/tutorials/" + cardTutorialImageLocations[widget.documentType == DocumentType.proofOfResidence ? 0 : i] + ".png",
        selectedImage: imageFile,
        cardFile: fileInQuestion,
        docTypeString: DocumentDTO.getFileTypeForEnum(widget.documentType),
      ));
    }

    // load the body into a stack, then we can layer the view fro controls later
    List<Widget> scaffoldChildren = [
      Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
        child: ListView(
          padding: EdgeInsets.only(left: ThemeConstants.paddingHalved, right: ThemeConstants.paddingHalved, top: 0, bottom: ThemeConstants.padding),
          children: cards,
        ),
      )
    ];

    // create a frame to accept touches, if the bottom sheet is open, this is to improve the UX and closing of the bottom sheet
    if (_imagePickerOptions) {
      scaffoldChildren.add(Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
        child: GestureDetector(
          onTap: () {
            _closeImageOptions();
          },
          onPanStart: (value) {
            _closeImageOptions();
          },
          child: ClipRect(
            child: BlurFrame.createBlurFrame(blurAmount: 2, childThatWillGiveSize: Text(""), tintColorWithOpacity: Colors.black.withOpacity(0.1)),
          ),
        ),
      ));
    }

    List<Widget> actionButtons = [];
    if (currentDocument.status != "VALID") {
      actionButtons.add(
        IconButton(
          icon: Icon(Icons.refresh),
          splashColor: Theme.of(context).splashColor,
          color: Colors.white,
          padding: EdgeInsets.only(right: 10),
          onPressed: () {
            setState(() {
              // reload the view
              _refreshTapped();
            });
          },
        ),
      );
    }

    actionButtons.add(IconButton(
      icon: Icon(Icons.send),
      splashColor: Theme.of(context).splashColor,
      color: Colors.white,
      padding: EdgeInsets.only(right: 10),
      onPressed: _isReadyForSubmission(documentToSubmit: currentDocument)
          ? () async {
              await _sendTapped(documentToSubmit: currentDocument);
            }
          : null,
    ));

    // check to show the please wait or not
    List<Widget> pageWidgets = [
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: Text(pageTitle),
            actions: actionButtons,
          ),
          backgroundColor: Theme.of(context).backgroundColor,
          body: Stack(
            children: scaffoldChildren,
          ),
        ),
      )
    ];
    if (_loadingMessage != null) {
      List<Widget> messageWidgets = [];
      if (_showCloseWindowButton) {
        messageWidgets.add(Text(
          _loadingMessage,
          style: Theme.of(context).textTheme.title,
        ));
        messageWidgets.add(Divider());
        messageWidgets.add(RaisedButton(
          child: Text("dismiss"),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ));
      } else {
        messageWidgets.add(CircularProgressIndicator());
        messageWidgets.add(Divider());
        messageWidgets.add(Text(_loadingMessage));
      }

      pageWidgets.add(Positioned(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        child: BlurFrame.createBlurFrame(
            blurAmount: 2,
            childThatWillGiveSize: Center(
                child: Card(
              margin: EdgeInsets.all(ThemeConstants.padding),
              child: Padding(
                padding: EdgeInsets.only(top: ThemeConstants.padding, left: ThemeConstants.padding, right: ThemeConstants.padding, bottom: ThemeConstants.paddingHalved),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: messageWidgets,
                ),
              ),
            )),
            tintColorWithOpacity: Colors.black.withOpacity(0.1)),
      ));
    }

    // TODO chek the results of the popup here
    return WillPopScope(
      child: Stack(
        children: pageWidgets,
      ),
      onWillPop: _onWillPop,
    );
  }

  /// handle the tapping of a card, and permissions allocated to it
  _cardTapped({@required DocumentFileType type, @required bool canUseCamera}) {
    if (canUseCamera) {
      _openSelectFileOptions(type: type);
    } else {
      _selectOrTakeImage(isCamera: true, type: type);
    }
  }

  /// present options to the user to select a file from camera or gallery
  _openSelectFileOptions({@required DocumentFileType type}) {
    setState(() {
      _imagePickerOptions = true;
    });

    String titleText = "Upload ";
    switch (widget.documentType) {
      case DocumentType.idBook:
        switch (type) {
          case DocumentFileType.selfie:
            titleText = titleText + "selfie with your ID book";
            break;
          case DocumentFileType.front:
            titleText = titleText + "inside of your ID book";
            break;
          case DocumentFileType.back:
            titleText = "YOU SHOULD NEVER SEE THIS";
            break;
        }
        break;

      case DocumentType.idCard:
        switch (type) {
          case DocumentFileType.selfie:
            titleText = titleText + "selfie with your ID Card";
            break;
          case DocumentFileType.front:
            titleText = titleText + "front of your ID Card";
            break;
          case DocumentFileType.back:
            titleText = titleText + "back of your ID book";
            break;
        }
        break;

      case DocumentType.passport:
        switch (type) {
          case DocumentFileType.selfie:
            titleText = titleText + "selfie with passport";
            break;
          case DocumentFileType.front:
            titleText = titleText + "inside of your passport";
            break;
          case DocumentFileType.back:
            titleText = "YOU SHOULD NEVER SEE THIS";
            break;
        }
        break;

      case DocumentType.proofOfResidence:
        switch (type) {
          case DocumentFileType.selfie:
            titleText = "YOU SHOULD NEVER SEE THIS";
            break;
          case DocumentFileType.front:
            titleText = titleText + "proof of residence";
            break;
          case DocumentFileType.back:
            titleText = "YOU SHOULD NEVER SEE THIS";
            break;
        }
        break;

      default:
        titleText = "ERR : did you forget to set the type?";
    }

    PersistentBottomSheetController bottomSheetController = _scaffoldKey.currentState.showBottomSheet(
      (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 0, right: 0),
            decoration: BoxDecoration(color: Colors.grey, boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.2), spreadRadius: 3)]),
            child: Padding(
              padding: EdgeInsets.only(left: ThemeConstants.padding, right: ThemeConstants.padding, top: ThemeConstants.paddingHalved, bottom: ThemeConstants.paddingHalved),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  /// title
                  Text(
                    titleText,
                    style: Theme.of(context).textTheme.title.apply(color: Colors.white),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                  ),
                  Divider(),

                  /// open camera button
                  RaisedButton(
                    onPressed: () async {
                      _closeImageOptions();
                      _selectOrTakeImage(type: type, isCamera: true);
                    },
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(ThemeConstants.paddingHalved),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: ThemeConstants.padding),
                          child: Text(
                            "take photo",
                            style: Theme.of(context).textTheme.button.apply(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(ThemeConstants.paddingHalved))),
                    color: Theme.of(context).primaryColor,
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: ThemeConstants.paddingHalved),
                  ),

                  /// Open gallery button
                  RaisedButton(
                    onPressed: () async {
                      _closeImageOptions();
                      _selectOrTakeImage(isCamera: false, type: type);
                    },
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(ThemeConstants.paddingHalved),
                          child: Icon(
                            Icons.photo_library,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: ThemeConstants.padding),
                          child: Text(
                            "select file",
                            style: Theme.of(context).textTheme.button.apply(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(ThemeConstants.paddingHalved))),
                    color: Theme.of(context).primaryColor,
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: ThemeConstants.paddingHalved),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.only(top: ThemeConstants.paddingHalved),
                  ),

                  /// Cancel button
                  RaisedButton(
                    onPressed: () {
                      _closeImageOptions();
                    },
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(ThemeConstants.paddingHalved),
                          child: Icon(
                            Icons.cancel,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: ThemeConstants.padding),
                          child: Text(
                            "cancel",
                            style: Theme.of(context).textTheme.button.apply(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(ThemeConstants.padding))),
                    color: Theme.of(context).accentColor,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );

    bottomSheetController.closed.then((value) {
      setState(() {
        _imagePickerOptions = false;
      });
    });
  }

  /// for POR this will show, so we must be able to close it of course
  _closeImageOptions() {
    setState(() {
      _imagePickerOptions = false;
    });
    Navigator.pop(this.context);
  }

  /// used when uploading an image to the gallery
  _selectOrTakeImage({@required bool isCamera, @required DocumentFileType type}) async {
    File picture;
    if (isCamera) {
      picture = await ImagePicker.pickImage(source: ImageSource.camera);
    } else {
      picture = await FilePicker.getFile(type: FileType.ANY);
    }

    if (picture != null) {
      setState(() {
        switch (type) {
          case DocumentFileType.selfie:
            _selfieFile = picture;
            break;

          case DocumentFileType.front:
            _frontFile = picture;
            break;

          case DocumentFileType.back:
            _backFile = picture;
            break;
        }
      });
    }
  }

  /// used as a gut check for when the user wants to go back or something before they upload their images
  Future<bool> _onWillPop() {
    if (_loadingMessage != null) {
      return showDialog(
        context: this.context,
        builder: (context) => new AlertDialog(
          title: new Text('Busy'),
          content: new Text('please wait for the current process to complete before leaving this page'),
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: new Text('DISMISS'),
            ),
          ],
        ),
      );
    } else {
      int pendingImageCount = 0;
      DocumentDTO currentDocument;

      switch (widget.documentType) {
        case DocumentType.idBook:
          currentDocument = IgmNetworkHelper.getInstance().currentProfileObject.getIdBook();
          if (_selfieFile != null) pendingImageCount++;
          if (_frontFile != null) pendingImageCount++;
          break;

        case DocumentType.idCard:
          currentDocument = IgmNetworkHelper.getInstance().currentProfileObject.getIdCard();
          if (_selfieFile != null) pendingImageCount++;
          if (_frontFile != null) pendingImageCount++;
          if (_backFile != null) pendingImageCount++;
          break;

        case DocumentType.passport:
          currentDocument = IgmNetworkHelper.getInstance().currentProfileObject.getPassport();
          if (_selfieFile != null) pendingImageCount++;
          if (_frontFile != null) pendingImageCount++;
          break;

        case DocumentType.proofOfResidence:
          currentDocument = IgmNetworkHelper.getInstance().currentProfileObject.getPor();
          if (_frontFile != null) pendingImageCount++;
          break;
      }

      // this bit of logic is to encourage users to upload everything at once, and not little part at a time.
      // we do this as documents should be collected at the same time, and to prevent loads of
      // partially complete profiles on our systems.
      if (pendingImageCount > 0 && _isReadyForSubmission(documentToSubmit: currentDocument)) {
        return showDialog(
              context: this.context,
              builder: (context) => new AlertDialog(
                title: new Text('Are you sure?'),
                content: new Text('You have not sent these files for verification\nWould you like to submit before going back?'),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: new Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  FlatButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: new Text('NO'),
                  ),
                  FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      _sendTapped(documentToSubmit: currentDocument);
                    },
                    child: new Text('YES'),
                  ),
                ],
              ),
            ) ??
            false;
      } else if (pendingImageCount > 0) {
        return showDialog(
              context: this.context,
              builder: (context) => new AlertDialog(
                title: new Text('Are you sure?'),
                content: new Text('You will loose all progress of this document if you go back.'),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: new Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  FlatButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: new Text('YES'),
                  ),
                ],
              ),
            ) ??
            false;
      } else {
        return Future.value(true);
      }
    }
  }

  /// when the user taps the send button
  Future _sendTapped({@required DocumentDTO documentToSubmit}) async {
    // at this point all error checking should be done.
    setState(() {
      _loadingMessage = "Starting Upload";
      _showCloseWindowButton = false;
    });

    Map<File, DocumentFileType> filesToUpload = {};
    int maxRes = 1920;

    switch (widget.documentType) {
      case DocumentType.idBook:
        if (_selfieFile != null) filesToUpload.addAll({_selfieFile: DocumentFileType.selfie});
        if (_frontFile != null) filesToUpload.addAll({_frontFile: DocumentFileType.front});
        break;

      case DocumentType.idCard:
        if (_selfieFile != null) filesToUpload.addAll({_selfieFile: DocumentFileType.selfie});
        if (_frontFile != null) filesToUpload.addAll({_frontFile: DocumentFileType.front});
        if (_backFile != null) filesToUpload.addAll({_backFile: DocumentFileType.back});
        break;

      case DocumentType.passport:
        if (_selfieFile != null) filesToUpload.addAll({_selfieFile: DocumentFileType.selfie});
        if (_frontFile != null) filesToUpload.addAll({_frontFile: DocumentFileType.front});
        break;

      case DocumentType.proofOfResidence:
        if (_frontFile != null) filesToUpload.addAll({_frontFile: DocumentFileType.front});
        maxRes = 2500;
        break;
    }

    List<HttpRequestError> errors = [];

    for (int i = 0; i < filesToUpload.length; i++) {
      // check if we can resize the file...
      File fileToUpload = filesToUpload.keys.toList()[i];
      if (!basename(fileToUpload.path).toLowerCase().endsWith('.pdf')) {
        // notify the user, as this may take some time
        setState(() {
          _loadingMessage = "Resizing, please wait.\n" + (filesToUpload.length - i).toString() + " remain";
        });
        await getApplicationDocumentsDirectory().then((applicationDirectory) async {
          imgLib.Image imageToSend = await compute(imgLib.decodeImage, fileToUpload.readAsBytesSync());
          imgLib.Image fileToUploadImage;

          switch (widget.documentType) {
            case DocumentType.idBook:
            case DocumentType.idCard:
            case DocumentType.passport:
              fileToUploadImage = await compute(resizeImageForDoc, imageToSend);
              break;

            case DocumentType.proofOfResidence:
              fileToUploadImage = await compute(resizeImageForPor, imageToSend);
              break;
          }

          fileToUpload = File(applicationDirectory.path + '/thumbnail-' + filesToUpload[filesToUpload.keys.toList()[i]].toString() + '.jpg');
          await fileToUpload.writeAsBytes(imgLib.encodeJpg(fileToUploadImage, quality: 75)); // add a little compression to reduce the size
        });
      }

      setState(() {
        _loadingMessage = "Uploading, please wait.\n" + (filesToUpload.length - i).toString() + " remain";
      });
      await _uploadFile(documentToSubmit: documentToSubmit, documentFileType: filesToUpload[filesToUpload.keys.toList()[i]], inputFile: filesToUpload.keys.toList()[i])
          .catchError((err) {
        errors.add(err);
      });
    }

    if (errors.length == 0) {
      setState(() {
        _loadingMessage = "Upload Complete\nSubmitting for verification";
      });

      await IgmNetworkHelper.getInstance().requestValidation(documentType: documentToSubmit.docType);

      setState(() {
        _loadingMessage = "Upload Complete\nSynchronizing";
      });

      await IgmNetworkHelper.getInstance().getProfile().then((unUsedProfileObject) {
        setState(() {
          _loadingMessage = "Upload complete & submitted";
          _showCloseWindowButton = true;
        });
      });
    } else {
      String message = "";
      for(HttpRequestError error in errors) {
        message = message + error.message + " [" + error.code.toString() + "]\n";
       }

      setState(() {
        _loadingMessage = message;
        _showCloseWindowButton = true;
      });
    }

  }

  /// process and upload a file
  Future _uploadFile({@required DocumentDTO documentToSubmit, @required DocumentFileType documentFileType, @required File inputFile}) async {
    // now we upload the a file
    String fileType = "";
    switch (documentFileType) {
      case DocumentFileType.selfie:
        fileType = "SELFIE";
        break;
      case DocumentFileType.front:
        fileType = "FRONT";
        break;
      case DocumentFileType.back:
        fileType = "BACK";
        break;
    }

    return IgmNetworkHelper.getInstance().uploadFile(documentType: documentToSubmit.docType, documentFileType: fileType, file: inputFile).catchError((err) {
      throw err;
    });
  }

  /// we check that files have been added fro the whole document this is used to enable/disable the send button
  bool _isReadyForSubmission({@required DocumentDTO documentToSubmit}) {
    // dont allow users to upload on the following states, all the others your user should be able to upload
    if (documentToSubmit.status != null &&
        (documentToSubmit.status == "PENDING_VALIDATION" ||
            documentToSubmit.status == "DELAYED" ||
            documentToSubmit.status == "REQUIRES_SUPPORT" ||
            documentToSubmit.status == "PENDING_VERIFICATION" ||
            documentToSubmit.status == "VERIFIED" ||
            documentToSubmit.status == "VALID")) return false;

    if (documentToSubmit.status != null && (documentToSubmit.status == "VALIDATION_FAILED" || documentToSubmit.status == "VERIFICATION_FAILED")) {
      switch (widget.documentType) {
        case DocumentType.idBook:
          if (_selfieFile == null || _frontFile == null) return false;
          break;
        case DocumentType.idCard:
          if (_selfieFile == null || _frontFile == null || _backFile == null) return false;
          break;
        case DocumentType.passport:
          if (_selfieFile == null || _frontFile == null) return false;
          break;
        case DocumentType.proofOfResidence:
          if (_frontFile == null) return false;
          break;
      }
    }

    switch (widget.documentType) {
      case DocumentType.idBook:
        if (documentToSubmit.getSelfie() == null && _selfieFile == null) return false;
        if (documentToSubmit.getFront() == null && _frontFile == null) return false;
        break;

      case DocumentType.idCard:
        if (documentToSubmit.getSelfie() == null && _selfieFile == null) return false;
        if (documentToSubmit.getFront() == null && _frontFile == null) return false;
        if (documentToSubmit.getBack() == null && _backFile == null) return false;
        break;

      case DocumentType.passport:
        if (documentToSubmit.getSelfie() == null && _selfieFile == null) return false;
        if (documentToSubmit.getFront() == null && _frontFile == null) return false;
        break;

      case DocumentType.proofOfResidence:
        if (documentToSubmit.getFront() == null && _frontFile == null) return false;
        break;
    }

    return true;
  }

  /// when a user clicks the refresh button, the timer on the mail change will also be reloading the app
  _refreshTapped() {
    setState(() {
      _loadingMessage = "fetching, please wait";
    });

    IgmNetworkHelper.getInstance().getProfile().then((unusedProfileObject) {
      setState(() {
        _loadingMessage = null;
      });
    });
  }
}

class StatusCardWithTutorial extends StatelessWidget {
  final String title;
  final String status;
  final Color cardColor;
  final bool isSelectable;
  final VoidCallback onTap;
  final DocumentFileDTO cardFile;
  final String tutorialImageLocation;
  final File selectedImage;
  final String docTypeString;

  const StatusCardWithTutorial({
    @required this.title,
    @required this.status,
    @required this.cardColor,
    @required this.isSelectable,
    @required this.docTypeString,
    this.onTap,
    this.tutorialImageLocation,
    this.selectedImage,
    this.cardFile,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> cardDetails = [
      Text(
        title,
        style: Theme.of(context).textTheme.title.apply(color: Colors.white),
      ),
      Padding(
        padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
      ),
      Text(
        status,
        style: Theme.of(context).textTheme.subtitle.apply(color: Colors.white60),
      )
    ];

    if (cardFile != null && cardFile.message != null) {
      final paddingBetweenIconAndText = ThemeConstants.paddingQuarter;

      cardDetails.add(Padding(
        padding: EdgeInsets.only(),
        child: Divider(
          height: 10,
        ),
      ));

      cardDetails.add(Padding(
        padding: EdgeInsets.only(left: 0, right: 0, bottom: ThemeConstants.paddingQuarter, top: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.error,
              color: Colors.white70,
            ),
            Padding(
              padding: EdgeInsets.only(right: paddingBetweenIconAndText),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    cardFile.message.title,
                    style: Theme.of(context).textTheme.subhead.apply(color: Colors.white),
                  ),
                  Text(
                    cardFile.message.body,
                    style: Theme.of(context).textTheme.body1.apply(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    Widget imageContainer;
    String imageHintText;
    if (selectedImage == null) {
      if (cardFile != null && cardFile.createdOn != null) {
        // the server generates this, so its great to use when checking if it has the file, wil be null otherwise
        imageContainer = FutureBuilder(
          future: IgmNetworkHelper.getInstance().getFileThumbnail(documentType: docTypeString, documentFileType: cardFile.fileType, maxWidth: 500),
          builder: (BuildContext context, AsyncSnapshot<String> imageSnapShot) {
            if (imageSnapShot.hasData) {
              File imageFile = File(imageSnapShot.data);
              return Image.file(imageFile);
            } else if (imageSnapShot.hasError) {
              return Text("err:" + imageSnapShot.error.toString());
            } else {
              return Padding(
                padding: EdgeInsets.all(5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CircularProgressIndicator(),
                      Divider(),
                      Text(
                        "loading",
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
        imageHintText = "uploaded";
      } else {
        imageContainer = Image.asset(tutorialImageLocation);
        imageHintText = "example";
      }
    } else {
      if (extension(selectedImage.path).toUpperCase() == ".PDF") {
        // read the image to the PDF
        imageContainer = Container(
          height: 150.0,
          child: PdfViewer(
            filePath: selectedImage.path,
          ),
        );
      } else if ((extension(selectedImage.path).toUpperCase() == ".JPG") ||
          (extension(selectedImage.path).toUpperCase() == ".PNG") ||
          (extension(selectedImage.path).toUpperCase() == ".TIFF") ||
          (extension(selectedImage.path).toUpperCase() == ".WEBP")) {
        imageContainer = Image.file(selectedImage);
      } else {
        imageContainer = Text("Invalid file : " + extension(selectedImage.path).toUpperCase());
      }
      imageHintText = "selected";
    }

    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Card(
        color: cardColor,
        elevation: isSelectable ? 4 : 0,
        margin: EdgeInsets.only(top: ThemeConstants.paddingHalved),
        child: Padding(
          padding: EdgeInsets.only(left: 0, right: 0, bottom: 0, top: 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: ThemeConstants.paddingHalved, right: 0, bottom: ThemeConstants.paddingQuarter, top: ThemeConstants.paddingHalved + 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(5)),
                                  child: imageContainer,
                                ),
                                width: 200,
                              ),
                              Text(
                                imageHintText,
                                style: Theme.of(context).textTheme.caption.apply(color: Colors.grey[300]),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: ThemeConstants.paddingHalved),
                        ),
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: cardDetails,
                          ),
                        ),
                      ],
                    )),
              ),
              isSelectable
                  ? Icon(
                      Icons.arrow_right,
                      color: Colors.white,
                    )
                  : Padding(
                      padding: EdgeInsets.only(),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
