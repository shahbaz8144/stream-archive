import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:stream_archive/screens/user_login.dart';
import '../data/user_data_manager.dart';
import '../models/profile_user_detail_model.dart';

import 'change_password.dart';

class PersonalInformation extends StatefulWidget {
  final int loginUserId;
  const PersonalInformation({super.key, required this.loginUserId});

  @override
  State<PersonalInformation> createState() => _PersonalInformationState();

}

class _PersonalInformationState extends State<PersonalInformation> {

  late Future<List<UserDetail>> futureUserDetails;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  Map<String, dynamic> userData = {};
  File? _selectedFile;
  String _fileName = "No file chosen";
  @override
  void initState() {
    super.initState();
    print("initState called"); // Debugging
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.green,  // Your desired color
    ));

    futureUserDetails = fetchUserDetails();
    _initialize();
  }

  @override
  void dispose() {
    super.dispose();
    // Restore the system UI behavior when this screen is disposed



  }

  Future<void> _initialize() async {
    await _loadUserData();
  }


  Future<void> _loadUserData() async {
    userData = await UserDataManager.loadUserData();
    //setState(() {});
  }




  // Future<List<UserDetail>> fetchUserDetails() async {
  //   final response = await http.post(
  //     Uri.parse(
  //         'https://cswebapps.com/dmsapi/api/LatestCommunicationAPI/NewUserDetailsJson'),
  //     headers: {
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode({
  //       'LoginUserId': widget.loginUserId, // Use the widget's loginUserId
  //     }),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> data = jsonDecode(response.body);
  //     print('Call user apis');
  //     final List<dynamic> userDetailsJson = jsonDecode(data['UserDetailsJson']);
  //     return userDetailsJson.map((json) => UserDetail.fromJson(json)).toList();
  //
  //   } else {
  //     throw Exception('Failed to load user details');
  //   }
  // }
  Future<List<UserDetail>> fetchUserDetails() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://cswebapps.com/dmsapi/api/LatestCommunicationAPI/NewUserDetailsJson'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'LoginUserId': widget.loginUserId, // Use the widget's loginUserId
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> userDetailsJson = jsonDecode(data['UserDetailsJson']);
        return userDetailsJson.map((json) => UserDetail.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user details, Status Code: ${response.statusCode}');
      }
    } on SocketException {
      // Handle socket exception
      throw Exception('No Internet connection');
    } on HttpException {
      // Handle HTTP exception
      throw Exception('Failed to connect to the server');
    } on FormatException {
      // Handle format exception
      throw Exception('Bad response format');
    } catch (e) {
      // Handle any other exceptions
      throw Exception('An error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        // appBar: AppBar(
        //   title: Text(
        //     'Personal Information',
        //     style: TextStyle(color: Colors.white),
        //   ),
        //   backgroundColor: Colors.blue[800],
        //   iconTheme: IconThemeData(color: Colors.white),
        // ),
        body: FutureBuilder<List<UserDetail>>(
          future: futureUserDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.inkDrop(
                  color: Colors.blue,
                  size: 35,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No user details found'));
            } else {
              final userDetailsList = snapshot.data!;
              return ListView.builder(
                itemCount: userDetailsList.length,
                itemBuilder: (context, index) {
                  final userDetail = userDetailsList[index];
                  return SingleChildScrollView(
                    child:  Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.30,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange, // Set the color of the container
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            // Set the radius for rounded corners
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  right: MediaQuery.of(context).size.width * 0.05, // 5% of screen width
                                  top: MediaQuery.of(context).size.height * 0.05, // 5% of screen height
                                ),

                                child: Align(
                                    alignment: Alignment.topRight,
                                    child: GestureDetector(
                                      onTap: (){
                                        Navigator.pop(context);

                                      },
                                      child:  Icon(Symbols.arrow_right_alt , color: Colors.white,size: 30.0,),
                                    )
                                ),
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.02, // 2% of screen height
                              ),

                              Stack(

                                alignment: Alignment.bottomRight,
                                children: [
                                  // User profile image
                                  (userDetail.userProfile.isNotEmpty && userDetail.userProfile != "NA")
                                      ? Container(
                                    width: MediaQuery.of(context).size.width * 0.28, // 50% of the screen width
                                    height: MediaQuery.of(context).size.height * 0.11, // 30% of the screen height
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black, // Border color
                                        width: 0.5, // Border width
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 45,
                                      backgroundImage: NetworkImage(
                                        "https://yrglobaldocuments.blob.core.windows.net/userprofileimages/" + userDetail.userProfile,
                                      ),
                                    ),
                                  )
                                      : CircleAvatar(
                                    radius: 30,
                                    child: Icon(
                                      Icons.person, // Replace with your desired icon
                                      size: 30,
                                    ),
                                  ),

                                  // Camera icon positioned on the right below the profile picture
                                  Positioned(
                                    right: 0, // Positioning to the right side
                                    bottom: 0, // Positioning to the bottom
                                    child: Container(
                                      height: MediaQuery.of(context).size.height * 0.05, // 5% of screen height
                                      width: MediaQuery.of(context).size.width * 0.08,  // 8% of screen width

                                      decoration: BoxDecoration(
                                        color: Colors.white, // Set the background fill color
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          // BoxShadow(
                                          //   // color: Colors.black.withOpacity(0.1), // Shadow color
                                          //   spreadRadius: 1, // Spread radius of the shadow
                                          //   blurRadius: 3, // Blur radius of the shadow
                                          //   offset: Offset(0, 2), // Offset of the shadow (horizontal, vertical)
                                          // ),
                                        ],
                                      ),
                                      child: IconButton(
                                        constraints: BoxConstraints(
                                          maxHeight:  MediaQuery.of(context).size.height * 0.05,
                                        ),
                                        iconSize: MediaQuery.of(context).size.width * 0.04,
                                        padding: EdgeInsets.zero,
                                        color: Colors.white,
                                        icon:

                                        Icon(
                                          Icons.edit,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () async {
                                          await _openFilePicker(context);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5.0,),
                              Text(userDetail.displayName , style: TextStyle(fontSize: 22.0 , color: Colors.white , fontWeight: FontWeight.w900),),
                              Text(userDetail.designationName , style: TextStyle(fontSize: 16.0 , color: Colors.white , fontWeight: FontWeight.w400),)
                            ],
                          ),
                        ),

                        SizedBox(height: 20.0,),

                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child:  Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6), // Add padding around the icon
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50, // Light blue color for the background
                                        shape: BoxShape.circle, // Circular shape
                                      ),
                                      child: Icon(
                                        Symbols.verified_user, // The icon you want to use
                                        color: Colors.blue, // Color of the icon itself
                                        size: 18.0,
                                      ),
                                    ),
                                    SizedBox(width: 5.0,),

                                    Wrap(
                                      direction: Axis.vertical,
                                      children: [
                                        Text("Employee Id", style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                                        Text(userDetail.emplyeeCode.toString(),
                                            style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),



                                  ],
                                ),
                                SizedBox(height: 15.0,),
                                (userDetail.companyName != null && userDetail.companyName.isNotEmpty && userDetail.companyName != "NA") ?  Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6), // Add padding around the icon
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50, // Light blue color for the background
                                        shape: BoxShape.circle, // Circular shape
                                      ),
                                      child: Icon(
                                        Symbols.work_outline, // The icon you want to use
                                        color: Colors.blue, // Color of the icon itself
                                        size: 18.0,
                                      ),
                                    ),
                                    SizedBox(width: 5.0,),

                                    Wrap(
                                      direction: Axis.vertical,
                                      children: [
                                        Text("Company", style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                                        Text(userDetail.companyName,
                                            style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),



                                  ],
                                ) : SizedBox.shrink(),
                                SizedBox(height: 15.0,),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6), // Add padding around the icon
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50, // Light blue color for the background
                                        shape: BoxShape.circle, // Circular shape
                                      ),
                                      child: Icon(
                                        Symbols.email, // The icon you want to use
                                        color: Colors.blue, // Color of the icon itself
                                        size: 18.0,
                                      ),
                                    ),
                                    SizedBox(width: 5.0,),

                                    Wrap(
                                      direction: Axis.vertical,
                                      children: [
                                        Text("Email", style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                                        Text(userDetail.email,
                                            style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),



                                  ],
                                ),
                                SizedBox(height: 15.0,),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6), // Add padding around the icon
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50, // Light blue color for the background
                                        shape: BoxShape.circle, // Circular shape
                                      ),
                                      child: Icon(
                                        Symbols.phone_in_talk, // The icon you want to use
                                        color: Colors.blue, // Color of the icon itself
                                        size: 18.0,
                                      ),
                                    ),
                                    SizedBox(width: 5.0,),

                                    Wrap(
                                      direction: Axis.vertical,
                                      children: [
                                        Text("Phone", style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                                        Text(userDetail.phone,
                                            style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),



                                  ],
                                ),
                                SizedBox(height: 15.0,),
                                (userDetail.address.isNotEmpty && userDetail.address != "NA") ? Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6), // Add padding around the icon
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50, // Light blue color for the background
                                        shape: BoxShape.circle, // Circular shape
                                      ),
                                      child: Icon(
                                        Symbols.location_on, // The icon you want to use
                                        color: Colors.blue, // Color of the icon itself
                                        size: 18.0,
                                      ),
                                    ),
                                    SizedBox(width: 5.0,),

                                    Wrap(
                                      direction: Axis.vertical,
                                      children: [
                                        Text("Address", style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                                        Text(
                                          formatText(userDetail.address),
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,  // Adjust as per your requirement
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),




                                      ],
                                    ),

                                    // Wrap(
                                    //   direction: Axis.vertical,
                                    //   children: [
                                    //     Text(
                                    //       "Address",
                                    //       style: TextStyle(color: Colors.grey, fontSize: 12.0),
                                    //     ),
                                    //     SizedBox(height: 4), // You can add some spacing between the label and the content
                                    //     Flexible(
                                    //       child: Text(
                                    //         formatText(userDetail.address),
                                    //         style: TextStyle(
                                    //           fontSize: 12.0,
                                    //           fontWeight: FontWeight.w600,
                                    //         ),
                                    //         maxLines: 2, // Adjust as per your requirement
                                    //         overflow: TextOverflow.ellipsis,
                                    //         softWrap: true,
                                    //       ),
                                    //     ),Row(
                                    //       children: [
                                    //         Expanded(
                                    //           child: Text(
                                    //             formatText(userDetail.address),
                                    //             style: TextStyle(
                                    //               fontSize: 12.0,
                                    //               fontWeight: FontWeight.w600,
                                    //             ),
                                    //             maxLines: 2, // Adjust as per your requirement
                                    //             overflow: TextOverflow.ellipsis,
                                    //             softWrap: true,
                                    //           ),
                                    //         ),
                                    //       ],
                                    //     )
                                    //
                                    //   ],
                                    // )



                                  ],
                                ) : SizedBox.shrink(),
                                SizedBox(height: 15.0,),
                                const Divider(
                                  height: 10,
                                  thickness: 0.1,
                                  indent: 10,
                                  endIndent: 10,
                                  color: Colors.black,
                                ),
                                SizedBox(height: 3.0,),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6), // Add padding around the icon
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50, // Light blue color for the background
                                        shape: BoxShape.circle, // Circular shape
                                      ),
                                      child: Icon(
                                        Symbols
                                            .supervisor_account, // The icon you want to use
                                        color: Colors.blue, // Color of the icon itself
                                        size: 18.0,
                                      ),
                                    ),
                                    SizedBox(width: 5.0,),

                                    Wrap(
                                      direction: Axis.vertical,
                                      children: [
                                        Text("Reporting Manager", style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                                        Text(userDetail.reportingUserName,
                                            style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),



                                  ],
                                ),
                                SizedBox(height: 3.0,),
                                const Divider(
                                  height: 10,
                                  thickness: 0.1,
                                  indent: 10,
                                  endIndent: 10,
                                  color: Colors.black,
                                ),
                                SizedBox(height: 15.0,),
                                GestureDetector(
                                  // onTap: (){
                                  //   Navigator.push(
                                  //       context,
                                  //       MaterialPageRoute(
                                  //           builder: (context) => ChangePassword(
                                  //             loginUserId: widget.loginUserId,
                                  //             oldPassword: userData['password'],
                                  //           )));
                                  // },
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => ChangePassword(
                                          loginUserId: widget.loginUserId,
                                          oldPassword: userData['password'],
                                        ),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          // Define the slide animation (from right to center)
                                          const begin = Offset(1.0, 0.0); // Start from right
                                          const end = Offset.zero; // End at center
                                          const curve = Curves.easeInOut; // Animation curve
                                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                          var offsetAnimation = animation.drive(tween);

                                          // Return the SlideTransition with the animation
                                          return SlideTransition(position: offsetAnimation, child: child);
                                        },
                                      ),
                                    );
                                  },

                                  child:Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(6), // Add padding around the icon
                                            decoration: BoxDecoration(
                                              color: Colors.blue, // Light blue color for the background
                                              shape: BoxShape.circle, // Circular shape
                                            ),
                                            child: Icon(
                                              Symbols.screen_lock_landscape, // The icon you want to use
                                              color: Colors.white, // Color of the icon itself
                                              size: 18.0,
                                            ),
                                          ),
                                          SizedBox(width: 5.0,),

                                          Wrap(
                                            direction: Axis.vertical,
                                            children: [
                                              Text("Change Password", style: TextStyle(color: Colors.black, fontSize: 14.0 , fontWeight: FontWeight.w600)),
                                              Text("Update and strengthen account security" ,
                                                  style: TextStyle(fontSize: 12.0, color: Colors.grey),
                                                  overflow: TextOverflow.ellipsis),
                                            ],
                                          ),



                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Icon(Symbols.arrow_circle_right , color: Colors.grey,),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 15.0,),
                                GestureDetector(
                                  onTap: (){
                                    _openFilePickerForSignature(context);
                                  },
                                  child:  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(6), // Add padding around the icon
                                            decoration: BoxDecoration(
                                              color: Colors.blue, // Light blue color for the background
                                              shape: BoxShape.circle, // Circular shape
                                            ),
                                            child: Icon(
                                              Symbols.ink_pen, // The icon you want to use
                                              color: Colors.white, // Color of the icon itself
                                              size: 18.0,
                                            ),
                                          ),
                                          SizedBox(width: 5.0,),

                                          Wrap(
                                            direction: Axis.vertical,
                                            children: [
                                              Text("Add Signature", style: TextStyle(color: Colors.black, fontSize: 14.0 , fontWeight: FontWeight.w600)),
                                              // Text("Update and strengthen account security" ,
                                              //     style: TextStyle(fontSize: 12.0, color: Colors.grey),
                                              //     overflow: TextOverflow.ellipsis),
                                            ],
                                          ),



                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Icon(Symbols.arrow_circle_right , color: Colors.grey,),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start, // Aligns children to the right
                                    children: [
                                      (userDetail.signature.isNotEmpty && userDetail.signature != "NA")
                                          ? ClipRect(
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Image.network(
                                            "https://yrglobaldocuments.blob.core.windows.net/documents/" + userDetail.signature,
                                            fit: BoxFit.contain,
                                            width: 150,
                                            height: 40,
                                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                              // Shrinks the widget if image is not available
                                              return SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                      )
                                          : SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () async{
              SharedPreferences prefs =
              await SharedPreferences.getInstance();
              await prefs.clear();
              // await notificationsPlugin.cancelAll();
              print('All notifications canceled');
              // FlutterBackgroundService().invoke("stopService");
              // Navigate to the login page

              UserDataManager.clearUserData();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const UserLogIn()),
                    (route) => false, // Clear all existing routes
              );
            },
            child:  Padding(
              padding: const EdgeInsets.only(left: 8.0 , right: 8.0 , bottom: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6), // Add padding around the icon
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300, // Light blue color for the background
                          shape: BoxShape.circle, // Circular shape
                        ),
                        child: Icon(
                          Symbols.login, // The icon you want to use
                          color: Colors.red.shade400, // Color of the icon itself
                          size: 17.0,
                        ),
                      ),
                      SizedBox(width: 5.0,),

                      Wrap(
                        direction: Axis.vertical,
                        children: [
                          Text("Log Out", style: TextStyle(color: Colors.red, fontSize: 14.0 , fontWeight: FontWeight.w600)),
                          Text("Securely log out of account" ,
                              style: TextStyle(fontSize: 12.0, color: Colors.grey),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),



                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 0.0),
                    child: Icon(Symbols.arrow_circle_right , color: Colors.red,),
                  ),
                ],
              ),
            ),
          ),
        )
    );
  }

  Future<void> _openFilePicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(LineAwesomeIcons.camera_solid),
              title: Text('Take from camera'),
              onTap: () async {
                Navigator.pop(context);
                await _checkPermissionsAndOpenCamera();
              },
            ),
            ListTile(
              leading: Icon(LineAwesomeIcons.mobile_alt_solid),
              title: Text('Select from device'),
              onTap: () async {
                Navigator.pop(context);
                await _pickFromDevice();
              },
            ),
          ],
        );
      },
    );
  }



  Future<void> _pickFromDevice() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      File file = File(result.files.single.path!);
      print('Selected File: ${file.path}');
      await addUserProfile(file);
      setState(() {
        futureUserDetails = fetchUserDetails(); // Re-fetch user details after successful upload
      });


    } else {
      print("No file selected.");
    }
  }

  Future<void> _pickFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera);

    if (file != null) {
      File cameraFile = File(file.path);
      print('Camera file');
      print(cameraFile);
      await addUserProfile(cameraFile);

      setState(() {
        futureUserDetails = fetchUserDetails(); // Re-fetch user details after successful upload
      });
      // await uploadFile(selectedFile); // Call upload function
    }
  }

  Future<void> _checkPermissionsAndOpenCamera() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }

    if (await Permission.camera.isGranted) {
      _pickFromCamera();
    } else {
      print("Camera permission denied");
    }
  }

  // Future<void> addUserProfile(File profileFile) async {
  //   // API endpoint
  //   final url = Uri.parse('https://cswebapps.com/dmsapi/api/UsersAPI/NewAddUserProfile');
  //
  //   final bytes = await profileFile.readAsBytes();
  //   final imgBase64 = base64Encode(bytes);
  //
  //   // Request body
  //   final body = jsonEncode({
  //     "imgUpload": profileFile.path,
  //     "UserId": userData['userId'],
  //   });
  //
  //   try {
  //     // Make the POST request
  //     final response = await http.post(
  //       url,
  //       headers: {"Content-Type": "application/json"},
  //       body: body,
  //     );
  //
  //     // Check the response status
  //     if (response.statusCode == 200) {
  //       print("Profile added successfully: ${response.body}");
  //     } else {
  //       print("Failed to add profile. Status code: ${response.statusCode}");
  //       print("Error: ${response.body}");
  //     }
  //   } catch (error) {
  //     print("Error occurred: $error");
  //   }
  // }
  Future<void> _openFilePickerForSignature(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(LineAwesomeIcons.camera_solid),
              title: Text('Take from camera'),
              onTap: () async {
                Navigator.pop(context);
                await _checkPermissionsAndOpenCameraForSignature();
              },
            ),
            ListTile(
              leading: Icon(LineAwesomeIcons.mobile_alt_solid),
              title: Text('Select from device'),
              onTap: () async {
                Navigator.pop(context);
                await _pickFromDeviceForSignature();
              },
            ),
            ListTile(
              leading: Icon(LineAwesomeIcons.signature_solid),
              title: Text('Draw Signature'),
              onTap: () async {
                Navigator.pop(context);
                await _openSignaturePad(context);
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> _openSignaturePad(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: 400,
            child: Column(
              children: [
                Expanded(
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.grey[200]!,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        _signatureController.clear();
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade800, // Text color
                          side: const BorderSide(
                              color: Colors.grey, width: 1), // Border color and width
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // Square shape
                          ),
                          minimumSize: Size(0.0, 30.0)
                      ),
                      child: Text("Clear"),
                    ),

                    // ElevatedButton(
                    //   onPressed: () async {
                    //     if (_signatureController.isNotEmpty) {
                    //       // Export the signature to PNG bytes
                    //       final signatureBytes = await _signatureController.toPngBytes();
                    //
                    //       if (signatureBytes != null) {
                    //         // Save the signature as a file in the temp directory
                    //         final String filePath = await _saveSignatureToFile(signatureBytes);
                    //
                    //         setState(() {
                    //           // _fileName = "Signature.png";
                    //           _selectedFile = File(filePath);
                    //         });
                    //         await uploadSignatureFile(_selectedFile!);
                    //         setState(() {
                    //           futureUserDetails = fetchUserDetails(); // Re-fetch user details after successful upload
                    //         });
                    //         Navigator.pop(context);
                    //         _signatureController.clear();
                    //       }
                    //     }
                    //   },
                    //   child: Text("Save"),
                    // ),
                    OutlinedButton(
                      onPressed: () async {
                        if (_signatureController.isNotEmpty) {
                          // Export the signature to PNG bytes
                          final signatureBytes = await _signatureController.toPngBytes();

                          if (signatureBytes != null) {
                            // Save the signature as a file in the temp directory
                            final String filePath = await _saveSignatureToFile(signatureBytes);

                            setState(() {
                              // _fileName = "Signature.png";
                              _selectedFile = File(filePath);
                            });
                            await uploadSignatureFile(_selectedFile!);
                            setState(() {
                              futureUserDetails = fetchUserDetails(); // Re-fetch user details after successful upload
                            });
                            _signatureController.clear();
                            Navigator.pop(context);

                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800, // Set button background color to white
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0), // Optional: Set rounded corners
                          ),
                          minimumSize: Size(0.0, 30.0)
                      ),
                      child: Text("Add" , style: TextStyle(color: Colors.white),),
                    )

                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Future<String> _saveSignatureToFile(Uint8List signatureBytes) async {
    // Get the temporary directory for the app
    final directory = await getTemporaryDirectory();

    // Define the path where the file will be saved
    final filePath = '${directory.path}/signature.png';

    setState(() {
      _fileName = filePath;
    });
    // Create the file and write the bytes
    final signatureFile = File(filePath);
    await signatureFile.writeAsBytes(signatureBytes);

    return filePath;  // Return the path of the saved file

  }
  Future<void> _pickFromDeviceForSignature() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      File file = File(result.files.single.path!);
      print('Selected File: ${file.path}');

      await uploadSignatureFile(file);
      setState(() {
        futureUserDetails = fetchUserDetails(); // Re-fetch user details after successful upload
      });
    } else {
      print("No file selected.");
    }
  }
  Future<void> _checkPermissionsAndOpenCameraForSignature() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }

    if (await Permission.camera.isGranted) {
      _pickFromCameraForSignature();
    } else {
      print("Camera permission denied");
    }
  }
  Future<void> _pickFromCameraForSignature() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera);

    if (file != null) {
      File cameraFile = File(file.path);
      print('Camera file');
      print(cameraFile);
      await uploadSignatureFile(cameraFile);
      setState(() {
        futureUserDetails = fetchUserDetails(); // Re-fetch user details after successful upload
      });
      // await uploadFile(selectedFile); // Call upload function
    }
  }

  Future<void> addUserProfile(File profileFile) async {
    // API endpoint
    final url = Uri.parse('https://cswebapps.com/dmsapi/api/UsersAPI/NewAddUserProfile');

    try {
      // Create a multipart request
      var request = http.MultipartRequest('POST', url);

      // Add user ID as a field
      request.fields['UserId'] = userData['userId'].toString();

      // Attach the profile picture as a file
      request.files.add(
        await http.MultipartFile.fromPath(
          'imgUpload', // The field name for the image file
          profileFile.path,
          filename: basename(profileFile.path),
        ),
      );

      // Send the request
      var response = await request.send();

      // Check the response
      if (response.statusCode == 200) {
        print("Profile picture uploaded successfully");
        final responseBody = await response.stream.bytesToString();
        print("Response: $responseBody");
        final jsonResponse = json.decode(responseBody);

        // Extract the URL (assuming the key is 'Url')
        String profileImageUrl = jsonResponse['Url']; // Adjust the key based on your actual response
        print("Profile Image URL: $profileImageUrl");


        String newUserProfile = profileImageUrl;

        await UserDataManager.updateUserProfile(newUserProfile);

        // Optionally, load and print the updated user data
        final updatedUserData = await UserDataManager.loadUserData();
        // print(newUserProfile);
        // print('Update profile data here');
        // print(updatedUserData);
        // await _loadUserData();


      } else {
        print("Failed to upload profile picture. Status code: ${response.statusCode}");
        final errorBody = await response.stream.bytesToString();
        print("Error: $errorBody");
      }
    } catch (error) {
      print("Error occurred: $error");
    }
  }
  Future<void> uploadSignatureFile(File filePath) async {
    final String apiUrl = 'https://cswebapps.com/dmsapi/api/UsersAPI/NewAddUserSignature';

    // Create the request
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.fields['UserId'] = userData['userId'].toString();

    // Add the image file
    request.files.add(
      await http.MultipartFile.fromPath(
        'fileUpload',
        filePath.path,
      ),
    );

    try {
      // Send the request
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        print('Success: ${String.fromCharCodes(responseData)}');
        print('Signature file uploaded');
        // You can handle success here, e.g., show a success message
      } else {
        print('Error: ${response.statusCode}');
        // Handle error response here, e.g., show an error message
      }
    } catch (e) {
      print('Exception: $e');
      // Handle exception, e.g., show an error message
    }
  }
}

String formatText(String inputText) {
  // Split the input text into words
  List<String> words = inputText.split(' ');

  // Create a buffer to store the formatted text
  StringBuffer formattedText = StringBuffer();

  // Loop through the words and add a newline after every 8 words
  for (int i = 0; i < words.length; i++) {
    formattedText.write(words[i]);
    if ((i + 1) % 5 == 0) {
      formattedText.write('\n'); // Add a newline after 8 words
    } else {
      formattedText.write(' '); // Add a space between words
    }
  }

  return formattedText.toString().trim();
}

