import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_archive/screens/user_login.dart';
import 'dart:convert';

import '../data/user_data_manager.dart';

class ChangePassword extends StatefulWidget {
  final int loginUserId;
  final String oldPassword;
  const ChangePassword(
      {super.key, required this.loginUserId, required this.oldPassword});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _retypePasswordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  Map<String, dynamic> userData = {};
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;
  bool _obscurePassword3 = true;

  @override
  void initState() {
    super.initState();
    _initialize();
    print(widget.oldPassword);
  }

  Future<void> _initialize() async {
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    userData = await UserDataManager.loadUserData();
    //setState(() {});
  }

  Future<void> _updatePassword() async {

    final bool checkPassword = BCrypt.checkpw(
      _currentPasswordController.text,
      widget.oldPassword,
    );
    if (!checkPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the correct Current password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if(_currentPasswordController.text ==  _newPasswordController.text){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set different password as previous'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }


    print(widget.oldPassword);
    print(_currentPasswordController.text);

    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current password field is empty. Please fill it.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } else if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password field is empty. Please fill it.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } else if (_retypePasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retype password field is empty. Please fill it.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }



    // Validate inputs first
    if (_newPasswordController.text != _retypePasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'New password and Retype password do not match!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // setState(() {
    //   _isLoading = true;
    // });

    String oldPassword = _currentPasswordController.text;
    String newPassword = _newPasswordController.text;

    // Use the encrypted old password provided by the backend
    String chryptedOldPassword = widget.oldPassword;
    int createdBy = widget
        .loginUserId; // Replace with actual user ID or other identification

    try {
      var response = await http.post(
        Uri.parse(
            'https://cswebapps.com/dmsapi/api/AuthenticationAPI/NewUpdatePasswordANG'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'ChryptedOldPassword': chryptedOldPassword,
          'OldPassWord': oldPassword,
          'createdby': createdBy,
          'NewPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password updated successfully!'),
            backgroundColor: Colors.blue.shade700,
          ),
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Navigate to the login page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserLogIn()),
              (route) => false, // Clear all existing routes
        );
      } else {
        // Handle non-200 status codes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update password. Please try again.')),
        );

      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 22.0,
            color: Colors.grey,
          ),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          'Back',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500
          ),
        ),
