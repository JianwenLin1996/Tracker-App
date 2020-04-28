import 'package:flutter/material.dart';
import './tracking.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false, //to remove debug banner on top right of app
    home: HomePage()));
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController idcontroller = new TextEditingController(); //controller for Text Field

  //move to next page
  void proceed(String id) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KeepTrack(idcontroller.text), //pass idcontroller.text as argument
        ));
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
