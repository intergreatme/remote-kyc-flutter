import 'dart:async';

import 'package:flutter/material.dart';
import 'package:igm_self_kyc/IgmNetworkHelper.dart';
import 'package:igm_self_kyc/ThemeConstants.dart';
import 'package:igm_self_kyc/models/DocumentDTO.dart';
import 'package:igm_self_kyc/models/DocumentFileMessageDTO.dart';
import 'package:igm_self_kyc/models/ProfileDTO.dart';
import 'package:igm_self_kyc/pages/DocumentPage.dart';
import 'package:igm_self_kyc/pages/FailPage.dart';
import 'package:igm_self_kyc/pages/LivelinessPage.dart';
import 'package:igm_self_kyc/pages/PassPage.dart';

class StatusPage extends StatefulWidget {
  StatusPage({Key key}) : super(key: key);

  @override
  _StatusPageState createState() {
    return _StatusPageState();
  }
}

class _StatusPageState extends State<StatusPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Icon _timerIcon = Icon(Icons.timer_off); // timer_3 & time_10
  int _timerTime = -1;
  Timer _timer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ProfileDTO profileDto = IgmNetworkHelper.getInstance().currentProfileObject;

    var nameString = "No-name brand";
    if (profileDto.firstName != null && profileDto.lastName != null) {
      nameString = profileDto.firstName + " " + profileDto.lastName;
    }

    List<Widget> pageContentWidgets = [
      /// top card to hold some info about who is logged in, you wont need this, but it does help to know during testing
      StatusCard(
        iconData: Icons.fingerprint,
        title: nameString,
        status: profileDto.documentNumber,
        cardColor: ThemeConstants.cardColorInfo,
        isEnabled: true,
        isSelectable: false,
      )
    ];

    /// add all the identity options to the list
    List<String> cardTitles = ["ID Book", "ID Card", "Passport", "Proof of Address"];
    List<DocumentType> cardTypes = [DocumentType.idBook, DocumentType.idCard, DocumentType.passport, DocumentType.proofOfResidence];
    List<IconData> cardIcons = [Icons.chrome_reader_mode, Icons.contact_mail, Icons.language, Icons.home];
    for (int i = 0; i < cardTitles.length; i++) {
      Color cardColor = ThemeConstants.cardColorNew;
      String cardActionText = "tap to add";
      DocumentDTO cardDoc;
      var isEnabled = true; // disable others once one has passed

      switch (cardTypes[i]) {
        case DocumentType.idBook:
          cardDoc = profileDto.getIdBook();
          // check if we have a card already
          if (profileDto.getIdCard() != null && (profileDto.getIdCard().status == "VALID" || profileDto.getIdCard().status == "VERIFIED")) {
            isEnabled = false;
            cardActionText = "identification already verified";
          }
          if (profileDto.getPassport() != null && (profileDto.getPassport().status == "VALID" || profileDto.getPassport().status == "VERIFIED")) {
            isEnabled = false;
            cardActionText = "identification already verified";
          }

          break;

        case DocumentType.idCard:
          cardDoc = profileDto.getIdCard();
          if (profileDto.getIdBook() != null && (profileDto.getIdBook().status == "VALID" || profileDto.getIdBook().status == "VERIFIED")) {
            isEnabled = false;
            cardActionText = "identification already verified";
          }
          if (profileDto.getPassport() != null && (profileDto.getPassport().status == "VALID" || profileDto.getPassport().status == "VERIFIED")) {
            isEnabled = false;
            cardActionText = "identification already verified";
          }
          break;

        case DocumentType.passport:
          cardDoc = profileDto.getPassport();
          if (profileDto.getIdBook() != null && (profileDto.getIdBook().status == "VALID" || profileDto.getIdBook().status == "VERIFIED")) {
            isEnabled = false;
            cardActionText = "identification already verified";
          }
          if (profileDto.getIdCard() != null && (profileDto.getIdCard().status == "VALID" || profileDto.getIdCard().status == "VERIFIED")) {
            isEnabled = false;
            cardActionText = "identification already verified";
          }
          break;

        case DocumentType.proofOfResidence:
          cardDoc = profileDto.getPor();
          break;
      }

      if (cardDoc != null && cardDoc.status != null) {
        // [ NEW, VALID, VERIFIED, ,  ]
        switch (cardDoc.status) {
          case 'NEW':
            break; // no need, defaults will suffice

          case 'VALID':
          case 'VERIFIED':
            cardActionText = "verified";
            cardColor = ThemeConstants.cardColorPass;
            break;

          case 'PENDING_VALIDATION':
          case 'ON_HOLD':
          case 'REQUIRES_SUPPORT':
          case 'PENDING_VERIFICATION':
            if (cardDoc.delayed) {
              cardActionText = "pending manual validation";
            } else {
              cardActionText = "pending validation";
            }
            cardColor = ThemeConstants.cardColorPending;
            break;

          case 'VALIDATION_FAILED':
          case 'VERIFICATION_FAILED':
            if (cardDoc.delayed) {
              cardActionText = "failed manual validation";
            } else {
              cardActionText = "failed validation";
            }
            cardColor = ThemeConstants.cardColorError;
            break;
        }
      }

      pageContentWidgets.add(
        StatusCard(
          iconData: cardIcons[i],
          title: cardTitles[i],
          status: cardActionText,
          cardColor: cardColor,
          isEnabled: isEnabled,
          isSelectable: isEnabled,
          onTap: () {
            if (isEnabled) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentPage(
                    documentType: cardTypes[i],
                  ),
                ),
              );
            }
          },
        ),
      );
    }

    /// add the liveliness card
    // TODO requires some state, and liveliness to be implemented