// toolbarHeight: 50,
        leadingWidth: 25,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 10.0 , top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Reset password' , style: TextStyle(color: Colors.black , fontWeight: FontWeight.bold , fontSize: 25.0),),
              SizedBox(height: 5.0,),
              Text('Your new password must be different from previous used password' , style: TextStyle(color: Colors.grey ,fontSize: 16),),

              SizedBox(height: 20.0,),
              Text('Current Password' , style: TextStyle(fontSize: 14 , color: Colors.grey),),
              SizedBox(height: 3.0,),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscurePassword1,
                cursorColor: Colors.blue,
                decoration: InputDecoration(
                  hintText: 'Enter Current Password',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  // filled: true,
                  // fillColor: Colors.black.withOpacity(0.09),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400,
                        width: 1.0
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0), // Active border color
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword1
                          ? Symbols.visibility
                          : Symbols.visibility_off,
                      size: 20.0,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword1 = !_obscurePassword1;
                      });
                    },
                  ),

                  // enabledBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(30.0), // More circular corners when not focused
                  //   borderSide: BorderSide.none,
                  // ),
                  // focusedBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(30.0), // More circular corners when focused
                  //   borderSide: BorderSide.none,
                  // ), // Adds a box around the TextFormField
                  // contentPadding: const EdgeInsets.symmetric(
                  //     vertical: 15,
                  //     horizontal: 10), // Adds padding inside the box
                ),
              ),

              const SizedBox(height: 20.0),
              Text('New Password' , style: TextStyle(fontSize: 14 , color: Colors.grey),),
              SizedBox(height: 3.0,),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscurePassword2,
                cursorColor: Colors.blue,
                decoration: InputDecoration(
                  hintText: 'New Password',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  // filled: true,
                  // fillColor: Colors.black.withOpacity(0.09),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400,
                        width: 1.0
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0), // Active border color
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword2
                          ? Symbols.visibility
                          : Symbols.visibility_off,
                      size: 20.0,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword2 = !_obscurePassword2;
                      });
                    },
                  ),
                  // enabledBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(30.0), // More circular corners when not focused
                  //   borderSide: BorderSide.none,
                  // ),
                  // focusedBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(30.0), // More circular corners when focused
                  //   borderSide: BorderSide.none,
                  // ), // Adds a box around the TextFormField
                  // contentPadding:
                  //     const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
              ),
              const SizedBox(height: 20.0),
              Text('New Password' , style: TextStyle(fontSize: 14 , color: Colors.grey),),
              SizedBox(height: 3.0,),
              TextFormField(
                controller: _retypePasswordController,
                obscureText: _obscurePassword3,
                cursorColor: Colors.blue,
                decoration: InputDecoration(
                  hintText: 'Enter Confirm Password',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  // filled: true,
                  // fillColor: Colors.black.withOpacity(0.09),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400,
                        width: 1.0
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0), // Active border color
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword3
                          ? Symbols.visibility
                          : Symbols.visibility_off,
                      size: 20.0,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword3 = !_obscurePassword3;
                      });
                    },
                  ),
                  // enabledBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(30.0), // More circular corners when not focused
                  //   borderSide: BorderSide.none,
                  // ),
                  // focusedBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(30.0), // More circular corners when focused
                  //   borderSide: BorderSide.none,
                  // ), // Adds a box around the TextFormField
                  // contentPadding:
                  //     const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
              ),
              const SizedBox(height: 8.0),
              // Row(
              //   children: [
              //     Transform.scale(
              //       scale: 0.8,
              //       child: Checkbox(
              //         value: _showPassword,
              //                 shape: RoundedRectangleBorder(
              //                   borderRadius: BorderRadius.circular(5),
              //                   side: BorderSide(
              //                     color: Colors.grey,
              //                   ),
              //                 ),
              //         onChanged: (value) {
              //           setState(() {
              //             _showPassword = value!;
              //           });
              //         },
              //         activeColor: Colors.blue,
              //                 visualDensity: VisualDensity(
              //                     horizontal: -4.0, vertical: -4.0),
              //       ),
              //     ),
              //     const Text('ShowPassword' ,
              //       style: TextStyle(
              //                 fontSize: 14.0, color: Colors.grey),
              //     ),
              //   ],
              // ),
              // SizedBox(
              //   height: MediaQuery.of(context).size.height * 0.06, // 10% of screen height
              // ),
              SizedBox(
                height: 50.0,
              ),

              // _isLoading
              //     ? Center(
              //   child: LoadingAnimationWidget.inkDrop(
              //     color: Colors.blue,
              //     size: 35,
              //   ),
              // )
              //     :
              // OutlinedButton(
              //   onPressed: _updatePassword,
              //   style: OutlinedButton.styleFrom(
              //     backgroundColor: Colors.blue
              //         .shade800, // Set button background color to blue
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(
              //           8.0), // Optional: Set rounded corners
              //     ),
              //     side: BorderSide(
              //         color: Colors.blue
              //             .shade800), // Optional: Set border color to match the background
              //   ),
              //   child: const Text(
              //     'Update',
              //     style: TextStyle(
              //         color: Colors.white), // Set text color to white
              //   ),
              // ),
              ElevatedButton(
                onPressed: _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor:  Colors.blue, // Background color
                  shape: RoundedRectangleBorder(
                    side: BorderSide.none, // No border
                    borderRadius: BorderRadius.circular(80.0), // Rounded corners
                  ),
                  elevation: 0, // Remove shadow
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Update Password',
                  style: TextStyle(color: Colors.white), // Text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
