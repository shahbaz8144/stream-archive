import 'package:flutter/foundation.dart';

class UserDataProvider with ChangeNotifier {
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _designationName = '';
  int _userId = 0;
  int _organizationid = 0;
  String _userProfile = '';
  String _password = '';
  String _employeeCode = '';

  String get firstName => _firstName;
  String get lastName => _lastName;
  String get email => _email;
  String get designationName => _designationName;
  int get userId => _userId;
  int get organizationid => _organizationid;
  String get userProfile => _userProfile;
  String get password => _password;
  String get employeeCode =>  _employeeCode;

  void setUserData(
      String firstName,
      String lastName,
      String email,
      String designationName,
      int userId,
      int organizationid,
      bool bool,
      String userProfile,
      String password,
      String  employeeCode) {
    _firstName = firstName;
    _lastName = lastName;
    _email = email;
    _designationName = designationName;
    _userId = userId;
    _organizationid = organizationid;
    _userProfile = userProfile;
    _password = password;
    _employeeCode = employeeCode;
    notifyListeners();
  }
}
