import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './auth.dart';
import './auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailFieldValidator {
  static String validate(String value) {
    return value.isEmpty ? 'Email can\'t be empty' : null;
  }
}

class PasswordFieldValidator {
  static String validate(String value) {
    return value.isEmpty ? 'Password can\'t be empty' : null;
  }
}

class LoginPage extends StatefulWidget {
  
  //final VoidCallback onSignedIn;
  final Function(String uid) onSignedIn;
  const LoginPage({this.onSignedIn});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

enum FormType {
  login,
  register,
}

enum Role { student, staff }

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String _email;
  String _password;
  Map<String, String> _newUserInfo = {
    "new_username" : "",
    "new_matricnumber" : "",
    "new_contactnumber" : "",
    "new_school" : "",
  };
  FormType _formType = FormType.login;
  Role _role = Role.student;
  bool studentDisabled = false;
  bool staffDisabled = true;
  bool pwVisible = false;

  bool validateAndSave() {
    final FormState form = formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> validateAndSubmit() async {
    if (validateAndSave()) {
      try {
        final BaseAuth auth = AuthProvider.of(context).auth;
        if (_formType == FormType.login) {
          final String userId =
              await auth.signInWithEmailAndPassword(_email, _password);
          print('Signed in: $userId');
          if (userId != null)
            widget.onSignedIn(userId);
          else
            await auth.signOut();
          _scaffoldKey.currentState.showSnackBar(
              new SnackBar(content: new Text("Please verify your email.")));
        } else {
          final String userId =
              await auth.createUserWithEmailAndPassword(_email, _password);
          print('Registered user: $userId');
          await Firestore.instance.document("RegisteredUser/" + userId).setData(_newUserInfo);
          await auth.signOut();
          _scaffoldKey.currentState.showSnackBar(new SnackBar(
              content: new Text(
                  "Verification email has been sent. Please verify.")));
          setState(() {
            
            _formType = FormType.login;
          });
        }
      } catch (e) {
        print('Error: $e');
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: new Text(e.toString())));
      }
    }
  }

  void moveToRegister() {
    formKey.currentState.reset();
    setState(() {
      _formType = FormType.register;
    });
  }

  void moveToLogin() {
    formKey.currentState.reset();
    setState(() {
      _formType = FormType.login;
    });
  }

  void roleChange() {
    if (_role == Role.staff) {
      _role = Role.student;
      studentDisabled = false;
      staffDisabled = true;
    } else if (_role == Role.student) {
      _role = Role.staff;
      studentDisabled = true;
      staffDisabled = false;
    }
    setState(() {
    });
  }

  void visibleChange() {
    setState(() {
      pwVisible = pwVisible ? false : true;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 5.0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "USM Tracker App",
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Container(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: chooseRole() +
                        [
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                  width: 3,
                                  color: Colors.purple,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5.0))),
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Column(
                                children: _formType == FormType.login
                                    ? buildLoginInputs() + buildSubmitButtons()
                                    : buildSignupInputs() +
                                        buildSubmitButtons(),
                              ),
                            ),
                          ),
                        ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> chooseRole() {
    return <Widget>[
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
        RaisedButton(
          color: studentDisabled ? Colors.white : Colors.purple,
          onPressed: () {
            studentDisabled ? roleChange() : null;
          },
          child: Text("Student",
              style: TextStyle(
                  color: studentDisabled ? Colors.grey : Colors.white)),
        ),
        RaisedButton(
          color: staffDisabled ? Colors.white : Colors.purple,
          onPressed: () {
            staffDisabled ? roleChange() : null;
          },
          child: Text(
            "Staff",
            style: TextStyle(color: staffDisabled ? Colors.grey : Colors.white),
          ),
        )
      ])
    ];
  }

  List<Widget> buildLoginInputs() {
    return <Widget>[
      TextFormField(
          key: Key('email'),
          decoration: InputDecoration(
              labelText: 'Email',
              suffix: _role == Role.student
                  ? Text('@student.usm.my')
                  : Text('@usm.my')),
          validator: EmailFieldValidator.validate,
          onSaved: (String value) {
            String suffix =
                _role == Role.student ? "@student.usm.my" : "@usm.my";
            _email = value + suffix;
          }),
      TextFormField(
        key: Key('password'),
        decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
                onPressed: () => visibleChange(),
                icon: pwVisible
                    ? Icon(Icons.visibility)
                    : Icon(Icons.visibility_off))),
        obscureText: pwVisible ? false : true,
        validator: PasswordFieldValidator.validate,
        onSaved: (String value) => _password = value,
      ),
    ];
  }

  List<Widget> buildSignupInputs() {
    return <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 0),
                  child: TextFormField(
                      key: Key('username'),
                      decoration: InputDecoration(labelText: 'User Name'),
                      validator: (value) {
                        return value.isEmpty
                            ? "Do not leave empty"
                            : null;
                      },
                      onSaved: (String value) {
                        _newUserInfo["new_username"] = value;
                      }),
                ),
              ),
              Flexible(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                  child: TextFormField(
                      key: Key('school'),
                      decoration: InputDecoration(labelText: 'School'),
                      validator: (value) {
                        return value.isEmpty
                            ? "Do not leave empty"
                            : null;
                      },
                      onSaved: (String value) {
                        _newUserInfo["new_school"] = value;
                      }),
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              
              Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 0),
                  child: TextFormField(
                      key: Key('contactnumber'),
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                      inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter.digitsOnly
                      ],
                      decoration: InputDecoration(labelText: 'Contact No.'),
                      validator: (value) {
                        return value.isEmpty
                            ? "Do not leave empty"
                            : null;
                      },
                      onSaved: (String value) {
                        _newUserInfo["new_contactnumber"] = value;
                      }),
                ),
              ),
              Flexible(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                  child: TextFormField(
                      key: Key('matricnumber'),
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter.digitsOnly
                      ],
                      decoration: InputDecoration(labelText: 'Matric No.'),
                      validator: (value) {
                        return value.isEmpty
                            ? "Do not leave empty"
                            : null;
                      },
                      onSaved: (String value) {
                        _newUserInfo["new_matricnumber"] = value;
                      }),
                ),
              )
            ],
          ),
        ] +
        buildLoginInputs();
  }

  List<Widget> buildSubmitButtons() {
    if (_formType == FormType.login) {
      return <Widget>[
        RaisedButton(
          color: Colors.purple,
          key: Key('signIn'),
          child: Text('Login',
              style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
          onPressed: validateAndSubmit,
        ),
        FlatButton(
          child: Text('Sign up an account',
              style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w200)),
          onPressed: moveToRegister,
        ),
      ];
    } else {
      return <Widget>[
        RaisedButton(
          color: Colors.purple,
          key: Key('signUp'),
          child: Text('Sign up',
              style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
          onPressed: validateAndSubmit,
        ),
        FlatButton(
          child: Text('Login',
              style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w200)),
          onPressed: moveToLogin,
        ),
      ];
    }
  }
}
