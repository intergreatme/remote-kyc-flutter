import 'package:flutter/material.dart';
import 'package:igm_self_kyc/IgmNetworkHelper.dart';
import 'package:igm_self_kyc/ThemeConstants.dart';

class FailPage extends StatefulWidget {
  FailPage({Key key}) : super(key: key);

  @override
  _FailPageState createState() {
    return _FailPageState();
  }
}

class _FailPageState extends State<FailPage> {
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
              Icons.error,
              size: 100,
              color: ThemeConstants.cardColorError,
            ),
            Text(
              "FAILED",
              style: Theme.of(context).textTheme.title.apply(color: ThemeConstants.cardColorError, fontSizeFactor: 2),
            ),
            Text(
              "are you sure you are who you say you are?",
              style: Theme.of(context).textTheme.caption.apply(color: Colors.white54),
            ),
            Divider(),
            RaisedButton(
              onPressed: () {
                IgmNetworkHelper.getInstance().clearAll();
                Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
              },
              child: Text(
                "try again",
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
