import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:stream_archive/models/archive_document_detail_model.dart';
import 'package:http/http.dart' as http;
import 'package:stream_archive/screens/dragable_box.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:ui' as ui;

import '../url/api_url.dart';


class DocDetails extends StatefulWidget {

  final String documentId;
  final String referenceId;
  final String shareId;
  final String createdBy;
  final String organizationId;
  final String documentName;

  const DocDetails({super.key,
    required this.documentId,
    required this.referenceId,
    required this.shareId,
    required this.createdBy,
    required this.organizationId,
    required this.documentName,
  });

  @override
  State<DocDetails> createState() => _DocDetailsState();
}

class _DocDetailsState extends State<DocDetails> {
  List<ArchiveDocumentDetailModel> documents = [];
  bool isLoading = true;
  String? error;
  String? documentUrl;
  String? sasUrl;
  String? _localFilePath;
  String? _fileType;
  String? _textContent;
  late TextEditingController _textController;
  late final WebViewController _controller;
  Offset position = Offset(100, 100);
  TemplateData? templateData;
  ArchiveDocumentDetailModel? documentData;
  bool showTemplateWidget = false; // control widget visibility
  final GlobalKey _repaintKey = GlobalKey();
  Uint8List? _capturedImage;
  String? _imageBase64;
  String? positionX;
String? positionY;

