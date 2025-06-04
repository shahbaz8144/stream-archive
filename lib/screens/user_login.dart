import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_archive/screens/all_doc_list.dart';
import '../data/user_data.dart';
import '../data/user_data_manager.dart';
import '../services/dependency_injection.dart';
import '../url/api_url.dart';


class UserLogIn extends StatefulWidget {
  const UserLogIn({Key? key}) : super(key: key);

  @override
  State<UserLogIn> createState() => _UserLogInState();
}

class _UserLogInState extends State<UserLogIn> {
  TextEditingController userIdController = TextEditingController();
  TextEditingController oldPassWordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    DependencyInjection.init();

    // Run async functions
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadUserData();
    await checkUserSession(context);
  }
  // Future<void> _loadUserData() async {
  //   userData = await UserDataManager.loadUserData();
  //   //setState(() {});
  // }

  // Future<void> checkUserSession() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   bool loggedIn = prefs.getBool('loggedIn') ?? false;
  //   if (loggedIn) {
  //     // If logged in, retrieve user data from shared preferences
  //     final userDataProvider =
  //         Provider.of<UserDataProvider>(context, listen: false);
  //     userDataProvider.setUserData(
  //       prefs.getString('firstName') ?? '',
  //       prefs.getString('lastName') ?? '',
  //       prefs.getString('email') ?? '',
  //       prefs.getString('designationName') ?? '',
  //       prefs.getInt('userId') ?? 0,
  //       prefs.getInt('organizationid') ?? 0,
  //       prefs.getBool('isCommunicationDownload') ?? false,
  //       prefs.getString('userProfile') ?? '',
  //       prefs.getString('password') ?? '',
  //       prefs.getString('employeeCode') ?? '',
  //     );
  //
  //     // Navigate to the MobileDashboard
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => MobileDashboard()),
  //     );
  //   }
  // }
  Future<void> checkUserSession(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('loggedIn') ?? false;

    if (loggedIn) {
      // Retrieve user data directly from SharedPreferences
      String firstName = prefs.getString('firstName') ?? '';
      String lastName = prefs.getString('lastName') ?? '';
      String email = prefs.getString('email') ?? '';
      String designationName = prefs.getString('designationName') ?? '';
      int userId = prefs.getInt('userId') ?? 0;
      int organizationId = prefs.getInt('organizationid') ?? 0;
      bool isCommunicationDownload = prefs.getBool('isCommunicationDownload') ?? false;
      String userProfile = prefs.getString('userProfile') ?? '';
      String password = prefs.getString('password') ?? '';
      String employeeCode = prefs.getString('employeeCode') ?? '';

      // Print to debug (Optional)
      print('User logged in: $firstName $lastName');

      // Navigate to the MobileDashboard
      if (!context.mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AllDocList()),
        );
      });
    }
  }
  Future<void> _loadUserData() async {
    Map<String, dynamic> data = await getUserSession();
    setState(() {
      userData = data;
    });
  }

  Future<Map<String, dynamic>> getUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'loggedIn': prefs.getBool('loggedIn') ?? false,
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'email': prefs.getString('email') ?? '',
      'designationName': prefs.getString('designationName') ?? '',
      'userId': prefs.getInt('userId') ?? 0,
      'organizationid': prefs.getInt('organizationid') ?? 0,
      'isCommunicationDownload': prefs.getBool('isCommunicationDownload') ?? false,
      'userProfile': prefs.getString('userProfile') ?? '',
      'password': prefs.getString('password') ?? '',
      'employeeCode': prefs.getString('employeeCode') ?? '',
    };
  }

  Future<void> _saveUserSession(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', true);
    await prefs.setString('firstName', userData['firstName']);
    await prefs.setString('lastName', userData['lastName']);
    await prefs.setString('email', userData['email']);
    await prefs.setString('designationName', userData['designationName']);
    await prefs.setInt('userId', userData['userId']);
    await prefs.setInt('organizationid', userData['organizationid']);
    await prefs.setBool(
        'isCommunicationDownload', userData['isCommunicationDownload']);
    await prefs.setString('userProfile', userData['userProfile']);
    await prefs.setString('password', userData['password']);
    await prefs.setString('employeeCode', userData['employeeCode']);
    print("User session saved!");
  }


  static const IconData check_circle_outline_rounded =
  IconData(0xf634, fontFamily: 'MaterialIcons');
  static const IconData lock_circle = IconData(0xf6f8, fontFamily: 'iconFont', fontPackage: 'iconFontPackage');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: Text('Stream Mail'),
      // ),
        body:SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 25.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0 , top: 70.0),
                      child: RichText(
                        text: TextSpan(
                          text: "Hey,\nWelcome Back To \n", // Non-blue text
                          style: TextStyle(
                            fontSize: 26.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.6), // Default color
                          ),
                          children: [
                            TextSpan(
                              text: "Stream Archive", // Blue text
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 30.0,// Set color to blue
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    // Transform.rotate(
                    //   angle: 165 * 3.14159 / 85 ,  // 45 degrees in radians
                    //   child: Transform.scale(
                    //     scale: 1.5,
                    //     child:  Image.asset(
                    //       'assets/login-welcome-robo.png',
                    //       width: 100,
                    //       height: 130,
                    //     ),
                    //   ),
                    // )
                    Image.asset(
                      'assets/logo_images/archive_dbl_above_logo.png',
                      width: MediaQuery.of(context).size.width * 0.33, // 30% of the screen width
                      height: MediaQuery.of(context).size.height * 0.2, // 20% of the screen height
                      fit: BoxFit.fill,
                    ),
                  ],
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.09, // 10% of the screen height
                          ),

                          TextFormField(
                            controller: userIdController,
                            decoration: InputDecoration(
                              hintText: 'USERNAME',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.09),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 15.0),
                                child: Icon(
                                  Icons.person,  // The icon inside the text field
                                  color: Colors.grey, // Icon color
                                ),
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0), // More circular corners
                                  borderSide: BorderSide.none
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0), // More circular corners when not focused
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0), // More circular corners when focused
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.0,),
                          TextFormField(
                            controller: oldPassWordController,
                            enableInteractiveSelection: false,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'PASSWORD',
                              contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                              // Reduces the height of the TextField
                              fillColor: Colors.black.withOpacity(0.09),// Grey background color
                              filled: true,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 15.0),
                                child: Icon(
                                  CupertinoIcons.lock_circle,  // The icon inside the text field
                                  color: Colors.grey, // Icon color
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0), // Rounded corners
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide:BorderSide.none,
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 15.0),
                                child: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Symbols.visibility
                                        : Symbols.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              // suffixIconConstraints: const BoxConstraints(
                              //   maxWidth: 40,
                              //   maxHeight: 40,
                              // ),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.09, // 10% of screen height
                          ),


                          ElevatedButton(
                            onPressed: () async {
                              if (userIdController.text.isEmpty || oldPassWordController.text.isEmpty) {
                                final snackBar = const SnackBar(
                                  content: Text(
                                    'Please Enter Username and Password',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                              } else {
                                var connectivityResult = await Connectivity().checkConnectivity();
                                if (connectivityResult == ConnectivityResult.none) {
                                  final snackBar = const SnackBar(
                                    content: Text(
                                      'No internet connection. Please check your network.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    dismissDirection: DismissDirection.none,
                                    margin: EdgeInsets.zero,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                } else {
                                  _handleSignIn();
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                              backgroundColor: Colors.deepOrange, // The background color for the ElevatedButton
                              minimumSize: Size(100.0, 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: _isLoading
                                ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Please wait',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 10),
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                                : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 40.0,),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'A document management software is a system used to track, \n manage and store documents and reduce paper.\n \n ${DateTime.now().year} © Creative Solutions Co. Ltd, All Rights Reserved',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.03, // 5% of screen height
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child:  Image.asset(
                    "assets/logo_images/archive_below_logo.png",
                    // width: MediaQuery.of(context).size.width * 0.3, // 30% of the screen width
                    height: MediaQuery.of(context).size.height * 0.12,
                    fit: BoxFit.fill,
                  ),
                )
              ],
            ),
          ),
        )

    );
  }

  Future<void> submitData() async {
    final userId = userIdController.text;
    final oldPassword = oldPassWordController.text;
    final body = {
      "userId": userId,
      "oldPassword": oldPassword,
    };

    const url = '${ApiUrls.baseUrl}Login/StreamLoginAPI';
    final uri = Uri.parse(url);
    final response = await http.post(
      uri,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

    final responseData = jsonDecode(response.body);
    final userIdData = json.decode(responseData['Data']['UserId']);

    if (userIdData.length > 0) {
      final credentialsIsValid = userIdData[0]['CredentialsIsValid'];
      if (response.statusCode == 200 && credentialsIsValid == true) {
        final firstName = userIdData[0]['FirstName'];
        final lastName = userIdData[0]['LastName'];
        final email = userIdData[0]['Email'];
        final designationName = userIdData[0]['DesignationName'];
        final userId = userIdData[0]['createdby'];
        final empId = userIdData[0]['userId'];
        final organizationid = userIdData[0]['organizationid'];
        final isCommunicationDownload =
        userIdData[0]['IsCommunicationDownload'];
        final userProfile = userIdData[0]['UserProfile'];
        final password = userIdData[0]['Password'];
        final pinConversionCount = userIdData[0]['PinConversationCount'];
        final employeeCode = userIdData[0]['EmployeeCode'];

        final userData = {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'designationName': designationName,
          'userId': userId,
          'organizationid': organizationid,
          'empId': empId,
          'isCommunicationDownload': isCommunicationDownload,
          'userProfile': userProfile,
          'password': password,
          'pinConversionCount': pinConversionCount,
          'employeeCode' : employeeCode,
        };

        // Save user data to JSON file
        // await UserDataManager.saveUserData(userData).then((value) =>
        //print('Testing first name : $firstName '),
        showCustomSnackBar(context, firstName + " " + lastName);
        await _saveUserSession(userData);

        userIdController.clear();
        oldPassWordController.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AllDocList(),
          ),
        );
      } else {
        final snackBar = const SnackBar(
          content: Text(
            'Sign in failed',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      final snackBar = const SnackBar(
        content: Text(
          'Log in failed',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void showCustomSnackBar(BuildContext context, String userName) {
    final snackBar = SnackBar(
      //duration: const Duration(minutes: 5),
      content: Row(
        children: [
          Icon(
            check_circle_outline_rounded,
            size: 30.0,
            color: Colors.white,
          ),
          SizedBox(width: 10),
          Text(
            'Hello,  $userName',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      backgroundColor: Colors.blue,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true; // Set loading to true when the sign-in process starts
    });

    try {
      await submitData();
    } finally {
      setState(() {
        _isLoading =
        false; // Set loading to false when the sign-in process completes
      });
    }
  }
}
