import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:igm_self_kyc/IgmNetworkHelper.dart';
import 'package:igm_self_kyc/ThemeConstants.dart';
import 'package:igm_self_kyc/models/AddressDTO.dart';
import 'package:igm_self_kyc/pages/StatusPage.dart';
import 'package:igm_self_kyc/utils/GuiUtils.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // setup a color for the application

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IGM Self-KYC',
      theme: ThemeConstants.getThemeData(),
      home: MyHomePage(title: 'Intergreatme Self-KYC'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String versionText = "0.0.3alpha";

  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  var _bottomSheetOpen = false;

  // controllers to get the values out of the text fields
  final _idNumberTextController = TextEditingController();
  final _firstNameTextController = TextEditingController();
  final _surnameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _mobileTextController = TextEditingController();
  final _addressBuildingComplexTextController = TextEditingController();
  final _addressLine1TextController = TextEditingController();
  final _addressLine2TextController = TextEditingController();
  final _addressSuburbTextController = TextEditingController();
  final _addressCityTextController = TextEditingController();
  final _addressProvinceTextController = TextEditingController();
  final _addressPostalCodeTextController = TextEditingController();
  final _addressCountryTextController = TextEditingController();
  final _addressLatitudeTextController = TextEditingController();
  final _addressLongitudeTextController = TextEditingController();

  // focus nodes for selecting the next field on enter
  final _idNumberFocusNode = FocusNode();
  final _firstNameFocusNode = FocusNode();
  final _surnameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _mobileFocusNode = FocusNode();
  final _addressBuildingComplexFocusNode = FocusNode();
  final _addressLine1FocusNode = FocusNode();
  final _addressLine2FocusNode = FocusNode();
  final _addressSuburbFocusNode = FocusNode();
  final _addressCityFocusNode = FocusNode();
  final _addressProvinceFocusNode = FocusNode();
  final _addressPostalCodeFocusNode = FocusNode();
  final _addressCountryFocusNode = FocusNode();
  final _addressLatitudeFocusNode = FocusNode();
  final _addressLongitudeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> scaffoldChildren = [
      Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
        child: ListView(
          padding: EdgeInsets.only(left: ThemeConstants.padding, right: ThemeConstants.padding, top: ThemeConstants.paddingHalved, bottom: ThemeConstants.paddingHalved),
          children: <Widget>[
            // form to control submission of inputted information
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  // details card
                  _buildDetailsCard(context),
                  Padding(
                    padding: EdgeInsets.only(top: ThemeConstants.padding),
                  ),
                  // address card
                  _buildAddressCard(context),
                  Padding(
                    padding: EdgeInsets.only(top: ThemeConstants.paddingHalved),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter, left: ThemeConstants.paddingQuarter),
                  child: Text(
                    "*manditory fields",
                    style: Theme.of(context).textTheme.caption.apply(color: Colors.white),
                  ),
                ),
                RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ThemeConstants.paddingQuarter),
                  ),
                  color: Theme.of(context).primaryColor,
                  textTheme: ButtonTextTheme.primary,
                  onPressed: () {
                    // Validate returns true if the form is valid, otherwise false and an error is presented to the user
                    if (_formKey.currentState.validate()) {
                      _submitInformation();
                    } else {
                      _showSnackBarError('Missing required information');
                    }
                  },
                  child: Text(
                    'next',
                    style: Theme.of(context).textTheme.button.apply(fontWeightDelta: 1, color: Colors.white),
                  ),
                ),
              ],
            ),
            Text(
              "   version " + versionText,
              style: Theme.of(context).textTheme.caption.apply(color: Colors.grey[800]),
            )
          ],
        ),
      )
    ];

    // create a frame to accept touches, if the bottom sheet is open, this is to improve the UX and closing of the bottom sheet
    if (_bottomSheetOpen) {
      scaffoldChildren.add(Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
        child: GestureDetector(
          onTap: () {
            _closeBottomSheet();
          },
          onPanStart: (value) {
            _closeBottomSheet();
          },
          child: ClipRect(
            child: BlurFrame.createBlurFrame(blurAmount: 2, childThatWillGiveSize: Text(""), tintColorWithOpacity: Colors.black.withOpacity(0.1)),
          ),
        ),
      ));
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.format_clear),
            splashColor: Theme.of(context).splashColor,
            color: Colors.white,
            padding: EdgeInsets.only(right: 10),
            onPressed: () {
              _clearInformation();
            },
          ),
          IconButton(
            icon: Icon(Icons.send),
            splashColor: Theme.of(context).splashColor,
            color: Colors.white,
            padding: EdgeInsets.only(right: 10),
            onPressed: () {
              _submitInformation();
            },
          )
        ],
      ),
      body: Stack(
        children: scaffoldChildren,
      ),
    );
  }

  @override
  void dispose() {
    // dispose the text controllers
    _idNumberTextController.dispose();
    _firstNameTextController.dispose();
    _surnameTextController.dispose();
    _emailTextController.dispose();
    _mobileTextController.dispose();
    _addressBuildingComplexTextController.dispose();
    _addressLine1TextController.dispose();
    _addressLine2TextController.dispose();
    _addressProvinceTextController.dispose();
    _addressPostalCodeTextController.dispose();
    _addressCountryTextController.dispose();
    _addressLatitudeTextController.dispose();
    _addressLongitudeTextController.dispose();
    _addressSuburbTextController.dispose();
    _addressCityTextController.dispose();

    // dispose the focus nodes
    _idNumberFocusNode.dispose();
    _firstNameFocusNode.dispose();
    _surnameFocusNode.dispose();
    _emailFocusNode.dispose();
    _mobileFocusNode.dispose();
    _addressBuildingComplexFocusNode.dispose();
    _addressLine1FocusNode.dispose();
    _addressLine2FocusNode.dispose();
    _addressProvinceFocusNode.dispose();
    _addressPostalCodeFocusNode.dispose();
    _addressCountryFocusNode.dispose();
    _addressLatitudeFocusNode.dispose();
    _addressLongitudeFocusNode.dispose();
    _addressSuburbFocusNode.dispose();
    _addressCityFocusNode.dispose();

    super.dispose();
  }

  // constructors
  Card _buildDetailsCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.only(left: ThemeConstants.paddingHalved, right: ThemeConstants.paddingHalved, top: ThemeConstants.paddingHalved, bottom: ThemeConstants.paddingHalved),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Details",
              style: Theme.of(context).textTheme.subhead,
            ),
            Divider(),

            // Id number
            TextFormField(
              decoration: InputDecoration(
                labelText: '*ID number',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.start,
              controller: _idNumberTextController,
              // The validator to check the users input
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter an ID number';
                } else if (!_isIdNumber(value.trim())) {
                  return 'Please enter a valid ID number';
                }
                return null;
              },
              autovalidate: true,
              focusNode: _idNumberFocusNode,
              onFieldSubmitted: (term) {
                _idNumberFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_firstNameFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            // First Name
            TextFormField(
              decoration: InputDecoration(
                labelText: '*name',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.start,
              controller: _firstNameTextController,
              // The validator to check the users input
              validator: (value) {
                if (_isValidName(value)) {
                  return 'Please enter an valid name';
                }
                return null;
              },
              autovalidate: true,
              focusNode: _firstNameFocusNode,
              onFieldSubmitted: (term) {
                _firstNameFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_surnameFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            // Surname
            TextFormField(
              decoration: InputDecoration(
                labelText: '*surname',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.start,
              controller: _surnameTextController,
              // The validator to check the users input
              validator: (value) {
                if (_isValidName(value)) {
                  return 'Please enter an valid surname';
                }
                return null;
              },
              autovalidate: true,
              focusNode: _surnameFocusNode,
              onFieldSubmitted: (term) {
                _surnameFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_emailFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            // email
            TextFormField(
              decoration: InputDecoration(
                labelText: 'email',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.emailAddress,
              textAlign: TextAlign.start,
              controller: _emailTextController,
              // The validator to check the users input
              validator: (value) {
                if (!_isValidEmail(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              autovalidate: true,
              focusNode: _emailFocusNode,
              onFieldSubmitted: (term) {
                _emailFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_mobileFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            // mobile
            TextFormField(
              decoration: InputDecoration(
                labelText: 'mobile',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.start,
              controller: _mobileTextController,
              // The validator to check the users input
              validator: (value) {
                if (!_isValidMobile(value)) {
                  return 'Please enter a valid mobile number';
                }
                return null;
              },
              autovalidate: true,
              focusNode: _mobileFocusNode,
              onFieldSubmitted: (term) {
                _mobileFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_addressBuildingComplexFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(
                top: ThemeConstants.paddingQuarter,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Card _buildAddressCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.only(left: ThemeConstants.paddingHalved, right: ThemeConstants.paddingHalved, top: ThemeConstants.paddingHalved, bottom: ThemeConstants.paddingHalved),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Address",
              style: Theme.of(context).textTheme.subhead,
            ),
            Divider(),

            // building or complex
            TextFormField(
              decoration: InputDecoration(
                labelText: 'building or complex',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              maxLines: 1,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.start,
              controller: _addressBuildingComplexTextController,
              focusNode: _addressBuildingComplexFocusNode,
              onFieldSubmitted: (term) {
                _addressBuildingComplexFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_addressLine1FocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            TextFormField(
              decoration: InputDecoration(
                labelText: 'line 1',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              maxLines: 1,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.start,
              controller: _addressLine1TextController,
              focusNode: _addressLine1FocusNode,
              onFieldSubmitted: (term) {
                _addressLine1FocusNode.unfocus();
                FocusScope.of(context).requestFocus(_addressLine2FocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            // line 2
            TextFormField(
              decoration: InputDecoration(
                labelText: 'line 2',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              maxLines: 1,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.start,
              controller: _addressLine2TextController,
              focusNode: _addressLine2FocusNode,
              onFieldSubmitted: (term) {
                _addressLine2FocusNode.unfocus();
                FocusScope.of(context).requestFocus(_addressSuburbFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            // suburb
            TextFormField(
              decoration: InputDecoration(
                labelText: 'suburb',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              maxLines: 1,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.start,
              controller: _addressSuburbTextController,
              focusNode: _addressSuburbFocusNode,
              onFieldSubmitted: (term) {
                _addressSuburbFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_addressCityFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            // city
            TextFormField(
              decoration: InputDecoration(
                labelText: 'city',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              maxLines: 1,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.start,
              controller: _addressCityTextController,
              focusNode: _addressCityFocusNode,
              onFieldSubmitted: (term) {
                _addressCityFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_addressProvinceFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            // province
            TextFormField(
              decoration: InputDecoration(
                labelText: 'province',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              maxLines: 1,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.start,
              controller: _addressProvinceTextController,
              focusNode: _addressProvinceFocusNode,
              onFieldSubmitted: (term) {
                _addressProvinceFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_addressPostalCodeFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            TextFormField(
              decoration: InputDecoration(
                labelText: 'postal code',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              maxLines: 1,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.phone,
              textAlign: TextAlign.start,
              controller: _addressPostalCodeTextController,
              focusNode: _addressPostalCodeFocusNode,
              onFieldSubmitted: (term) {
                _addressPostalCodeFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_addressCountryFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            // country
            TextFormField(
              decoration: InputDecoration(
                labelText: 'country',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              maxLines: 1,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.start,
              controller: _addressCountryTextController,
              focusNode: _addressCountryFocusNode,
              onFieldSubmitted: (term) {
                _addressCountryFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_addressLatitudeFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            // latitude
            TextFormField(
              decoration: InputDecoration(
                labelText: 'latitude',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              maxLines: 1,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.start,
              controller: _addressLatitudeTextController,
              focusNode: _addressLatitudeFocusNode,
              onFieldSubmitted: (term) {
                _addressLatitudeFocusNode.unfocus();
                FocusScope.of(context).requestFocus(_addressLongitudeFocusNode);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),

            // longitude
            TextFormField(
              decoration: InputDecoration(
                labelText: 'longitude',
                contentPadding: EdgeInsets.all(4),
              ),
              cursorWidth: 2,
              maxLines: 1,
              cursorRadius: Radius.circular(4),
              cursorColor: Theme.of(context).primaryColor,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.start,
              controller: _addressLongitudeTextController,
              focusNode: _addressLongitudeFocusNode,
              onFieldSubmitted: (term) {
                _addressLongitudeFocusNode.unfocus();
                _submitInformation();
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: ThemeConstants.paddingQuarter),
            ),
          ],
        ),
      ),
    );
  }

  // validators
  _isIdNumber(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null && str.length == 13;
  }

  _isValidName(String str) {
    if (str.contains(RegExp(r'[A-Z]'))) {
      return false;
    } else {
      return true;
    }
  }

  _isValidEmail(String str) {
    if (str.isEmpty) {
      return true;
    }
    return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(str);
  }

  _isValidMobile(String str) {
    // TODO complete
    return true;
  }

  _showSnackBarError(String msg) {
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

  _submitInformation({String userId, String userName, String userSurname}) {
    _showLoading();

    IgmNetworkHelper.getInstance()
        .sendWhitelistInfo(
            idNumber: userId != null ? userId : _idNumberTextController.text.trim(),
            name: userName != null ? userName : _firstNameTextController.text.trim(),
            surname: userSurname != null ? userSurname : _surnameTextController.text.trim(),
            addressDTO: AddressDTO(
                unitComplex: _addressBuildingComplexTextController.text.trim(),
                line1: _addressLine1TextController.text.trim(),
                line2: _addressLine2TextController.text.trim(),
                suburb: _addressSuburbTextController.text.trim(),
                province: _addressProvinceTextController.text.trim(),
                city: _addressCityTextController.text.trim(),
                country: _addressCountryTextController.text.trim(),
                postalCode: _addressPostalCodeTextController.text.trim(),
                latitude: _addressLatitudeTextController.text.trim(),
                longitude: _addressLongitudeTextController.text.trim()),
            email: _emailTextController.text.trim(),
            mobile: _mobileTextController.text.trim())
        .then((returned) {
      IgmNetworkHelper.getInstance().getEligible().then((eligibleDto) {
        IgmNetworkHelper.getInstance().getProfile().then((unusedProfileObject) {
          Navigator.pop(context); // close the please wait at the ned of the process
          sleep(const Duration(milliseconds: 100));
          Navigator.push(context, MaterialPageRoute(builder: (context) => StatusPage()));
        }).catchError((err) {
          Navigator.pop(context); // close the please wait on error
          _showSnackBarError(err);
        });
      }).catchError((err) {
        Navigator.pop(context); // close the please wait on error
        _showSnackBarError(err);
      });
    }).catchError((err) {
      Navigator.pop(context); // close the please wait on error
      _showSnackBarError(err);
    });
  }

  _clearInformation() {
    showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Are you sure?'),
        content: new Text('This will clear all information entered.'),
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: new Text(
              'CANCEL',
              style: TextStyle(color: Colors.red),
            ),
          ),
          FlatButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              _idNumberTextController.text = "";
              _firstNameTextController.text = "";
              _surnameTextController.text = "";
              _emailTextController.text = "";
              _mobileTextController.text = "";
              _addressBuildingComplexTextController.text = "";
              _addressLine1TextController.text = "";
              _addressLine2TextController.text = "";
              _addressSuburbTextController.text = "";
              _addressCityTextController.text = "";
              _addressProvinceTextController.text = "";
              _addressPostalCodeTextController.text = "";
              _addressCountryTextController.text = "";
              _addressLatitudeTextController.text = "";
              _addressLongitudeTextController.text = "";

              _idNumberFocusNode.requestFocus();
            },
            child: new Text('YES'),
          ),
        ],
      ),
    );
  }

  _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Card(
            child: Padding(
              padding: EdgeInsets.only(top: ThemeConstants.padding, left: ThemeConstants.padding, right: ThemeConstants.padding, bottom: ThemeConstants.paddingHalved),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  Divider(),
                  Text("loading, please wait"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _closeBottomSheet() {
    setState(() {
      _bottomSheetOpen = false;
    });
    Navigator.pop(this.context);
  }
}

class TestPersonConfig {
  String id;
  String name;
  String surname;

  TestPersonConfig({@required this.id, @required this.name, @required this.surname});
}