//    pageContentWidgets.add(StatusCard(
//      iconData: Icons.camera_front,
//      title: "Liveliness Detection",
//      status: "tap to start",
//      cardColor: Theme.of(context).primaryColor,
//      isEnabled: true,
//      isSelectable: true,
//      onTap: () {
//        Navigator.push(context, MaterialPageRoute(builder: (context) => LivelinessPage()));
//      },
//    ));

    Widget pageContent = ListView(
      padding: EdgeInsets.only(left: ThemeConstants.paddingHalved, right: ThemeConstants.paddingHalved, top: 0, bottom: ThemeConstants.padding),
      children: pageContentWidgets,
    );

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("KYC Status"),
          actions: <Widget>[
            IconButton(
              icon: _timerIcon,
              splashColor: Theme.of(context).splashColor,
              color: Colors.white,
              padding: EdgeInsets.only(right: 10),
              onPressed: () {
                setState(() {
                  _changeTimerTapped();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              splashColor: Theme.of(context).splashColor,
              color: Colors.white,
              padding: EdgeInsets.only(right: 10),
              onPressed: () {
                _refreshTapped();
              },
            )
          ],
        ),
        backgroundColor: Theme.of(context).backgroundColor,
        body: pageContent,
      ),
    );
  }

  /// when a user clicks back, this will enable the gut check to the back out process
  Future<bool> _onWillPop() {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('This will end this session, and you will have to start a new one'),
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
  }

  /// displaying a temp message to the user
  _showSnackMessage(String msg) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(msg),
      action: SnackBarAction(
        label: 'Dismiss',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    ));
  }

  /// when the user taps the refresh button
  _refreshTapped() {
    _showSnackMessage("Syncronizing, please wait");

    IgmNetworkHelper.getInstance().getProfile().then((profileObject) {
      _evaluateSuccessOrRefresh(returnedProfileObject: profileObject);
    }).catchError((err) {
      _showSnackMessage(err);
    });
  }

  /// when the user taps the timer button
  _changeTimerTapped() {
    if (_timerTime == -1) {
      _timerIcon = Icon(Icons.timer_3);
      _timerTime = 3;
    } else if (_timerTime == 3) {
      _timerIcon = Icon(Icons.timer_10);
      _timerTime = 10;
    } else if (_timerTime == 10) {
      _timerIcon = Icon(Icons.timer_off);
      _timerTime = -1;
    }
    _changeTimer(_timerTime);
  }

  /// after the user taps the timer, update the polling
  _changeTimer(int seconds) {
    _timer?.cancel();

    if (seconds > 0) {
      _timer = Timer.periodic(Duration(seconds: seconds), (Timer t) {
        IgmNetworkHelper.getInstance().getProfile().then((fetchedProfileObject) {
          _evaluateSuccessOrRefresh(returnedProfileObject: fetchedProfileObject);
        }).catchError((err){
          _showSnackMessage(err);
          _timer?.cancel();
          setState(() {
            _timerIcon = Icon(Icons.timer_off);
            _timerTime = -1;
          });
        });
      });
    }
  }

  /// check the result of the profile object AFTER each refresh
  _evaluateSuccessOrRefresh({@required ProfileDTO returnedProfileObject}) {
    if (returnedProfileObject.shareSuccess != null) {
      if (returnedProfileObject.shareSuccess) {
        // TODO show state somehow
      } else {
        // TODO show state somehow
      }
      _timer?.cancel();
    } else {
      setState(() {});
    }
  }
}