  List<TemplateData> parseTemplateDatas(List<dynamic> json) {
    return json.map((data) => TemplateData.fromJson(data)).toList();
  }


  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchArchiveDocumentsDetails();
    if (documentUrl != null) {
      await fetchAndSetSasUrl(documentUrl!);
      print('doc url');
      print(documentUrl);
      await _checkDocumentType(documentUrl!);
      if (_fileType == 'web' && sasUrl != null) {
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(
              "https://view.officeapps.live.com/op/view.aspx?src=${Uri.encodeComponent(sasUrl!)}"));
        print('sas url');
        print(sasUrl);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentName),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    height: 400,
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    child: Text('doc details here'),
                  );
                },
              );
            },
            icon: Icon(Icons.more_vert_outlined),
          ),
        ],
      ),
      body:
      // Column(
      //   children: [
      //     if (showTemplateWidget && templateData != null)
      //       buildTemplateDisplay(
      //         template: templateData!,
      //         position: position,
      //         onPositionChanged: (newPos) {
      //           setState(() => position = newPos);
      //         },
      //       ),
      //     // Image.memory(
      //     //   _capturedImage!,
      //     //   fit: BoxFit.contain,
      //     //   // width: 300,
      //     // ),
      //     // Image.memory(
      //     //   base64Decode(_imageBase64!),
      //     //   fit: BoxFit.contain,
      //     //   width: 300,
      //     // ),
      //   ],
      // ),
      Stack(
        children: [

          if (showTemplateWidget && templateData != null)
            buildTemplateDisplay(
              template: templateData!,
              position: position,
              onPositionChanged: (newPos) {
                setState(() => position = newPos);
              },
            ),

          if (isLoading)
            const Center(
              child: LinearProgressIndicator(
                color: Colors.red,
              ),
            )
          else if (_fileType == 'pdf' && _localFilePath != null)
            PDFView(
              filePath: _localFilePath!,
              onPageChanged: (int? page, int? total) {
                if (total != null && page != null) {
                  if (mounted) {
                    setState(() {
                      isLoading = false;
                    });
                  }
                }
              },
              onViewCreated: (PDFViewController viewController) {
                print('PDFViewController created');
              },
            )
          else if (_fileType == 'image' && _localFilePath != null)
              PhotoView(imageProvider: FileImage(File(_localFilePath!)))
            else if (_fileType == 'video' && _localFilePath != null)
                VideoPlayerScreen(filePath: _localFilePath!)
              else if (_fileType == 'text' && _textContent != null)
                  Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            decoration: const InputDecoration(),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (_fileType == 'audio' && _localFilePath != null)
                    AudioPlayerScreen( filePath: _localFilePath! , sasUrl!)
                  else if (_fileType == 'web' && sasUrl != null)
                      WebViewWidget(controller: _controller)
                    else if (_fileType == 'unsupported')
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Symbols.preview_off, size: 100, color: Colors.grey),
                              SizedBox(height: 20),
                              const Text(
                                'Preview Not Available',
                                style: TextStyle(fontSize: 25, color: Colors.black),
                              ),
                              Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  'The file is not available for preview currently. Please download the file to view.',
                                  style: TextStyle(fontSize: 15, color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton(
                                onPressed: () => _downloadDocument(sasUrl ?? ''),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  side: BorderSide(color: Colors.blue.shade800),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Download',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                      // else
                      //   Center(
                      //     child: Text(error ?? 'No preview available'),
                      //   ),
        ],
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () {}, icon: Icon(Icons.star)),
          IconButton(onPressed: () {}, icon: Icon(Icons.push_pin_sharp)),
          IconButton(onPressed: () {}, icon: Icon(Icons.delete)),
          // IconButton(
          //   onPressed: () {
          //     // if (documentUrl != null) {
          //     //   Navigator.push(
          //     //     context,
          //     //     MaterialPageRoute(
          //     //       builder: (context) => DragableBox(documentUrl: documentUrl!),
          //     //     ),
          //     //   );
          //     // }
          //   },
          //   icon: Icon(Symbols.preview),
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: documents.map((doc) {
              return   IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder:
                        (context) {
                      final screenHeight = MediaQuery.of(context).size.height;
                      // final template = doc.templateData as Map<String, dynamic>;
                      final template = TemplateData.fromJson(doc.templateData as Map<String, dynamic>);
                      final String?  fileUrl  = template.elements[1].fileUrl;
                      String? base64String = fileUrl?.split(',').last;

                      Uint8List bytes = base64Decode(base64String!);

                     print(template.elements[0].id);
                      print(template.elements[0].fontColor);
                      print(template.elements[0].fontWeight);

                      print(template.elements[1].fileUrl);
                      print(template.elements[0].barcodeNumber);
                      print(template.elements[2].text);


                      return StatefulBuilder(
                        builder: (context, setModalState) {
                          return Container(
                            height: screenHeight * 0.7,
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            child: Stack(
                              children: [
                                // Top bar showing coordinates
                                Positioned(
                                  top: 10,
                                  left: 20,
                                  child: Row(
                                    children: [


                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "X: ${position.dx.toStringAsFixed(1)}   Y: ${position.dy.toStringAsFixed(1)}",
                                          style: TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      ),
                                      SizedBox(width: 10.0),
                                      OutlinedButton(
                                        onPressed: () {
                                          // Add your update position logic here
                                        },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          minimumSize: Size(80, 40),
                                          side: BorderSide(color: Colors.blue),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        child: Text(
                                          'Update Position',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )
                                    ],
                                  ),
                                ),

                                // Draggable box
                                Center(
                                  child: Container(
                                    width: 360,
                                    height: 360,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey, width: 3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        double boxSize = 100;
                                        double maxX = constraints.maxWidth - boxSize;
                                        double maxY = constraints.maxHeight - boxSize;

                                        return Stack(
                                          children: [
                                            // Draggable box using GestureDetector
                                            Positioned(
                                              left: position.dx,
                                              top: position.dy,
                                              child: GestureDetector(
                                                onPanUpdate: (details) {
                                                  double newX = position.dx + details.delta.dx;
                                                  double newY = position.dy + details.delta.dy;

                                                  newX = newX.clamp(0.0, maxX);
                                                  newY = newY.clamp(0.0, maxY);

                                                  setState(() {
                                                    position = Offset(newX, newY);
                                                  });
                                                  setModalState(() {}); // refresh modal content
                                                },
                                                child: Container(
                                                  width: template.width,
                                                  height: template.height,

                                                  decoration: BoxDecoration(
                                                    color: hexToColor(template.backgroundColor),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: hexToColor(template.borderColor), // Border color
                                                      width: 2.0,         // Border width
                                                    ),
                                                   // boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                                                  ),

                                                  child: Column(
                                                    children: [

                                                      Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                       Padding(
                                                         padding: const EdgeInsets.all( 8.0),
                                                         child: Image.memory(bytes ,
                                                         width: template.elements[1].width,
                                                           height: template.elements[1].height,
                                                         ),
                                                       ),
                                                              Column(
                                                                children: [
                                                                  Row(
                                                                    children: [
Column(
  children: [
    Text(
      'code : ',
      style: TextStyle(
        color: Colors.grey,
        fontSize: 11.0,
      ),
    ),
    Text(
      'type : ',
      style: TextStyle(
        color: Colors.grey,
        fontSize: 11.0,
      ),
    ),
    Text(
      'date : ',
      style: TextStyle(
        color: Colors.grey,
        fontSize: 11.0,
      ),
    ),
    Text(
      'DHJ : ',
      style: TextStyle(
        color: Colors.grey,
        fontSize: 11.0,
      ),
    ),
  ],
),

   Column(
     children: [
       Text(
         doc.barcode,
         style: TextStyle(
           fontSize: 11.0,
         ),
         maxLines: 2,      // Wraps to the second line if needed
         overflow: TextOverflow.visible, // No ellipsis
         softWrap: true,   // Enables line wrapping
       ),
       Text(
         doc.cabinetName,
         style: TextStyle(
           fontSize: 11.0,
         ),
       ),
       Text(
         doc.yyyyMmDd,
         style: TextStyle(
           fontSize: 11.0,
         ),
       ),
       Text(
        doc.yyyyMmDd,
         style: TextStyle(fontSize: 11.0),
       ),



     ],
   )
                                                                    ],
                                                                  )
                                                                ],
                                                              )
                                                              // Column(
                                                              //   mainAxisAlignment: MainAxisAlignment.start,
                                                              //   children: [
                                                              //     Row(
                                                              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              //       children: [
                                                              //         Text(
                                                              //           'code : ',
                                                              //           style: TextStyle(
                                                              //             color: Colors.grey,
                                                              //             fontSize: 11.0,
                                                              //           ),
                                                              //         ),
                                                              //         Text(
                                                              //           'ABC123_2257',
                                                              //           style: TextStyle(
                                                              //             fontSize: 11.0,
                                                              //           ),
                                                              //         ),
                                                              //       ],
                                                              //     ),
                                                              //     Row(
                                                              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              //       children: [
                                                              //         Text(
                                                              //           'type : ',
                                                              //           style: TextStyle(
                                                              //             color: Colors.grey,
                                                              //             fontSize: 11.0,
                                                              //           ),
                                                              //         ),
                                                              //         Text(
                                                              //           template.elements[3].type,
                                                              //           style: TextStyle(
                                                              //             fontSize: 11.0,
                                                              //           ),
                                                              //         ),
                                                              //       ],
                                                              //     ),
                                                              //     Row(
                                                              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              //       children: [
                                                              //         Text(
                                                              //           'date : ',
                                                              //           style: TextStyle(
                                                              //             color: Colors.grey,
                                                              //             fontSize: 11.0,
                                                              //           ),
                                                              //         ),
                                                              //         Text(
                                                              //           '2025 - 04-01',
                                                              //           style: TextStyle(
                                                              //             fontSize: 11.0,
                                                              //           ),
                                                              //         ),
                                                              //       ],
                                                              //     ),
                                                              //     Row(
                                                              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              //       children: [
                                                              //         Text(
                                                              //           'DHJ : ',
                                                              //           style: TextStyle(
                                                              //             color: Colors.grey,
                                                              //             fontSize: 11.0,
                                                              //           ),
                                                              //         ),
                                                              //         Text(
                                                              //           '2025 - 04-01',
                                                              //           style: TextStyle(
                                                              //             fontSize: 11.0,
                                                              //           ),
                                                              //         ),
                                                              //       ],
                                                              //     ),
                                                              //   ],
                                                              // )
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                      SizedBox(height: 10,),
                                                      Image.asset('assets/bar-code.PNG',
                                                        width: template.elements[13].width,
                                                        height: template.elements[13].height,
                                                      ),
                                                    ],
                                                  )
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                icon: Icon(Symbols.preview),
              );
            }).toList(),
          ),





          IconButton(onPressed: (){
            addImageToSignedPdf(
              pdfUrl: sasUrl.toString(),
              imageBase64: _imageBase64.toString(),
              positionX: double.parse(positionX!),
              positionY: double.parse(positionY!),
              overlayWidth: templateData!.width,
              overlayHeight: templateData!.height,
              pdfContainerWidth: 0,
              pdfContainerHeight: 0,
              workspaceDataWidth: 0,
              workspaceDataHeight: 0,
            );

          }, icon: Icon(Symbols.file_save)),
          IconButton(onPressed: () {
            _downloadDocument(sasUrl!);
          }, icon: Icon(Icons.save_alt)),


        ],

      ),
    );
  }

  Future<void> fetchArchiveDocumentsDetails() async {
    final url = Uri.parse("${ApiUrls.baseUrl}ArchiveAPI/ArchiveDocumentDetails");
    final body = {
      "DocumentId": widget.documentId,
      "ReferenceId": "0",
      "ShareId": widget.shareId,
      "CreatedBy": widget.createdBy,
      "OrganizationId": widget.organizationId,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        print(body);
        final json = jsonDecode(response.body);
        print(json);
        final archiveList = json['Data']['ArchiveJson'] as List;
        print('test detail');
        print(archiveList);

        final templateDatafetch = archiveList[0]['TemplateData'];
        print('testing here '+ templateDatafetch);
        final templateDataget = jsonDecode(templateDatafetch);

        final elements = templateDataget['elements'] as List<dynamic>;


   print(elements[1]['fileUrl']);




        // final imageElement = elements.firstWhere(
        //       (e) => e['type'] == 'image',
        //   orElse: () => null,
        // );
        //
        // if (imageElement != null) {
        //   final fileUrl = imageElement['fileUrl'];
        //   print("✅ Found fileUrl: $fileUrl");
        // }







        if (archiveList.isNotEmpty) {
          setState(() {
            documentUrl = archiveList[0]['Url'];
            positionX = archiveList[0]['PositionX'];
            positionY = archiveList[0]['PositionY'];
            documents = archiveList.map((e) => ArchiveDocumentDetailModel.fromJson(e)).toList();
            templateData = TemplateData.fromJson(templateDataget);
            showTemplateWidget = true; // show widget
            isLoading = false;
          });
print(positionX);
print(positionY);
print('positon testing');
print(documentUrl);

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Future.delayed(const Duration(milliseconds: 1000)); // allow render
            await captureWidgetAsImage();
          });

        } else {
          setState(() {
            error = "No documents found";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = "HTTP Error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error: $e";
        isLoading = false;
      });
    }
  }

  // Future<void> addImageToSignedPdf({
  //   required String pdfUrl,
  //   required String imageBase64,
  //   required double positionX,
  //   required double positionY,
  //   required double overlayWidth,
  //   required double overlayHeight,
  //   required double pdfContainerWidth,
  //   required double pdfContainerHeight,
  //   required double workspaceDataWidth,
  //   required double workspaceDataHeight,
  // }) async {
  //   final url = Uri.parse('${ApiUrls.baseUrl}ArchiveAPI/AddImageToSignedPdf');
  //
  //   final Map<String, dynamic> requestBody = {
  //     "pdfUrl": pdfUrl,
  //     "imageBase64": imageBase64,
  //     "positionX": positionX,
  //     "positionY": positionY,
  //     "overlayWidth": overlayWidth,
  //     "overlayHeight": overlayHeight,
  //     "pdfContainerWidth": pdfContainerWidth,
  //     "pdfContainerHeight": pdfContainerHeight,
  //     "workspaceDataWidth": workspaceDataWidth,
  //     "workspaceDataHeight": workspaceDataHeight,
  //   };
  //
  //   final jsonString = jsonEncode(requestBody);
  //   print("📦 Request Body: $jsonString"); // <- PRINTS THE BODY
  //
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //       },
  //       body: jsonEncode(requestBody),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       print("✅ Success: ${response.body}");
  //     } else {
  //       print("❌ Error ${response.statusCode}: ${response.body}");
  //     }
  //   } catch (e) {
  //     print("⚠️ Exception occurred: $e");
  //   }
  // }
  Future<void> addImageToSignedPdf({
    required String pdfUrl,
    required String imageBase64,
    required double positionX,
    required double positionY,
    required double overlayWidth,
    required double overlayHeight,
    required double pdfContainerWidth,
    required double pdfContainerHeight,
    required double workspaceDataWidth,
    required double workspaceDataHeight,
  }) async {
    final url = Uri.parse('${ApiUrls.baseUrl}ArchiveAPI/AddImageToSignedPdf');

    final Map<String, dynamic> requestBody = {
      "pdfUrl": pdfUrl,
      "imageBase64": imageBase64,
      "positionX": positionX,
      "positionY": positionY,
      "overlayWidth": overlayWidth,
      "overlayHeight": overlayHeight,
      "pdfContainerWidth": pdfContainerWidth,
      "pdfContainerHeight": pdfContainerHeight,
      "workspaceDataWidth": workspaceDataWidth,
      "workspaceDataHeight": workspaceDataHeight,
    };

    print("📦 Request Body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {

        print(response.body);
        print('response body');
        Uint8List pdfBytes = response.bodyBytes;

        print(imageBase64);
        print(positionX);
        print(positionY);
        print(overlayWidth);
        print(overlayHeight);
        print(pdfContainerWidth);
        print(pdfContainerHeight);
        print(workspaceDataWidth);



      } else {
        print("❌ Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("⚠️ Exception occurred: $e");
    }
  }

  Future<void> _downloadDocumentByPath(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print("❌ Could not launch file at $filePath");
      }
    } else {
      print("❌ File not found at $filePath");
    }
  }

  Widget buildTemplateDisplay({
    required TemplateData template,
    required Offset position,
    required Function(Offset) onPositionChanged,
  }) {
    final String? fileUrl = template.elements[1].fileUrl;
    final String? base64String = fileUrl?.split(',').last;
    final Uint8List bytes = base64Decode(base64String!);



        return RepaintBoundary(
          key: _repaintKey ,
          child:  Container(
            width: template.width,
            height: template.height,
            decoration: BoxDecoration(
              color: hexToColor(template.backgroundColor),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hexToColor(template.borderColor),
                width: 2.0,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0 , left: 8.0),
                          child: Image.memory(
                            bytes,
                            width: template.elements[1].width,
                            height: template.elements[1].height,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: documents.map((document) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabelValue('code :', document.barcode),
                            _buildLabelValue('type :', document.cabinetName),
                            _buildLabelValue('date :', document.yyyyMmDd),
                            _buildLabelValue('DHJ :', document.yyyyMmDd),
                          ],
                        );
                      }).toList(),
                    ),

                  ],
                ),
                Image.asset('assets/bar-code.PNG',
                  width: template.elements[13].width,
                  height: template.elements[13].height,
                ),
              ],
            ),
          ),
        );


  }


  Widget _buildLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11.0)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 11.0)),
        ],
      ),
    );
  }

  Future<void> captureWidgetAsImage() async {
    try {
      RenderRepaintBoundary boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final String imageBase64 = base64Encode(pngBytes);

      setState(() {
        _capturedImage = pngBytes; // Store in local class variable
        _imageBase64 = imageBase64;
      });
      print("img testing");
      print(_capturedImage);
      print(_imageBase64);

      debugPrint('Image captured and stored in _capturedImage!');
    } catch (e) {
      debugPrint('Error capturing widget: $e');
    }
  }


  Future<void> fetchAndSetSasUrl(String filePath) async {
    setState(() {
      isLoading = true;
    });

    try {
      final expiryTime = DateTime.now().add(Duration(days: 1));
      final expiryTimeString = expiryTime.toUtc().toIso8601String();
      final url = Uri.parse(
        '${ApiUrls.baseUrl}FileUploadAPI/NewGenerateSASTokenUrl',
      ).replace(
        queryParameters: {
          'filePath': filePath,
          'expiryTime': expiryTimeString,
        },
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          sasUrl = responseData['sasUrl'] as String;
          isLoading = false;
        });
        print(sasUrl);
      } else {
        throw Exception('Failed to get SAS URL: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = "Error getting SAS URL: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _checkDocumentType(String url) async {
    if (url.endsWith('.pdf')) {
      _fileType = 'pdf';
      await _handlePdf(sasUrl!);
    } else if (url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.PNG') ||
        url.endsWith('.JPG') ||
        url.endsWith('.JPEG')) {
      _fileType = 'image';
      await _handleImage(sasUrl!);
    } else if (url.endsWith('.mp4')) {
      _fileType = 'video';
      await _handleVideo(sasUrl!);
    } else if (url.endsWith('.mp3')) {
      _fileType = 'audio';
      await _handleAudio(sasUrl!);
    } else if (url.endsWith('.doc') ||
        url.endsWith('.docx') ||
        url.endsWith('.xls') ||
        url.endsWith('.xlsx') ||
        url.endsWith('.ppt') ||
        url.endsWith('.pptx')) {
      _fileType = 'web';
      await _handleWeb(sasUrl!);
    } else if (url.endsWith('.txt')) {
      _fileType = 'text';
      await _handleText(sasUrl!);
    } else {
      _fileType = 'unsupported';
      setState(() {
        isLoading = false;
      });
    }
  }

  Color hexToColor(String code) {
    return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  Future<void> _handlePdf(String url) async {
    try {
      final filePath = await _downloadFile(url);
      setState(() {
        _localFilePath = filePath;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error downloading PDF: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleImage(String url) async {
    try {
      final filePath = await _downloadFile(url);
      setState(() {
        _localFilePath = filePath;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error downloading image: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleVideo(String url) async {
    try {
      final filePath = await _downloadFile(url);
      setState(() {
        _localFilePath = filePath;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error downloading video: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleAudio(String url) async {
    try {
      final filePath = await _downloadFile(url);
      setState(() {
        _localFilePath = filePath;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error downloading audio: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleText(String url) async {
    try {
      final filePath = await _downloadFile(url);
      final content = await File(filePath).readAsString();
      setState(() {
        _localFilePath = filePath;
        _textContent = content;
        _textController.text = content;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error handling text file: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _handleWeb(String url) async {
    setState(() {
      isLoading = false;
    });
  }

  Future<String> _downloadFile(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.${url.split('.').last}');
      await file.writeAsBytes(bytes);
      return file.path;
    } else {
      throw 'Failed to download file';
    }
  }




  void _downloadDocument(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class AudioPlayerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  const AudioPlayerScreen(this.fileName, {super.key, required this.filePath});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _duration = duration;
      });
    });
    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _position = position;
      });
    });
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      await _audioPlayer.setSource(UrlSource(widget.filePath));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading audio: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Audio Player'),
      // ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.fileName,
              style: const TextStyle(fontSize: 15),
            ),
            Slider(
              value: _position.inSeconds.toDouble(),
              min: 0,
              max: _duration.inSeconds.toDouble(),
              onChanged: (value) {
                setState(() {
                  _audioPlayer.seek(Duration(seconds: value.toInt()));
                });
              },
            ),
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 50,
              ),
              onPressed: () {
                setState(() {
                  if (_isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play(UrlSource(widget.filePath));
                  }
                });
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_isPlaying) {
              _audioPlayer.pause();
            } else {
              _audioPlayer.play(UrlSource(widget.filePath));
            }
          });
        },
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String filePath;
  const VideoPlayerScreen({super.key, required this.filePath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {}); // Refresh the UI when the video is initialized
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  appBar: AppBar(title: Text('Video Player')),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}