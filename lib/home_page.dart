/*
import 'package:flutter/material.dart';
import './tracking.dart';
import './auth.dart';
import './auth_provider.dart';

class HomePage extends StatefulWidget {
  final String homeUID;
  final Function(String uid) onSignedOut;
  const HomePage(
      {this.onSignedOut, this.homeUID}); //need to add {}, else will have error

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController idcontroller =
      new TextEditingController(); //controller for Text Field
  String empty_uid = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("Home UID " + widget.homeUID);
  }

  //move to next page
  void proceed(String id) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {}
          //=> KeepTrack(idcontroller.text), //pass idcontroller.text as argument
        ));
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final BaseAuth auth = AuthProvider.of(context).auth;
      await auth.signOut();
      widget.onSignedOut(empty_uid);
    } catch (e) {
      print(e);
    }
  }

  //UI of first page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: new AppBar(
        title: new Text("EE Tracker App"),
      ),
      body: new Container(
        child: new Center(
          child: SingleChildScrollView(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Text(
                  "EE Tracker",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w500),
                ),
                Padding(
                  padding: EdgeInsets.all(15),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: new TextField(
                    controller: idcontroller,
                    decoration: InputDecoration(
                        hintText: "Enter your ID here",
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(5))),
                    onSubmitted: (String str) {
                      setState(() {
                        idcontroller.text = str;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(15),
                ),
                new RaisedButton(
                    child: new Text("Enter"),
                    onPressed: () {
                      proceed(idcontroller.text);
                    }),
                Padding(
                  padding: EdgeInsets.all(15),
                ),
                new RaisedButton(
                    child: new Text("Sign Out"),
                    onPressed: () {
                      _signOut(context);
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/