/// the cards displayed on the status page
class StatusCard extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String status;
  final Color cardColor;
  final bool isEnabled;
  final bool isSelectable;
  final List<DocumentFileMessageDTO> errors;
  final VoidCallback onTap;

  const StatusCard({
    @required this.iconData,
    @required this.title,
    @required this.status,
    @required this.cardColor,
    @required this.isEnabled,
    @required this.isSelectable,
    this.errors,
    this.onTap,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> cardChildren = [
      Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            iconData,
            color: Colors.white,
            size: 56,
          ),
          Padding(
            padding: EdgeInsets.only(right: ThemeConstants.paddingHalved),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
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
              ],
            ),
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
      )
    ];

    if (errors != null) {
      final paddingBetweenIconAndText = ThemeConstants.paddingQuarter;
      String failHeading = "Failed for the following:";
//      if (errors.length > 1) {
//        failHeading = failHeading + "s";
//      }
//      failHeading = failHeading + ":";

      cardChildren.add(Padding(
        padding: EdgeInsets.only(),
        child: Divider(
          height: 10,
        ),
      ));

      cardChildren.add(Padding(
        padding: EdgeInsets.only(left: ThemeConstants.paddingHalved, bottom: ThemeConstants.paddingQuarter, top: ThemeConstants.paddingQuarter),
        child: Text(
          failHeading,
          style: Theme.of(context).textTheme.caption.apply(color: Colors.white),
          textAlign: TextAlign.left,
        ),
      ));

      for (DocumentFileMessageDTO error in errors) {
        cardChildren.add(Padding(
          padding: EdgeInsets.only(left: ThemeConstants.paddingHalved, right: ThemeConstants.paddingHalved, bottom: ThemeConstants.paddingQuarter, top: 0),
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
                      error.title,
                      style: Theme.of(context).textTheme.subhead.apply(color: Colors.white),
                    ),
                    Text(
                      error.body,
                      style: Theme.of(context).textTheme.body1.apply(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
      }
    }

    Widget firstChild;
    if (isSelectable) {
      firstChild = InkWell(
        onTap: () {
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.only(left: ThemeConstants.paddingHalved, right: 0, top: ThemeConstants.paddingHalved, bottom: ThemeConstants.paddingHalved),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cardChildren,
          ),
        ),
      );
    } else {
      firstChild = Padding(
        padding: EdgeInsets.only(left: ThemeConstants.paddingHalved, right: 0, top: ThemeConstants.paddingHalved, bottom: ThemeConstants.paddingHalved),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cardChildren,
        ),
      );
    }

    return Card(
      margin: EdgeInsets.only(top: ThemeConstants.paddingHalved),
      elevation: isSelectable ? 4 : 0,
      color: isEnabled ? cardColor : cardColor.withOpacity(0.2),
      child: firstChild
    );
  }
}
