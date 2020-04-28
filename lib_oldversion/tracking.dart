import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:flutter/material.dart';
import 'package:geolocation/geolocation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ntp/ntp.dart';
import 'package:connectivity/connectivity.dart';

class KeepTrack extends StatefulWidget {
  //to get String argument for this class
  final String id;
  KeepTrack(this.id);

  @override
  _KeepTrackState createState() => _KeepTrackState();
}

class _KeepTrackState extends State<KeepTrack> {
  double lat = 0;
  double long = 0;
  List<String> locationstored = [];
  List<String> timestored = [];

  DateTime _currentTime;
  DateTime _ntpTime = DateTime.now();
  int _ntpOffset;

  StreamController<List<String>> _events;
  Timer _timer;

  DateTime now = DateTime.now(); //do not put new infront of datatime
  String today;
  String currentmoment;

  //_gotinternet is stream which detects changes in internet whenever user is in this page
  StreamController<bool> _gotinternet = new StreamController<bool>(sync: false);
  var subscription;
  bool _connected = false;

  //initial state is where app will run through when first enter the page
  @override
  initState() {
    super.initState();

    //check internet connection
    _gotinternet.add(false);
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      //print("checking connectivity");
      if (result == ConnectivityResult.none) {
        //print("not connected");
        //if not connected, add false to _connected and _gotinternet subscription
        _gotinternet.add(false);
        _connected = false;
      } else {
        //print("connected");
        //if not connected, add true to _connected and _gotinternet subscription
        _gotinternet.add(true);
        _connected = true;

        //if internet is connected, update time
        _updateTime();
        //if internet is connected, check if ID folder is existed on Firestore
        checkExistance();
      }
    });

    //set _events as new StreamController<List<String>> to detect update of tracking data
    _events = new StreamController<List<String>>.broadcast();
    _events.add(["Start tracking"]);

    //code inside will run every 10 seconds in this page
    _timer = Timer.periodic(Duration(seconds: 10), (Timer t) {
      //run code if is connected
      if (_connected) {
        _updateTime();
        Future.delayed(Duration(seconds: 5));
        getLocation();
      }
    });
  }

  //dispose will run when app is exiting this page
  @override
  void dispose() {
    _events.close(); //Stream MUST be closed when exiting page.
    _gotinternet.close(); //Stream MUST be closed when exiting page.
    _timer
        .cancel(); //MUST cancel timer before exiting, else it will still continue in other page and cause error
    subscription.cancel();     
    super.dispose();
  }

  //update time
  void _updateTime() async {
    //get device time
    _currentTime = DateTime.now();
    //get offset time from Network Time Protocol
    //offsettime meaning time difference between local machine and reference time (NTP)
    NTP.getNtpOffset().then((value) {
      //print("time updated");      
      setState(() {
        _ntpOffset = value;
        //set _ntpTime to current time plus offset time
        _ntpTime = _currentTime.add(Duration(milliseconds: _ntpOffset));
        //update variable today
        today = _ntpTime.day.toString() +
            "-" +
            _ntpTime.month.toString() +
            "-" +
            _ntpTime.year.toString();
        //update variable currentmoment
        currentmoment = _ntpTime.hour.toString().padLeft(2, "0") +
            ":" +
            _ntpTime.minute.toString().padLeft(2, "0") +
            ":" +
            _ntpTime.second.toString().padLeft(2, "0");
      });
    }).catchError((e) {
      print(e);
    });
  }

  //create collection if UserID does not exist
  void createCollection(String idlist) async {
    //process the id list to fit it into field
    idlist = idlist.substring(1, idlist.length - 1);
    List<String> tempidlist = idlist.split(", ");
    tempidlist.add(widget.id);
    Map<String, dynamic> addin = {"UserID List": tempidlist};
    //add data into IDCollection document
    await Firestore.instance.document('UserID/IDCollection/').updateData(addin);

    //create new ID collection
    Map<String, dynamic> newinfo = {
      "First login at": currentmoment + " of " + today
    };
    final CollectionReference newcollection = Firestore.instance.collection(
        'UserID/IDCollection/' +
            widget.id); //collection need not "/" after widget.id
    //set first login time as field into the newly created folder
    await newcollection.document(today).setData(newinfo);
  }

  //check exist of collection with entered ID
  void checkExistance() async {
    //print("checking existance");
    try {
      Firestore.instance
          .document('UserID/IDCollection/')
          .get() //get data inside IDCollection
          .then((datasnapshot) {
        if (datasnapshot.exists) {
          Map<String, dynamic> tempString = datasnapshot.data;
          String tempID = tempString['UserID List'].toString();
          if (!tempID.contains(widget.id)) { //if no data inside IDCollection matches entered ID
            createCollection(tempID);
          }
        }
      });
    } catch (err) {
      print(err);
    }
  }

  //update Firestore whenever location is tracked
  void updateFirestore() async {
    //data structure which will be inserted into Firestore
    Map<String, dynamic> tempdata = {
      currentmoment: {"latitude": lat, "longtitude": long}
    };

    //check if today's document exists
    try {
      Firestore.instance
          .document("UserID/IDCollection/" +
              widget.id +
              "/" +
              today.toString() +
              "/")
          .get()
          .then((datasnapshot) {
        if (!datasnapshot.exists) { //if not exist
          Firestore.instance
              .document("UserID/IDCollection/" +
                  widget.id +
                  "/" +
                  today.toString() +
                  "/")
              .setData(tempdata); //create new document and set data
        }
        else {
          Firestore.instance
        .document(
            "UserID/IDCollection/" + widget.id + "/" + today.toString() + "/")
        .updateData(
            tempdata); //update data
            //did not create document using updateData
        }
      });
    } catch (err) {
      print(err);
    }

     //if the key of map is unique in the document, document will be added instead of replaced
  }

  //get permission to detect device location
  getPermission() async {
    final GeolocationResult result =
        await Geolocation.requestLocationPermission(
            permission:
                LocationPermission(android: LocationPermissionAndroid.fine));
    return result;
  }

  //get location of device
  getLocation() async {
    getPermission().then((result) {
      if (result.isSuccessful) { //if permission to detect location is granted
        StreamSubscription<LocationResult> subscription =
            Geolocation.currentLocation(
                    inBackground: true, accuracy: LocationAccuracy.best)
                .listen((result) { 
          if (result.isSuccessful) { //if successfully obtain result
            if (mounted) {
              //mounted is needed so that if this is still running after page exited
              //no error will occur  due to setState
              setState(() {
                lat = result.location.latitude;
                long = result.location.longitude;
                locationstored.add("Lattitude: $lat\nLongtitude: $long");
                timestored
                    .add("Tracked on " + today + " at " + currentmoment + ".");
              });
            }
            //update Firestore the result
            updateFirestore();
            //update _events stream
            _events.add(locationstored);
          }
        });
      } else {
        //show dialog if fail to obtain result
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                elevation: 8.0,
                insetPadding: EdgeInsets.all(10),
                backgroundColor: Colors.lightBlue[200],
                title: new Text(
                    "Please grant permission to access device location."),
                actions: <Widget>[
                  new FlatButton(
                    child: new Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              );
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          title: new Text("ID : " + widget.id),
        ),
        body: StreamBuilder(
            stream: _gotinternet.stream, //listen to _gotinternet stream
            builder: (BuildContext context, connection) {
              return (connection.data == true)
                  ? new Container( //UI when connected to internet
                      child: new Center(
                        child: StreamBuilder( 
                          stream: _events.stream, //listen to _events stream
                          builder: (context, snapshot) {
                            //locationresult = snapshot.data;
                            return ListView.builder( //build a list of items
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              itemCount: locationstored.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  subtitle: Text(timestored.elementAt(index)),
                                  title: Text(locationstored.elementAt(index)),
                                );
                              },
                            );
                          },
                        ),                  
                      ),
                    )
                  : _nointernet();
            }));
  }
}

//UI when no internet
Widget _nointernet() {
  return new Container(
      child: new Center(
    child: new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.signal_wifi_off),
        ),
        Padding(
            padding: EdgeInsets.all(10),
            child: Text("Please check your internet connection."))
      ],
    ),
  ));
}
