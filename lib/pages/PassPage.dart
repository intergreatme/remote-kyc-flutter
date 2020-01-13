import 'package:flutter/material.dart';
import 'package:igm_self_kyc/IgmNetworkHelper.dart';
import 'package:igm_self_kyc/ThemeConstants.dart';

class PassPage extends StatefulWidget {
  PassPage({Key key}) : super(key: key);

  @override
  _PassPageState createState() {
    return _PassPageState();
  }
}

class _PassPageState extends State<PassPage> {
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
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.verified_user,
              size: 100,
              color: ThemeConstants.cardColorPass,
            ),
            Text(
              "PASSED",
              style: Theme.of(context).textTheme.title.apply(color: ThemeConstants.cardColorPass, fontSizeFactor: 2),
            ),
            Text(
              "you have been verified!",
              style: Theme.of(context).textTheme.caption.apply(color: Colors.white54),
            ),
            Divider(),
            RaisedButton(
              onPressed: () {
                IgmNetworkHelper.getInstance().clearAll();
                Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
              },
              child: Text(
                "start over",
                style: Theme.of(context).textTheme.button.apply(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(ThemeConstants.paddingHalved))),
              color: Theme.of(context).primaryColor,
            )
          ],
        ),
      ),
    );
  }
}