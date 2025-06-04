import 'dart:io';

import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:azblob/azblob.dart';
import 'package:azure_blob_flutter/azure_blob_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mime/mime.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_archive/models/archive_favorite_model.dart';
import 'package:stream_archive/screens/doc_details.dart';
import 'package:stream_archive/screens/profile_personal_info_page.dart';
import 'package:xml/xml.dart';
import '../data/user_data_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf/pdf.dart' as pw; // Alias for pdf package
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf; // Alias for Syncfusion package
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:flutter/material.dart' as material;





import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdf/pdf.dart' as pdf;

import '../models/all_labels_model.dart';
import '../models/archive_inbox_model.dart';
import '../models/archive_pin_model.dart';
import '../models/archive_share_by_me_model.dart';
import '../models/archive_share_with_me_model.dart';
import '../models/archive_trash_model.dart';
import 'dart:ui' as ui;

import 'package:pdf_render/pdf_render.dart' as pdfRender;
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion_pdf;

import 'package:http_parser/http_parser.dart';

import '../models/cabinate_list_model.dart';
import '../url/api_url.dart'; // Required for Content-Type

class AllDocList extends StatefulWidget {
  const AllDocList({super.key});

  @override
  State<AllDocList> createState() => _AllDocListState();
}

class _AllDocListState extends State<AllDocList> {
  int _selectedIndex = 0; // Index of the selected bottom navigation bar item
  Map<String, dynamic> userData = {};
  bool _isLoading = true; // To handle loading state
  List<dynamic> documents = [];
  List<dynamic> pinDocuments = [];
  List<Cabinet> cabinets = [];
  List<Label> labels = [];
  bool isLoading = false;
  bool showList = false;
  RefreshController _refreshControllerForMainArchiveList =
  RefreshController(initialRefresh: false);
  RefreshController _refreshControllerForFavorite =
  RefreshController(initialRefresh: false);
  RefreshController _refreshControllerForTrash =
  RefreshController(initialRefresh: false);
  RefreshController _refreshControllerForShareWithMe =
  RefreshController(initialRefresh: false);
  RefreshController _refreshControllerForShareByMe =
  RefreshController(initialRefresh: false);

  String? globalThumbnailPath;
  String? globalThumbnailName;
  File? thumbnailNamepdf;
  String? thumbnailName;

  int currentPage = 1;
  List<FavoriteDocument> favoriteDocuments = [];
  List<TrashItem> trashItems = [];
  List<ArchiveDocumentShareWithMe> shareWithMeList = [];
  List<ArchiveDocumentShareByMe> shareByMeList = [];
  bool isShareWithMeActive = true;

  // List<File> _selectedFiles = [];
  List<XFile> _selectedFiles = [];
  List<String> _fileUploadStatuses = [];
  bool isExistFile = false;
  List<Map<String, dynamic>> _GacAttachmentFileuplod = [];
  String _sasToken = '';
  String _blobUrl = '';
  int _expiryTime = 0;
  Uint8List? bodyBytes;
  int  cabinetId = 0;
  int totalDocCount = 0;
  TextEditingController searchController = TextEditingController();

  ///////////////For OCR /////////////
  File? _selectedFile;
  String _fileType = '';
  String _extractedText = '';
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _showSearchBar = false;
  String _searchQuery = "";

  Future<void> _pickAndProcessFile(StateSetter setModalState) async {
    debugPrint('Starting file picker...');
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'txt' , 'doc' , 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String extension = file.path.split('.').last.toLowerCase();
      debugPrint('File selected: ${file.path}, Extension: $extension');

      // Update UI immediately after selecting a file
      setModalState(() {
        _selectedFile = file;
        _extractedText = ''; // Clear previous text
        _fileType = extension.toUpperCase();
      });

      if (['jpg', 'jpeg', 'png'].contains(extension)) {
        _processImage(file, setModalState);
      } else if (extension == 'pdf') {
        _processPdf(file, setModalState);
      } else if (extension == 'txt') {
        _processTextFile(file, setModalState);
      }
      else if(extension == 'docx'){
        _processDocxFile(file , setModalState );
      }
      else if(extension == 'doc'){
        _processDocFile(file , setModalState );
      }
      else {
        setModalState(() {
          _fileType = 'Unsupported';
          _extractedText = 'File type not supported.';
        });
        debugPrint('Unsupported file type: $extension');
      }
    } else {
      debugPrint('No file selected.');
    }
  }


  // Process an image file with OCR
  Future<void> _processImage(File imageFile, StateSetter setModalState) async {
    debugPrint('Processing image: ${imageFile.path}');
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      debugPrint('InputImage created successfully');
      final RecognizedText recognizedText =
      await _textRecognizer.processImage(inputImage);
      debugPrint('OCR completed successfully');

      setModalState(() {
        _extractedText = recognizedText.text.isEmpty
            ? 'No text found in image.'
            : recognizedText.text;
      });

      debugPrint('Extracted text from image: $_extractedText');
    } catch (e) {
      setModalState(() {
        _extractedText = 'Error processing image: $e';
      });
      debugPrint('Error processing image: $e');
    }
  }


  // Process a PDF file by converting pages to images and running OCR
  // Future<void> _processPdf(File pdfFile) async {
  //   debugPrint('Processing PDF: ${pdfFile.path}');
  //   try {
  //     String extractedText = '';
  //     final pdfRender.PdfDocument doc = await pdfRender.PdfDocument.openFile(pdfFile.path);
  //     debugPrint('PDF opened with ${doc.pageCount} pages');
  //
  //     for (int i = 1; i <= doc.pageCount; i++) {
  //       debugPrint('Processing page $i');
  //       final pdfRender.PdfPage page = await doc.getPage(i);
  //       final pdfRender.PdfPageImage? pageImage = await page.render(
  //         fullWidth: 600,
  //         fullHeight: 800,
  //       );
  //
  //       if (pageImage != null) {
  //         debugPrint('Page $i rendered successfully');
  //         final Directory tempDir = await getTemporaryDirectory();
  //         final String tempPath = '${tempDir.path}/page_$i.png';
  //         final File tempFile = File(tempPath)
  //           ..writeAsBytesSync(pageImage.pixels);
  //         debugPrint('Temporary image file created: $tempPath');
  //
  //         final inputImage = InputImage.fromFilePath(tempFile.path);
  //         final RecognizedText recognizedText =
  //         await _textRecognizer.processImage(inputImage);
  //         extractedText += '${recognizedText.text}\n';
  //         debugPrint('Text extracted from page $i: ${recognizedText.text}');
  //
  //         tempFile.deleteSync();
  //         debugPrint('Temporary file deleted: $tempPath');
  //       } else {
  //         debugPrint('Failed to render page $i');
  //       }
  //     }
  //
  //     setState(() {
  //       _extractedText = extractedText.isEmpty ? 'No text found in PDF.' : extractedText;
  //     });
  //     debugPrint('Extracted text from PDF: $_extractedText');
  //   } catch (e) {
  //     setState(() {
  //       _extractedText = 'Error processing PDF: $e';
  //     });
  //     debugPrint('Error processing PDF: $e');
  //   }
  // }
  Future<void> _processPdf(File pdfFile, StateSetter setModalState) async {
    debugPrint('Processing PDF: ${pdfFile.path}');
    try {
      StringBuffer extractedTextBuffer = StringBuffer();

      final syncfusion_pdf.PdfDocument document =
      syncfusion_pdf.PdfDocument(inputBytes: pdfFile.readAsBytesSync());

      debugPrint('PDF opened with ${document.pages.count} pages');

      for (int i = 0; i < document.pages.count; i++) {
        debugPrint('Extracting text from page ${i + 1}');
        String pageText = syncfusion_pdf.PdfTextExtractor(document)
            .extractText(startPageIndex: i, endPageIndex: i);

        if (pageText.isNotEmpty) {
          List<String> lines = pageText.split('\n');

          String? footerText;
          List<String> mainContent = [];

          for (String line in lines) {
            if (line.trim().isEmpty) continue; // Skip empty lines

            // Detect footer based on common patterns (e.g., "Page X", copyright notices, etc.)
            if (RegExp(r'^\s*Page\s*\d+\s*$', caseSensitive: false).hasMatch(line.trim())) {
              footerText = line.trim(); // Store footer separately
            } else {
              mainContent.add(line); // Add normal text
            }
          }

          // Add main content first
          extractedTextBuffer.writeln(mainContent.join('\n'));

          // Append footer at the bottom if found
          if (footerText != null) {
            extractedTextBuffer.writeln('\n$footerText');
          }

          // Update UI after processing each page
          setModalState(() {
            _extractedText = extractedTextBuffer.toString();
          });
        }
      }

      document.dispose();

      setModalState(() {
        _extractedText = extractedTextBuffer.isEmpty
            ? 'No text found in PDF.'
            : extractedTextBuffer.toString();
      });

      debugPrint('Final extracted text:\n$_extractedText');
    } catch (e) {
      setModalState(() {
        _extractedText = 'Error processing PDF: $e';
      });
      debugPrint('Error processing PDF: $e');
    }
  }





  // Process a text file by reading its contents
  Future<void> _processTextFile(File textFile, StateSetter setModalState) async {
    debugPrint('Processing text file: ${textFile.path}');
    try {
      final String content = await textFile.readAsString();
      debugPrint('Text file read successfully');

      setModalState(() {
        _extractedText = content.isEmpty ? 'No text found in file.' : content;
      });

      debugPrint('Extracted text from text file: $_extractedText');
    } catch (e) {
      setModalState(() {
        _extractedText = 'Error reading text file: $e';
      });
      debugPrint('Error reading text file: $e');
    }
  }

  /////////////////process text form docx
  Future<void> _processDocxFile(File file, StateSetter setModalState) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Locate document.xml inside .docx archive
      final docXml = archive.files.firstWhere(
            (file) => file.name == 'word/document.xml',
        orElse: () => throw Exception('document.xml not found in .docx file'),
      );

      final xmlString = String.fromCharCodes(docXml.content);
      final document = XmlDocument.parse(xmlString);

      // Extract text content
      final textElements = document.findAllElements('w:t');
      final extractedText = textElements.map((node) => node.text).join(' ');

      setModalState(() {
        _extractedText = extractedText.isEmpty ? 'No text found in file.' : extractedText;
      });

      debugPrint('Extracted text from .docx: $_extractedText');
    } catch (e) {
      setModalState(() {
        _extractedText = 'Error reading .docx file: $e';
      });
      debugPrint('Error reading .docx file: $e');
    }
  }

/////////////////process text form doc

  Future<void> _processDocFile(File file, StateSetter setModalState) async {
    try {
      // Read the .doc file as raw bytes
      final bytes = await file.readAsBytes();

      // Attempt to extract text by converting bytes to a string
      // Note: .doc is binary, so this is a crude heuristic and may not work well
      String rawContent = '';
      try {
        // Try UTF-8 decoding (may fail or produce garbage for binary data)
        rawContent = utf8.decode(bytes, allowMalformed: true);
      } catch (e) {
        // If UTF-8 fails, fall back to Latin-1 (ISO-8859-1) to capture some text
        rawContent = latin1.decode(bytes, allowInvalid: true);
      }

      // Filter out non-printable characters (heuristic to clean up binary noise)
      final extractedText = rawContent
          .split('')
          .where((char) => char.codeUnitAt(0) >= 32 && char.codeUnitAt(0) <= 126)
          .join()
          .trim();

      // Update the modal state with the result
      setModalState(() {
        _extractedText = extractedText.isEmpty ? 'No readable text found in .doc file.' : extractedText;
      });

      debugPrint('Extracted text from .doc: $_extractedText');
    } catch (e) {
      setModalState(() {
        _extractedText = 'Error reading .doc file: $e';
      });
      debugPrint('Error reading .doc file: $e');
    }
  }


  // @override
  // void dispose() {
  //   _textRecognizer.close();
  //   debugPrint('TextRecognizer disposed');
  //   super.dispose();
  // }

  // List of widgets to display for each bottom navigation bar item
  List<Widget> _getWidgetOptions() {
    return <Widget>[
      // First Page: Buttons

      Column(
        children: [
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [
          //     Padding(
          //       padding: const EdgeInsets.only(right: 8.0),
          //       child: GestureDetector(
          //         onTap: () {
          //           setState(() {
          //             showList = !showList;
          //           });
          //         },
          //         child: Icon(showList ? Icons.grid_on : Icons.list),
          //       ),
          //     ),
          //   ],
          // ),
          // showList
          //     ?
          Expanded(
              child: SlidableAutoCloseBehavior(
                  child: SmartRefresher(
                  controller: _refreshControllerForMainArchiveList,
                  onRefresh: () async {

                    setState(() {
                      cabinetId = 0;
                    });
                    // Reset the page and fetch again
                    await fetchDocuments(isRefresh: true, cabinetId: cabinetId);
                    _refreshControllerForMainArchiveList.refreshCompleted();
                  },
                  enablePullUp: true,
                  enablePullDown: true,
                  onLoading: () async {
                    print('working');
                    // Load more documents
                    await fetchDocuments(isRefresh: false, cabinetId: cabinetId);
                  },
                  child: ListView.builder(
                    itemCount: pinDocuments.length +
                        documents
                            .length, // Combine the length of both lists
                    itemBuilder: (context, index) {
                      // Determine which list the current index belongs to
                      final isPinDocument = index < pinDocuments.length;
                      final doc = isPinDocument
                          ? pinDocuments[index]
                          : documents[index - pinDocuments.length];

                      return Slidable(
                          key: ValueKey(index),
                          startActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.15,
                            children: [
                              CustomSlidableAction(
                                backgroundColor:
                                Colors.black.withOpacity(0.10),
                                onPressed: (BuildContext
                                context) async {
                                  // Update the memo pin status

                                  // Refresh the data after pinning
                                  print("working slide");
                                },
                                child:Icon(
                                  doc.isPin == true
                                      ? Icons.push_pin
                                      : Icons
                                      .push_pin, // Conditional icon
                                  color: doc.isPin == true ?  Colors.blue : Colors.black,
                                  // Icon color
                                  size: 20,
                                )
                              ),
                            ],
                          ),
                          endActionPane: ActionPane(
                            extentRatio: 0.25,
                            motion: const BehindMotion(),
                            children: [
                              CustomSlidableAction(
                                backgroundColor:
                                Colors.black.withOpacity(0.10),
                                foregroundColor: doc.isFavorite
                                    ? Colors.yellow
                                    : Colors.white,
                                onPressed: (BuildContext
                                context) async {
                                  print(doc.isFavorite);
                                  print("working slide");
                                  // setState(() {
                                  //   print("test1");
                                  //   doc.isFavorite = !doc
                                  //       .isFavorite; // Update the favorite status of the mail
                                  //   print("test2");
                                  // });
                                  print("docId" + doc.documentId.toString());
                                  print("shareId" + doc.shareId.toString());
                                  print("Favorite " + doc.isFavorite.toString());
                                  print("CabinetId " + cabinetId.toString());
                                 await archiveFavorite(doc.documentId , doc.shareId , doc.isFavorite);

                                 await fetchDocuments(cabinetId: cabinetId);
                                  print("After Favorite " + doc.isFavorite.toString());
                                },
                                child: Icon(
                                  doc.isFavorite
                                      ? Icons.star
                                      : Icons
                                      .star_border_outlined,
                                  color: doc.isFavorite
                                      ? Colors
                                      .yellow.shade600
                                      : Colors.black,
                                  size: 20.0,
                                ),
                              ),
                              CustomSlidableAction(
                                backgroundColor:
                                Colors.black.withOpacity(0.10),
                                onPressed: (BuildContext
                                context) async {
                                  // Delete the memo

                                },
                                child: Icon(
                                    LineAwesomeIcons
                                        .trash_solid,
                                    size: 20.0,
                                    color: Colors
                                        .black
                                ),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                minLeadingWidth: 10,
                                horizontalTitleGap: 2,
                                // leading: Container(
                                //   width:
                                //   50,
                                //   // Explicitly set the width of the leading widget
                                //   height:
                                //   50,
                                //   // Explicitly set the height of the leading widget
                                //   child: ClipRRect(
                                //     borderRadius: BorderRadius
                                //         .zero,
                                //     // Removes the circle and gives a square look
                                //     child:  _getFileIconForActivity(doc.documentName),
                                //   ),
                                // ),
                                title: Text(
                                  getShortenedText(doc.documentName),
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color:
                                    doc.isRead ? Colors.black : Colors.blue,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start, // Aligns the text to the left
                                  children: [
                                    Text(
                                      doc.userName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: doc.isRead
                                            ? Colors.black
                                            : Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      getShortenedText(doc.description),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: doc.isRead
                                            ? Colors.grey
                                            : Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Show version only if versionName is not null or empty
                                    if (doc.versionName.isNotEmpty)
                                      Container(
                                        color: Colors.grey[200],
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Text(
                                          "Version ${doc.versionName}",
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: doc.isRead ? Colors.black : Colors.blue,
                                          ),
                                        ),
                                      ),

                                    SizedBox(height: 5),

                                    if (doc.createdDateString != null && doc.createdDateString.isNotEmpty)
                                      Text(
                                        doc.createdDateString.toString(),
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: doc.isRead ? Colors.black : Colors.blue,
                                        ),
                                      ),

                                  ],
                                ),



                                // Row(
                                //   mainAxisSize: MainAxisSize
                                //       .min,
                                //   // Ensures the Row only takes up necessary space
                                //   children: [
                                //     if (doc.isPin)
                                //       Icon(
                                //         Icons.push_pin_sharp,
                                //         size: 15,
                                //         color: Colors.blue,
                                //       ),
                                //     if (doc.isFavorite)
                                //       Icon(
                                //         LineAwesomeIcons.star,
                                //         size: 15,
                                //         color: Colors.yellow.shade800,
                                //       ),
                                //     IconButton(
                                //       icon: Icon(
                                //         Symbols.keyboard_arrow_down,
                                //         size: 20.0,
                                //         color: Colors.grey,
                                //       ),
                                //       onPressed: () {
                                //         // Handle more options
                                //         showModalBottomSheet(
                                //           context: context,
                                //           builder: (BuildContext context) {
                                //             return Container(
                                //               height:
                                //               450,
                                //               // Set the height of the bottom sheet
                                //               width: double.infinity,
                                //               color: Colors
                                //                   .white,
                                //               // Background color of the bottom sheet
                                //               child: Padding(
                                //                 padding: const EdgeInsets.only(
                                //                     top: 20.0),
                                //                 child: Column(
                                //                   children: [
                                //                     Container(
                                //                       height: 5,
                                //                       width: 60,
                                //                       decoration: BoxDecoration(
                                //                         color:
                                //                         Colors.grey.shade300,
                                //                         borderRadius:
                                //                         BorderRadius.circular(
                                //                             8),
                                //                       ),
                                //                     ),
                                //                     SizedBox(height: 20.0),
                                //                     Container(
                                //                       width:
                                //                       100,
                                //                       // Explicitly set the width of the leading widget
                                //                       height:
                                //                       100,
                                //                       // Explicitly set the height of the leading widget
                                //                       child: ClipRRect(
                                //                         borderRadius:
                                //                         BorderRadius.circular(
                                //                             5.0),
                                //                         child: Image.network(
                                //                           doc.url,
                                //                           fit: BoxFit.cover,
                                //                         ),
                                //                       ),
                                //                     ),
                                //                     SizedBox(height: 20.0),
                                //                     Text(
                                //                         getShortenedText(
                                //                             doc.documentName),
                                //                         style: TextStyle(
                                //                             fontSize: 16.0,
                                //                             fontWeight:
                                //                             FontWeight.w600)),
                                //                     Text(
                                //                         DateFormat(
                                //                             'MMMM dd, yyyy, hh:mm:ss a')
                                //                             .format(DateTime.parse(doc
                                //                             .createdDateWithTime)),
                                //                         style: TextStyle(
                                //                             fontSize: 12.0)),
                                //                     SizedBox(height: 10.0),
                                //                     Container(
                                //                       height: 0.15,
                                //                       color: Colors.grey,
                                //                     ),
                                //                     Expanded(
                                //                       child: ListView(
                                //                         children: [
                                //                           ListTile(
                                //                             leading: Icon(
                                //                                 Symbols.keep_pin),
                                //                             title: Text('Pin'),
                                //                             onTap: () {
                                //                               // Handle tap action
                                //                             },
                                //                           ),
                                //                           ListTile(
                                //                             leading:
                                //                             Icon(Icons.star),
                                //                             title:
                                //                             Text('Favorite'),
                                //                             onTap: () async {
                                //                               await archiveFavorite(
                                //                                   doc.documentId,
                                //                                   doc.shareId,
                                //                                   doc.isFavorite);
                                //                               setState(() {
                                //                                 fetchDocuments(
                                //                                     isRefresh:
                                //                                     true);
                                //                               });
                                //                               Navigator.pop(
                                //                                   context);
                                //                             },
                                //                           ),
                                //                           ListTile(
                                //                             leading:
                                //                             Icon(Icons.mail),
                                //                             title: Text('Unread'),
                                //                             onTap: () {
                                //                               // Handle tap action
                                //                             },
                                //                           ),
                                //                           ListTile(
                                //                             leading: Icon(
                                //                                 Icons.delete),
                                //                             title: Text('Delete'),
                                //                             onTap: () async {
                                //                               await archiveTrash(
                                //                                   doc.shareId,
                                //                                   doc.documentId);
                                //                               setState(() {
                                //                                 fetchDocuments(
                                //                                     isRefresh:
                                //                                     true);
                                //                               });
                                //                               Navigator.pop(
                                //                                   context);
                                //                             },
                                //                           ),
                                //                         ],
                                //                       ),
                                //                     )
                                //                   ],
                                //                 ),
                                //               ),
                                //             );
                                //           },
                                //         );
                                //       },
                                //     ),
                                //   ],
                                // ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => DocDetails(
                                        documentId : doc.documentId.toString(),
                                        referenceId: '0',
                                        shareId: doc.shareId.toString(),
                                        createdBy: userData['userId'].toString(),
                                        organizationId: userData['organizationid'].toString() ,
                                        documentName:doc.documentName

                                    )),
                                  );
                                },
                              ),
                              Container(
                                height: 0.15,
                                color: Colors.grey,
                              ),
                            ],
                          )
                      );
                    },
                  )))
          )
              // :
          // Expanded(
          //     child: SmartRefresher(
          //         controller: _refreshControllerForMainArchiveList,
          //         onRefresh: () async {
          //           // Reset the page and fetch again
          //           await fetchDocuments(isRefresh: true);
          //           _refreshControllerForMainArchiveList.refreshCompleted();
          //         },
          //         enablePullUp: true,
          //         enablePullDown: true,
          //         onLoading: () async {
          //           print('working');
          //           // Load more documents
          //           await fetchDocuments(isRefresh: false);
          //         },
          //         child:GridView.builder(
          //           itemCount: pinDocuments.length + documents.length,
          //           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //             crossAxisCount: 2,
          //             crossAxisSpacing: 8.0,
          //             mainAxisSpacing: 0.0, // No vertical spacing between grid items
          //             childAspectRatio: 1.25,
          //           ),
          //           itemBuilder: (context, index) {
          //             final isPinDocument = index < pinDocuments.length;
          //             final doc = isPinDocument
          //                 ? pinDocuments[index]
          //                 : documents[index - pinDocuments.length];
          //
          //             return Card(
          //               elevation: 4.0,
          //               margin: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0), // No bottom margin
          //               child: InkWell(
          //                 onTap: () {
          //                   Navigator.push(
          //                     context,
          //                     MaterialPageRoute(builder: (context) => DocDetails(
          //                       documentId : doc.documentId.toString(),
          //                       referenceId: '0',
          //                       shareId: doc.shareId.toString(),
          //                       createdBy: userData['userId'].toString(),
          //                       organizationId: userData['organizationid'].toString() ,
          //                       documentName:doc.documentName
          //
          //                     )),
          //                   );
          //                 },
          //                 child: Column(
          //                   crossAxisAlignment: CrossAxisAlignment.start,
          //                   mainAxisAlignment: MainAxisAlignment.spaceBetween, // Push content to top and bottom
          //                   children: [
          //                     Row(
          //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //                       children: [
          //                         Flexible(
          //                           child: Row(
          //                             children: [
          //                               _getFileIconForActivity(doc.documentName),
          //                               SizedBox(width: 5.0),
          //                               Flexible(
          //                                 child: Text(
          //                                   getShortenedText(doc.documentName),
          //                                   style: TextStyle(
          //                                     fontSize: 12.0,
          //                                     fontWeight: FontWeight.w600,
          //                                   ),
          //                                   overflow: TextOverflow.ellipsis,
          //                                 ),
          //                               ),
          //                             ],
          //                           ),
          //                         ),
          //                         IconButton(
          //                           icon: Icon(
          //                             Icons.more_vert_outlined,
          //                             size: 20.0,
          //                             color: Colors.grey,
          //                           ),
          //                           onPressed: () {
          //                             showModalBottomSheet(
          //                               context: context,
          //                               builder: (BuildContext context) {
          //                                 return Container(
          //                                   height: 450,
          //                                   width: double.infinity,
          //                                   color: Colors.white,
          //                                   child: Padding(
          //                                     padding: const EdgeInsets.only(top: 20.0),
          //                                     child: Column(
          //                                       children: [
          //                                         Container(
          //                                           height: 5,
          //                                           width: 60,
          //                                           decoration: BoxDecoration(
          //                                             color: Colors.grey.shade300,
          //                                             borderRadius: BorderRadius.circular(8),
          //                                           ),
          //                                         ),
          //                                         SizedBox(height: 20.0),
          //                                         // Container(
          //                                         //   width: 80,
          //                                         //   height: 100,
          //                                         //
          //                                         //   child: ClipRRect(
          //                                         //     borderRadius: BorderRadius.circular(5.0),
          //                                         //     child: Image.network(
          //                                         //       doc.url,
          //                                         //       fit: BoxFit.cover,
          //                                         //     ),
          //                                         //   ),
          //                                         // ),
          //                                         Container(
          //                                           width: 100,
          //                                           height: 100, // Adjust to 80 if desired
          //                                           alignment: Alignment.bottomCenter,
          //
          //                                           child: ClipRRect(
          //                                             borderRadius: BorderRadius.circular(5.0),
          //                                             child: Image.network(
          //                                               doc.url,
          //                                               fit: BoxFit.cover,
          //                                             ),
          //                                           ),
          //                                         ),
          //                                         SizedBox(height: 20.0),
          //                                         Text(
          //                                           DateFormat('MMMM dd, yyyy, hh:mm:ss a')
          //                                               .format(DateTime.parse(doc.createdDateWithTime)),
          //                                           style: TextStyle(fontSize: 12.0),
          //                                         ),
          //                                         SizedBox(height: 10.0),
          //                                         Container(
          //                                           height: 0.15,
          //                                           color: Colors.grey,
          //                                         ),
          //                                         Expanded(
          //                                           child: ListView(
          //                                             children: [
          //                                               ListTile(
          //                                                 leading: Icon(Symbols.keep_pin),
          //                                                 title: Text('Pin'),
          //                                                 onTap: () {},
          //                                               ),
          //                                               ListTile(
          //                                                 leading: Icon(Icons.star),
          //                                                 title: Text('Favorite'),
          //                                                 onTap: () async {
          //                                                   await archiveFavorite(
          //                                                       doc.documentId,
          //                                                       doc.shareId,
          //                                                       doc.isFavorite);
          //                                                   setState(() {
          //                                                     fetchDocuments(isRefresh: true);
          //                                                   });
          //                                                   Navigator.pop(context);
          //                                                 },
          //                                               ),
          //                                               ListTile(
          //                                                 leading: Icon(Icons.mail),
          //                                                 title: Text('Unread'),
          //                                                 onTap: () {},
          //                                               ),
          //                                               ListTile(
          //                                                 leading: Icon(Icons.delete),
          //                                                 title: Text('Delete'),
          //                                                 onTap: () async {
          //                                                   await archiveTrash(
          //                                                       doc.shareId, doc.documentId);
          //                                                   setState(() {
          //                                                     fetchDocuments(isRefresh: true);
          //                                                   });
          //                                                   Navigator.pop(context);
          //                                                 },
          //                                               ),
          //                                             ],
          //                                           ),
          //                                         ),
          //                                       ],
          //                                     ),
          //                                   ),
          //                                 );
          //                               },
          //                             );
          //                           },
          //                         ),
          //                       ],
          //                     ),
          //                     Expanded( // Wrap the image Row in Expanded to fill remaining space
          //                       child: Row(
          //                         mainAxisAlignment: MainAxisAlignment.center,
          //                         children: [
          //                           Container(
          //                             height: 100, // Fill the available height
          //                             width: 130,
          //                             decoration: BoxDecoration(
          //                               border: material.Border(
          //                                 left: material.BorderSide(color: Colors.indigo.shade50, width: 10.0),
          //                                 top: material.BorderSide(color: Colors.indigo.shade50, width: 10.0),
          //                                 right: material.BorderSide(color: Colors.indigo.shade50, width: 10.0),
          //                               ),
          //                               borderRadius: material.BorderRadius.circular(10.0),
          //                             ),
          //                             child: ClipRRect(
          //                               borderRadius: BorderRadius.zero,
          //                               child: Image.network(
          //                                 doc.url,
          //                                 fit: BoxFit.cover,
          //                               ),
          //                             ),
          //                           ),
          //                         ],
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             );
          //           },
          //         )
          //     )
          // )
        ],
      ),

      // Favorite page Bind here
      isLoading
          ? Center(child:LoadingAnimationWidget.inkDrop(
        color: Colors.deepOrange,
        size: 35,
      ),)
          : favoriteDocuments.isEmpty
          ? Center(child: Text("No documents found"))
          : SmartRefresher(
        controller: _refreshControllerForFavorite,
        onRefresh: () async {
          // Reset the page and fetch again
          await fetchFavoriteDocuments();
          _refreshControllerForFavorite.refreshCompleted();
        },
        child: ListView.builder(
          itemCount: favoriteDocuments.length,
          itemBuilder: (context, index) {
            final doc = favoriteDocuments[index];
            return Column(
              children: [
                ListTile(

                  contentPadding: const EdgeInsets.only(
                      left: 8.0, right: 8.0),
                  minLeadingWidth: 10,
                  horizontalTitleGap: 2,
                  // leading: Container(
                  //   width:
                  //   50, // Explicitly set the width of the leading widget
                  //   height:
                  //   50, // Explicitly set the height of the leading widget
                  //   child: ClipRRect(
                  //     borderRadius: BorderRadius
                  //         .zero, // Removes the circle and gives a square look
                  //     child: _getFileIconForActivity(doc.documentName),
                  //   ),
                  // ),

                  title: Text(getShortenedText(doc.documentName),
                      style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color:
                          doc.isRead ? Colors.black : Colors.blue)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Aligns the text to the left
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        doc.userName,
                        style: TextStyle(
                            fontSize: 11,
                            color:
                            doc.isRead ? Colors.black : Colors.blue),
                      ),
                      Text(
                        getShortenedText(doc.description),
                        style: TextStyle(
                            fontSize: 9,
                            color:
                            doc.isRead ? Colors.grey : Colors.blue),
                      ),
                    ],
                  ),

                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Show version only if versionName is not null or empty
                      if (doc.versionName.isNotEmpty)
                        Container(
                          color: Colors.grey[200],
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            "Version ${doc.versionName}",
                            style: TextStyle(
                              fontSize: 8,
                              color: doc.isRead ? Colors.black : Colors.blue,
                            ),
                          ),
                        ),

                      SizedBox(height: 5),

                      if (doc.createdDateString != null && doc.createdDateString.isNotEmpty)
                        Text(
                          doc.createdDateString.toString(),
                          style: TextStyle(
                            fontSize: 8,
                            color: doc.isRead ? Colors.black : Colors.blue,
                          ),
                        ),

                    ],
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DocDetails(
                          documentId : doc.documentId.toString(),
                          referenceId: '0',
                          shareId: doc.sharedId.toString(),
                          createdBy: userData['userId'].toString(),
                          organizationId: userData['organizationid'].toString() ,
                          documentName:doc.documentName

                      )),
                    );
                  },
                ),
                Container(
                  height: 0.15,
                  color: Colors.grey,
                ),
              ],
            );
          },
        ),
      ),


      ////////Trash list Bind form here

      isLoading
          ? Center(child: LoadingAnimationWidget.inkDrop(
        color: Colors.deepOrange,
        size: 35,
      ),)
          : trashItems.isEmpty
          ? Center(child: Text("No data available"))
          : SmartRefresher(
        controller: _refreshControllerForTrash,
        onRefresh: () async {
          await fetchTrashList();
          _refreshControllerForTrash.refreshCompleted();
        },
        child: ListView.builder(
          itemCount: trashItems.length,
          itemBuilder: (context, index) {
            final doc = trashItems[index];

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.only(
                      left: 8.0, right: 8.0),
                  minLeadingWidth: 10,
                  horizontalTitleGap: 2,
                  // leading: Container(
                  //   width:
                  //   50, // Explicitly set the width of the leading widget
                  //   height:
                  //   50, // Explicitly set the height of the leading widget
                  //   child: ClipRRect(
                  //     borderRadius: BorderRadius
                  //         .zero, // Removes the circle and gives a square look
                  //     child:  _getFileIconForActivity(doc.documentName),
                  //   ),
                  // ),
                  title: Text(getShortenedText(doc.documentName),
                      style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Aligns the text to the left
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        doc.documentName,
                        style:
                        TextStyle(fontSize: 11, color: Colors.black),
                      ),
                      Text(
                        getShortenedText(doc.description),
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Show version only if versionName is not null or empty
                      if (doc.versionName.isNotEmpty)
                        Container(
                          color: Colors.grey[200],
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            "Version ${doc.versionName}",
                            style: TextStyle(
                              fontSize: 8,
                              color: doc.isRead ? Colors.black : Colors.blue,
                            ),
                          ),
                        ),

                      SizedBox(height: 5),

                      if (doc.createdDateString != null && doc.createdDateString.isNotEmpty)
                        Text(
                          doc.createdDateString.toString(),
                          style: TextStyle(
                            fontSize: 8,
                            color: doc.isRead ? Colors.black : Colors.blue,
                          ),
                        ),

                    ],
                  ),
                  onTap: () {
                    print('Tapped on list');
                  },
                ),
                Container(
                  height: 0.15,
                  color: Colors.grey,
                ),
              ],
            );
          },
        ),
      ),



      //Share options here
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isShareWithMeActive = true;
                      fetchShareWithMeList();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    height: 50,
                    alignment: Alignment.center,
                    color:
                    isShareWithMeActive ? Colors.deepOrange : Colors.white,
                    child: Text(
                      'Share with me',
                      style: TextStyle(
                        color:
                        isShareWithMeActive ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isShareWithMeActive = false;
                      fetchShareByMeList();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    height: 50,
                    color:
                    !isShareWithMeActive ? Colors.deepOrange : Colors.white,
                    child: Text(
                      'Share by me',
                      style: TextStyle(
                        color:
                        !isShareWithMeActive ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          isShareWithMeActive
              ? isLoading
              ? Center(child: LoadingAnimationWidget.inkDrop(
            color: Colors.deepOrange,
            size: 35,
          ),)
              : shareWithMeList.isEmpty
              ? Center(child: Text("No data available"))
              : Expanded(
              child: SmartRefresher(
                controller: _refreshControllerForShareWithMe,
                onRefresh: () async {
                  await fetchShareWithMeList();
                  _refreshControllerForShareWithMe.refreshCompleted();
                },
                child: ListView.builder(
                  itemCount: shareWithMeList.length,
                  itemBuilder: (context, index) {
                    final doc = shareWithMeList[index];

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.only(
                              left: 8.0, right: 8.0),
                          minLeadingWidth: 10,
                          horizontalTitleGap: 2,
                          // leading: Container(
                          //   width:
                          //   50, // Explicitly set the width of the leading widget
                          //   height:
                          //   50, // Explicitly set the height of the leading widget
                          //   child: ClipRRect(
                          //     borderRadius: BorderRadius
                          //         .zero,
                          //     // Removes the circle and gives a square look
                          //     child: _getFileIconForActivity(doc.documentName),
                          //   ),
                          // ),
                          title: Text(getShortenedText(doc.documentName),
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // Aligns the text to the left
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                doc.documentName,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.black),
                              ),

                              // Text(
                              //   getShortenedText(doc.description),
                              //   style: TextStyle(
                              //       fontSize: 9, color: Colors.grey),
                              // ),
                            ],
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Show version only if versionName is not null or empty
                              if (doc.versionName.isNotEmpty)
                                Container(
                                  color: Colors.grey[200],
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    "Version ${doc.versionName}",
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: doc.isRead ? Colors.black : Colors.blue,
                                    ),
                                  ),
                                ),

                              SizedBox(height: 5),

                              if (doc.createdDateString != null && doc.createdDateString.isNotEmpty)
                                Text(
                                  doc.createdDateString.toString(),
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: doc.isRead ? Colors.black : Colors.blue,
                                  ),
                                ),

                            ],
                          ),
                          onTap: () {
                            print('Tapped on list');
                          },
                        ),
                        Container(
                          height: 0.15,
                          color: Colors.grey,
                        ),
                      ],
                    );
                  },
                ),
              ))
              :

          ///Share by me
          isLoading
              ? Center(child: LoadingAnimationWidget.inkDrop(
            color: Colors.deepOrange,
            size: 35,
          ),)
              : shareByMeList.isEmpty
              ? Center(child: Text("No data available"))
              : Expanded(
              child: SmartRefresher(
                controller: _refreshControllerForShareByMe,
                onRefresh: () async {
                  await fetchShareByMeList();
                  _refreshControllerForShareByMe.refreshCompleted();
                },
                child: ListView.builder(
                  itemCount: shareByMeList.length,
                  itemBuilder: (context, index) {
                    final doc = shareByMeList[index];

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.only(
                              left: 8.0, right: 8.0),
                          minLeadingWidth: 10,
                          horizontalTitleGap: 2,
                          // leading: Container(
                          //   width:
                          //   50, // Explicitly set the width of the leading widget
                          //   height:
                          //   50, // Explicitly set the height of the leading widget
                          //   child: ClipRRect(
                          //     borderRadius: BorderRadius
                          //         .zero,
                          //     // Removes the circle and gives a square look
                          //     child:  _getFileIconForActivity(doc.documentName),
                          //   ),
                          // ),
                          title: Text(getShortenedText(doc.documentName),
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // Aligns the text to the left
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                doc.documentName,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.black),
                              ),
                              // Text(
                              //   getShortenedText(doc.description),
                              //   style: TextStyle(
                              //       fontSize: 9, color: Colors.grey),
                              // ),
                            ],
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Show version only if versionName is not null or empty
                              if (doc.versionName.isNotEmpty)
                                Container(
                                  color: Colors.grey[200],
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    "Version ${doc.versionName}",
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: doc.isRead ? Colors.black : Colors.blue,
                                    ),
                                  ),
                                ),

                              SizedBox(height: 5),

                              if (doc.createdDateString != null && doc.createdDateString.isNotEmpty)
                                Text(
                                  doc.createdDateString.toString(),
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: doc.isRead ? Colors.black : Colors.blue,
                                  ),
                                ),

                            ],
                          ),
                          onTap: () {
                            print('Tapped on list');
                          },
                        ),
                        Container(
                          height: 0.15,
                          color: Colors.grey,
                        ),
                      ],
                    );
                  },
                ),
              )),
        ],
      ),

    ];
  }

  // Function to handle bottom navigation bar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      fetchDocuments(isRefresh: true, cabinetId: cabinetId);
    } else if (index == 1) {
      _isLoading = true;
      fetchFavoriteDocuments();
    } else if (index == 2) {
      _isLoading = true;
      fetchTrashList();
    } else if (index == 3) {
      _isLoading = true;
      isShareWithMeActive = true;
      fetchShareWithMeList();
    }
  }

  noTapped() {
    print("calling");
  }

  @override
  void initState() {
    super.initState();
    _initialize();
    ; // Load user data when the page initializes
  }

  Future<void> _initialize() async {
    await _loadUserData();
    await fetchDocuments(isRefresh: true, cabinetId: cabinetId);
    fetchCabinetData();
    await fetchLabels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight : 42,
        leading: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          PersonalInformation(loginUserId: userData['userId'])),
                );
              },
              child: CircleAvatar(
                radius: 18.0,
                backgroundImage: userData['userProfile'] == null ||
                    userData['userProfile'] == '' ||
                    userData['userProfile'] == 'NA'
                    ? null // No image if the condition is true
                    : NetworkImage(
                    "https://yrglobaldocuments.blob.core.windows.net/userprofileimages/" +
                        userData['userProfile']),
                child: userData['userProfile'] == null ||
                    userData['userProfile'] == '' ||
                    userData['userProfile'] == 'NA'
                    ? Icon(
                    Icons.person) // Show person icon if condition is true
                    : null, // No icon if there's an image
              ),
            ),
          ],
        ),
        title: const Text('Stream Archive'),
        actions: [


          IconButton(
              onPressed: () {
                // Ensure _activeTile is not null or empty
                if (_selectedIndex == 0) {
                  //_handleSearch(context); // Call search if it's get the data for option in search
                  //   _showBottomSheet(context);
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        height: 250,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Search',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Type to search...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            // Add more widgets if needed
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  // Toggle search bar visibility
                  setState(() {
                    _showSearchBar = !_showSearchBar;

                    // If the search bar is hidden, clear the search field and reload favorite memos
                    if (!_showSearchBar) {
                      searchController.clear(); // Clear the TextField input
                      // _loadFavoriteMemos(
                      //     isRefresh: true); // Reload favorite memos
                    }
                  });
                }
              },
              icon: SvgPicture.asset(
                'assets/svg_icons/search_icon.svg', // Ensure Symbols.search is properly defined or imported

                color: (_selectedIndex == 0)
                    ? Colors
                    .blue // If conditions are met, set the color to blue
                    : null, // Default color (if not matching conditions)
              )),




          Builder(
            builder: (context) {
              return IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                iconSize: 20,
                icon: SvgPicture.asset(
                  'assets/svg_icons/cabinate_icon.svg',
                  width: 20,
                  height: 20,
                  // You can also specify color here if needed
                  // color: Colors.white,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
              _showSearchBar && _selectedIndex != 0 ? 80 : 30),
          child: Column(
            children: [
              if (_showSearchBar && _selectedIndex != 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5.0, vertical: 5.0),
                  child: Container(
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      // border: Border.all(color: Colors.grey),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 15.0,
                      ),
                      child: TextField(
                        controller: searchController,
                        // autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.0,
                            fontStyle: FontStyle.italic,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                        ),
                        style: const TextStyle(
                            color: Colors.black, fontSize: 14.0),
                        cursorHeight: 22.0,
                        onChanged: (query) {
                          if (_selectedIndex == 1) {
                            setState(() {
                              _searchQuery = query;
                            });
                            fetchFavoriteDocuments(query: _searchQuery);
                          }
                          if (_selectedIndex == 2) {
                            setState(() {
                              _searchQuery = query;
                              //_loadSentMemos(isRefresh: true);
                            });
                          }
                          if (_selectedIndex == 3 && isShareWithMeActive) {
                            setState(() {
                              _searchQuery = query;

                            });
                            fetchShareWithMeList(query: _searchQuery);
                          }
                          if (_selectedIndex == 3 && !isShareWithMeActive) {
                            setState(() {
                              _searchQuery = query;

                            });
                            fetchShareByMeList(query: _searchQuery);
                          }
                         else {
                            _searchQuery = query;
                            // filterMemos();
                            print(_searchQuery);
                          }
                        },
                      ),
                    ),
                  ),
                ),

            ],
          ),
        ),
      ),

      drawer: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30.0),
          bottomRight: Radius.circular(30.0),
        ),
        child: Drawer(
          child:Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 50.0, left: 15.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PersonalInformation(
                              loginUserId: userData['userId'])),
                    );
                  },
                  child: Column(
                    children: [
                      // Padding(
                      //   padding: const EdgeInsets.only(left: 8.0),
                      //   child: Image.asset(
                      //     'assets/dms-logo.png',
                      //     width: 40,
                      //     height: 40,
                      //   ),
                      // ),
                      // const Padding(
                      //   padding: EdgeInsets.only(),
                      //   child: Text(
                      //     'STREAM MAIL',
                      //     style: TextStyle(
                      //         color: Colors.black,
                      //         fontSize: 20,
                      //         fontWeight: FontWeight.w400,
                      //         fontFamily: 'AvenirNextCyr-Bold'),
                      //   ),
                      // ),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // border: Border.all(
                            //   color: Colors.grey, // Border color
                            //   width: 0.5, // Border width
                            // ),
                          ),
                          child: CircleAvatar(
                            radius: 28.0,
                            backgroundImage: userData['userProfile'] == null ||
                                userData['userProfile'] == '' ||
                                userData['userProfile'] == 'NA'
                                ? null // No image if the condition is true
                                : NetworkImage(
                                "https://yrglobaldocuments.blob.core.windows.net/userprofileimages/" +
                                    userData['userProfile']),
                            child: userData['userProfile'] == null ||
                                userData['userProfile'] == '' ||
                                userData['userProfile'] == 'NA'
                                ? Icon(Icons
                                .person) // Show person icon if condition is true
                                : null, // No icon if there's an image
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${userData['firstName']} ${userData['lastName']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18.0,
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Visibility(
                          visible: userData['designationName'] != null &&
                              userData['designationName'] != "N/A" &&
                              userData['designationName'] != "NA" &&
                              userData['designationName']?.isNotEmpty == true,
                          child: Text(
                            userData['designationName'] ?? '',
                            style:
                            TextStyle(fontSize: 18.0, color: Colors.grey),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                height: 10,
                thickness: 0.2,
                indent: 10,
                endIndent: 10,
                color: Colors.black,
              ),
              Expanded(
                child:  ListView.builder(
                itemCount: cabinets.length,
                itemBuilder: (context, index) {
                  final cabinet = cabinets[index];
                  return ListTile(
                    title: Text(cabinet.cabinetName ?? 'No Name'),
                    leading: SvgPicture.asset(
                      'assets/svg_icons/cabinate_icon.svg',
                      width: 20,
                      height: 20,
                      // You can also specify color here if needed
                      color: Colors.grey,
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cabinet.archiveCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    onTap: () {
                      setState(() {
                        cabinetId = cabinet.cabinetId!;
                        totalDocCount = cabinet.archiveCount ?? 0;
                        _selectedIndex = 0; // Switch to the Archive tab
                        _isLoading = true; // Set loading state
                      });
                      fetchDocuments(isRefresh: true, cabinetId: cabinetId);
                      Navigator.pop(context); // Close the drawer after selection
                    },
                  );
                },
              ),
              ),
              const Divider(
                thickness: 0.2,
                color: Colors.black,
                indent: 10,
                endIndent: 10,
              ),
             Expanded(
             child: labels.isEmpty
                 ? SizedBox.shrink()
            : ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: labels.length,
        itemBuilder: (context, index) {
          final label = labels[index];
          return ListTile(
            minLeadingWidth: 0,
            horizontalTitleGap: 0,
            visualDensity:
            VisualDensity(horizontal: 0, vertical: -4),
            dense: true,
            contentPadding: EdgeInsets.symmetric(
                vertical: 0.0, horizontal: 20.0),
            title: Text(label.labelName,
                style: TextStyle(fontSize: 13.0)),
            onTap: () async {
              print('click');
              print(label.labelId);
             await fetchLabelArchives(label.labelId);
              Navigator.pop(
                  context); // Close the drawer after selection
            },
          );
        },
      ),
             )

            ],
          )
        ),
      ),

      body: _getWidgetOptions()
          .elementAt(_selectedIndex), // Display the selected widget
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // Ensure labels are always visible
        items: <BottomNavigationBarItem>[
          // BottomNavigationBarItem(
          //   icon: InkWell(
          //     onTap: () => _onItemTapped(0), // Call function when tapped
          //     child: SvgPicture.asset(
          //       'assets/svg_icons/archive_inbox_icon.svg',
          //       color: _selectedIndex == 0 ? Colors.amber[800] : Colors.grey,
          //     ),
          //   ),
          //   label: 'Archive',
          //   tooltip: 'Archive',
          // ),
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () => _onItemTapped(0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    'assets/svg_icons/archive_inbox_icon.svg',
                    color: _selectedIndex == 0 ? Colors.amber[800] : Colors.grey,
                  ),
                  if (totalDocCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$totalDocCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            label: 'Archive',
            tooltip: 'Archive',
          ),

          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () => _onItemTapped(1),
              child: SvgPicture.asset(
                'assets/svg_icons/archive_favorite_icon.svg',
                color: _selectedIndex == 1 ? Colors.amber[800] : Colors.grey,
              ),
            ),
            label: 'Favorite',
            tooltip: 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () => _onItemTapped(2),
              child: SvgPicture.asset(
                'assets/svg_icons/archive_trash_icon.svg',
                color: _selectedIndex == 2 ? Colors.amber[800] : Colors.grey,
              ),
            ),
            label: 'Trash',
            tooltip: 'Trash',
          ),
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () => _onItemTapped(3),
              child: SvgPicture.asset(
                'assets/svg_icons/share_by_me_archive_icon.svg',
                color: _selectedIndex == 3 ? Colors.amber[800] : Colors.grey,
              ),
            ),
            label: 'Share',
            tooltip: 'Share',
          ),
          // BottomNavigationBarItem(
          //   icon: InkWell(
          //     onTap: () => _onItemTapped(4),
          //     child: SvgPicture.asset(
          //       'assets/svg_icons/archive_shared_expired_icon.svg',
          //       color: _selectedIndex == 4 ? Colors.amber[800] : Colors.grey,
          //     ),
          //   ),
          //   label: 'Expired',
          //   tooltip: 'Shared Expired',
          // ),
        ],
        currentIndex: _selectedIndex,
        // Current selected index
        selectedItemColor: Colors.amber[800],
        // Color of the selected item
        onTap: _onItemTapped, // Callback when an item is tapped
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     _openFilePicker();
      //   },
      //   child: Icon(Icons.add, color: Colors.white),
      //   backgroundColor: Colors.deepOrange,
      // ),
      floatingActionButton: cabinetId != 0
          ? FloatingActionButton(
        onPressed: () {
          _openFilePicker();
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.deepOrange,
      )
          : null,

    );
  }

//Load user data from here
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
  //Api call function here
  Future<void> fetchDocuments(   {required int cabinetId ,bool isRefresh = false}) async {
    if (isLoading) return; // Prevent multiple fetch calls at the same time

    print('Fetching documents...');

    setState(() {
      isLoading = true;
    });

    // If it's a refresh, reset the page number to 1
    if (isRefresh) {
      currentPage = 1;
    }

    final url = Uri.parse(

        "${ApiUrls.baseUrl}ArchiveAPI/ArchiveDocumentList"

    );
    final Map<String, dynamic> body = {
      "subcatid": "",
      "DocumentTypeIds": "",
      "DocumentSearchText": "",
      "SourceIds": "",
      "DMIds": "",
      "PageSize": 20,
      "PageNumber": currentPage,
      "OrganizationId": userData['organizationid'],
      "CreatedBy": userData['userId'],
      "StartDate": "",
      "EndDate": "",
      "DocumentStatus": "",
      "IsAll": true,
      "CabinetId" : cabinetId,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData["Status"] == true && responseData["Data"] != null) {
          final List<dynamic> jsonList =
              responseData["Data"]["ArchiveJson"] ?? [];

          final List<dynamic> jsonPinList =
              responseData["Data"]["PinJson"] ?? [];

          final int totalCount =
              responseData["Data"]["TotalRecordsJSON"] ?? 0;
          print("totalCount " + totalCount.toString());

          setState(() {
            if (isRefresh) {
              // If it's a refresh, clear the existing list
              documents = jsonList
                  .map((json) => ArchiveDocument.fromJson(json))
                  .toList();
              pinDocuments = jsonPinList
                  .map((json) => ArchivePinDocument.fromJson(json))
                  .toList();

              totalDocCount = totalCount;
            } else {
              // If it's loading more, append to the existing list
              documents.addAll(jsonList
                  .map((json) => ArchiveDocument.fromJson(json))
                  .toList());
            }
          });

          print("Documents loaded: ${documents.length}");
          print("Total count :  ${totalCount.toString()}");
          // Increment the page number for next load more call
          if (!isRefresh) {
            currentPage++;
          }

          // If no documents were fetched, you can stop loading more
          if (jsonList.isEmpty) {
            _refreshControllerForMainArchiveList.loadNoData();
          } else {
            _refreshControllerForMainArchiveList.loadComplete();
          }
        } else {
          print("No documents found.");
          _refreshControllerForMainArchiveList.loadComplete();
        }
      } else {
        print("Failed to fetch documents. Status code: ${response.statusCode}");
        _refreshControllerForMainArchiveList.loadComplete();
      }
    } catch (e) {
      print("Error fetching documents: $e");
      _refreshControllerForMainArchiveList.loadComplete();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future<void> fetchFavoriteDocuments() async {
  //   final url = Uri.parse(
  //       '${ApiUrls.baseUrl}Gac/ArchiveFavoriteList_V2');
  //   final headers = {"Content-Type": "application/json"};
  //   final body = jsonEncode({
  //     "CreatedBy": userData['userId'],
  //     "Organizationid": userData['organizationid'],
  //   });
  //
  //   try {
  //     final response = await http.post(url, headers: headers, body: body);
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data["Status"] == true) {
  //         List<dynamic> jsonList = data["Data"]["FavoriteJson"];
  //         setState(() {
  //           favoriteDocuments = jsonList
  //               .map((json) => FavoriteDocument.fromJson(json))
  //               .toList();
  //           isLoading = false;
  //         });
  //       } else {
  //         showError("No data available");
  //       }
  //     } else {
  //       showError("Failed to load data");
  //     }
  //   } catch (e) {
  //     showError("Error: $e");
  //   }
  // }
  Future<void> fetchFavoriteDocuments({String query = ''}) async {
   // print("Fetching favorites with search query: '$query' and reverseOrder: $reverseOrder");

    final url = Uri.parse('${ApiUrls.baseUrl}Gac/ArchiveFavoriteList_V2');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "CreatedBy": userData['userId'],
      "Organizationid": userData['organizationid'],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["Status"] == true) {
          List<dynamic> jsonList = data["Data"]["FavoriteJson"];

          List<FavoriteDocument> documents = jsonList
              .map((json) => FavoriteDocument.fromJson(json))
              .toList();

          // Apply search filter if query is provided
          if (query.isNotEmpty) {
            final searchLower = query.toLowerCase();
            documents = documents.where((doc) {
              final title = doc.documentName?.toLowerCase() ?? '';
              final desc = doc.description?.toLowerCase() ?? '';
              return title.contains(searchLower) || desc.contains(searchLower);
            }).toList();
          }

          // Reverse if needed
          // if (reverseOrder) {
          //   documents = documents.reversed.toList();
          // }

          setState(() {
            favoriteDocuments = documents;
            isLoading = false;
          });
        } else {
          showError("No data available");
        }
      } else {
        showError("Failed to load data");
      }
    } catch (e) {
      showError("Error: $e");
    }
  }

  void showError(String message) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> fetchTrashList() async {
    final url = Uri.parse(
        // '${ApiUrls.baseUrl}Gac/ArchiveTrashList_V2'
    'https://cswebapps.com/dmscoretestapi/api/Gac/ArchiveTrashList_V2'
    );
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "CreatedBy": userData['userId'],
      "Organizationid": userData['organizationid'],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        if (data["Status"] == true) {
          List<dynamic> jsonList = data["Data"]["TrashJson"];
          setState(() {
            trashItems =
                jsonList.map((json) => TrashItem.fromJson(json)).toList();
            isLoading = false;
          });
        } else {
          showError("No data available");
        }
      } else {
        showError("Failed to load data");
      }
    } catch (e) {
      showError("Error: $e");
    }
  }

  // Future<void> fetchShareWithMeList() async {
  //   final url = Uri.parse(
  //       '${ApiUrls.baseUrl}ArchiveAPI/ArchiveShareWithMeList');
  //   final headers = {"Content-Type": "application/json"};
  //   final body = jsonEncode({
  //     "CreatedBy": 44,
  //     "Organizationid": userData['organizationid'],
  //   });
  //
  //   try {
  //     final response = await http.post(url, headers: headers, body: body);
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       print(data);
  //       if (data["Status"] == true) {
  //         List<dynamic> jsonList = data["Data"]["ArchiveJson"];
  //         setState(() {
  //           shareWithMeList = jsonList
  //               .map((json) => ArchiveDocumentShareWithMe.fromJson(json))
  //               .toList();
  //           isLoading = false;
  //         });
  //       } else {
  //         showError("No data available");
  //       }
  //     } else {
  //       showError("Failed to load data");
  //     }
  //   } catch (e) {
  //     showError("Error: $e");
  //   }
  // }
  Future<void> fetchShareWithMeList({String query = ''}) async {
    final url = Uri.parse('${ApiUrls.baseUrl}ArchiveAPI/ArchiveShareWithMeList');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "CreatedBy": userData['userId'], // Consider using: userData['userId'] for consistency
      "Organizationid": userData['organizationid'],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);

        if (data["Status"] == true) {
          List<dynamic> jsonList = data["Data"]["ArchiveJson"];
          List<ArchiveDocumentShareWithMe> docs = jsonList
              .map((json) => ArchiveDocumentShareWithMe.fromJson(json))
              .toList();

          // Local search filter
          if (query.isNotEmpty) {
            final lowerQuery = query.toLowerCase();
            docs = docs.where((doc) {
              final title = doc.documentName?.toLowerCase() ?? '';
              final desc = doc.description?.toLowerCase() ?? '';
              return title.contains(lowerQuery) || desc.contains(lowerQuery);
            }).toList();
          }

          // Optional reverse


          setState(() {
            shareWithMeList = docs;
            isLoading = false;
          });
        } else {
          showError("No data available");
        }
      } else {
        showError("Failed to load data");
      }
    } catch (e) {
      showError("Error: $e");
    }
  }

  // Future<void> fetchShareByMeList() async {
  //   final url = Uri.parse(
  //       '${ApiUrls.baseUrl}ArchiveAPI/ArchiveShareByMeList');
  //   final headers = {"Content-Type": "application/json"};
  //   final body = jsonEncode({
  //     "CreatedBy": 44,
  //     "Organizationid": userData['organizationid'],
  //   });
  //
  //   try {
  //     final response = await http.post(url, headers: headers, body: body);
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       print(data);
  //       if (data["Status"] == true) {
  //         List<dynamic> jsonList = data["Data"]["ArchiveJson"];
  //         setState(() {
  //           shareByMeList = jsonList
  //               .map((json) => ArchiveDocumentShareByMe.fromJson(json))
  //               .toList();
  //           isLoading = false;
  //         });
  //       } else {
  //         showError("No data available");
  //       }
  //     } else {
  //       showError("Failed to load data");
  //     }
  //   } catch (e) {
  //     showError("Error: $e");
  //   }
  // }

  Future<void> fetchShareByMeList({String query = ''}) async {
    final url = Uri.parse('${ApiUrls.baseUrl}ArchiveAPI/ArchiveShareByMeList');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "CreatedBy": userData['userId'], // You can replace 44 with: userData['userId']
      "Organizationid": userData['organizationid'],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);

        if (data["Status"] == true) {
          List<dynamic> jsonList = data["Data"]["ArchiveJson"];
          List<ArchiveDocumentShareByMe> docs = jsonList
              .map((json) => ArchiveDocumentShareByMe.fromJson(json))
              .toList();

          // Local search filtering
          if (query.isNotEmpty) {
            final lowerQuery = query.toLowerCase();
            docs = docs.where((doc) {
              final title = doc.documentName?.toLowerCase() ?? '';
              final desc = doc.description?.toLowerCase() ?? '';
              return title.contains(lowerQuery) || desc.contains(lowerQuery);
            }).toList();
          }

          // Optional reverse


          setState(() {
            shareByMeList = docs;
            isLoading = false;
          });
        } else {
          showError("No data available");
        }
      } else {
        showError("Failed to load data");
      }
    } catch (e) {
      showError("Error: $e");
    }
  }

  //Click on label and get list of document
  Future<void> fetchLabelArchives(int labelId) async {
    final url = Uri.parse(
        'https://cswebapps.com/dmsapitest/api/LabelsAPI/GetLabelArchives_V2');

    final body = jsonEncode({
      "LabelId": labelId,
      "CreatedBy": userData['userId'],
      "Organizationid": userData['organizationid']
    });

    final headers = {
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(url, body: body, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
print(responseData);
        if (responseData["Status"] == true && responseData["Data"] != null) {
          final List<dynamic> jsonList =
              responseData["Data"]["LabelsArchiveJson"] ?? [];
          setState(() {
            documents = jsonList
                .map((json) => ArchiveDocument.fromJson(json))
                .toList();
          });
        } else {
          print('API call unsuccessful or Data is null');
        }
      } else {
        print('Failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  //////////////call delete api function

  Future<void> archiveTrash(int shareId, int documentId) async {
    final url = Uri.parse(
        '${ApiUrls.baseUrl}Gac/ArchiveTrash_V2');

    // JSON data to be sent in the request body
    final Map<String, dynamic> data = {
      "trashjson": jsonEncode([
        {"ShareId": shareId, "DocumentId": documentId, "IsTrash": true}
      ])
    };

    // Set the headers
    final headers = {
      "Content-Type": "application/json",
    };

    try {
      // Send the POST request
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      // Check the response status code
      if (response.statusCode == 200) {
        // Request was successful
        print('Success: ${response.body}');
      } else {
        // Handle different status codes appropriately
        print('Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      // Handle any exceptions that occur during the request
      print('Exception: $e');
    }
  }

  ////////////////call favorite api function

  Future<void> archiveFavorite(int documentId, int shareId,
      bool isFavorite) async {
    print('calling favorite');
    print(documentId);
    print(shareId);
    print(isFavorite);
    final url = Uri.parse(
        '${ApiUrls.baseUrl}Gac/ArchiveFavorite_V2');
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'DocumentId': documentId,
      'ShareId': shareId,
      'isFavorite': isFavorite,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {

        print("here resultant print " +  isFavorite.toString());
        // Handle success
        print('Request successful');
      } else {
        // Handle error
        print('Request failed with status code ${response.statusCode}');
      }
    } catch (e) {
      // Handle exception
      print('Error: $e');
    }
  }

  // Future<void> _openFilePicker() async {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Wrap(
  //         children: [
  //           SingleChildScrollView(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 ElevatedButton(
  //                   onPressed: _pickAndProcessFile,
  //                   child: const Text('Pick a File (Image, PDF, or Text)'),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 if (_selectedFile != null) ...[
  //                   Text('Selected File: ${_selectedFile!.path.split('/').last}'),
  //                   const SizedBox(height: 10),
  //                   Text('File Type: $_fileType'),
  //                   const SizedBox(height: 20),
  //                   // _fileType == 'Image'
  //                   //     ? Image.file(_selectedFile!, height: 200)
  //                   //     : Container(),
  //                 ] else
  //                   const Text('No file selected.'),
  //                 const SizedBox(height: 20),
  //                 const Text('Extracted Text:', style: TextStyle(fontSize: 18)),
  //                 const SizedBox(height: 10),
  //                 Text(_extractedText.isEmpty ? 'No text extracted yet.' : _extractedText),
  //               ],
  //             ),
  //           ),
  //           Divider(),
  //           ListTile(
  //             leading: Icon(LineAwesomeIcons.camera_solid),
  //             title: Text('Take form camera'),
  //             onTap: () async {
  //               Navigator.pop(context);
  //               await _pickFromCamera();
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(LineAwesomeIcons.mobile_alt_solid),
  //             title: Text('Select from device'),
  //             onTap: () async {
  //               Navigator.pop(context);
  //               await _pickFromDevice();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  //   // setState(() {
  //   //   _selectedFile = null;
  //   //   _extractedText = '';
  //   //   _fileType = '';
  //   // });
  // }
  Future<void> _openFilePicker() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to expand dynamically
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.document_scanner),
                    title: const Text('Choose file for Ocr'),
                    onTap: () async {
                      await _pickAndProcessFile(setModalState);
                    },
                  ),
                  // const SizedBox(height: 20),

                  // if (_selectedFile != null) ...[
                  //   Text('Selected File: ${_selectedFile!.path.split('/').last}'),
                  //   const SizedBox(height: 10),
                  //   Text('File Type: $_fileType'),
                  //   const SizedBox(height: 20),
                  // ] else
                  //   const Text('No file selected.'),

                  // const SizedBox(height: 20),
                  // const Text('Extracted Text:', style: TextStyle(fontSize: 18)),
                  // const SizedBox(height: 10),
                  Container(
                    constraints: _extractedText.isNotEmpty
                        ? const BoxConstraints(maxHeight: 200)
                        : null, // No constraint when empty
                    width: double.infinity, // Adjust width if needed
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          _extractedText.isEmpty ? '' : _extractedText,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),



                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Take from Camera'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFromCamera();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.perm_device_information_sharp),
                    title: const Text('Select from Device'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFromDevice();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() {
      _extractedText = '';
      _selectedFile = null;
    });
  }


  // Future<void> _pickFromDevice() async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
  //
  //   if (result != null) {
  //     setState(() {
  //       _selectedFiles.addAll(
  //           result.paths.whereType<String>().map((path) => XFile(path)) // Convert to XFile
  //       );
  //       _fileUploadStatuses.addAll(List<String>.filled(result.files.length, 'cancel'));
  //     });
  //
  //     await _uploadFile(File(file.path)); // Convert to File when needed
  //   }
  //
  // }
  Future<void> _pickFromDevice() async {
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      List<XFile> selectedXFiles =
      result.paths.whereType<String>().map((path) => XFile(path)).toList();
      List<String> statuses =
      List<String>.filled(selectedXFiles.length, 'cancel');

      setState(() {
        _selectedFiles.addAll(selectedXFiles);
        _fileUploadStatuses.addAll(statuses);
      });

      // Upload each file correctly
      for (XFile xfile in selectedXFiles) {
        await _uploadFile(File(xfile.path)); // Convert XFile to File
      }
    }
  }

  Future<void> _pickFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera);

    if (file != null) {
      setState(() {
        print(file.name);
        _selectedFiles.add(file); // Storing XFile directly
        print(_selectedFiles);
        _fileUploadStatuses.add('cancel');
      });

      await _uploadFile(File(file.path)); // Convert to File when needed
    }
  }

  // Future<void> _checkPermissionsAndOpenCamera() async {
  //   var status = await Permission.camera.status;
  //   if (!status.isGranted) {
  //     await Permission.camera.request();
  //   }
  //
  //   if (await Permission.camera.isGranted) {
  //     _pickFromCamera();
  //   } else {
  //     print("Camera permission denied");
  //   }
  // }

  // Future<void> _uploadFile(File file) async {
  //   print("\n🚀 Starting file upload...");
  //
  //   var url = '${ApiUrls.baseUrl}ArchiveAPI/NewDocument';
  //   var request = http.MultipartRequest('POST', Uri.parse(url));
  //
  //   try {
  //     print("\n📂 File Info:");
  //     print("  - Path: ${file.path}");
  //     print("  - Name: ${file.path.split('/').last}");
  //     print("  - File Exists: ${await file.exists()}");
  //     print("  - File Size: ${await file.length()} bytes");
  //
  //     // Prepare multipart file
  //     var multipartFile = await http.MultipartFile.fromPath(
  //       'file',  // Change 'Document' to 'file' or what the API expects
  //       file.path,
  //       contentType: MediaType('application', 'json'), // Adjust based on file type
  //     );
  //
  //     request.files.add(multipartFile);
  //     print("\n✅ File added to request.");
  //
  //     // Prepare request fields
  //     Map<String, String> requestFields = {
  //       "FlagId": "0",
  //       "DocumentName": file.path.split('/').last,
  //       "CreatedBy": "31",
  //       "extractedValuesJson": jsonEncode([
  //         {
  //           "FileName": file.path.split('/').last,
  //           "CloudName": "",
  //           "IsMain": true,
  //           "Url": file.uri.toString(),
  //           "ThumbnailUrl": "null"
  //         }
  //       ]),
  //       "ApprovalUserJson": "[]",
  //       "ShareUserJson": "[]",
  //       "ReportingUserID": "31",
  //       "IsArchiveApproval": "false",
  //       "WorkflowJson": "[]",
  //       "DocumentInfoJson": "[]",
  //       "VersionName": "1.0",
  //       "ParentId": "0",
  //     };
  //
  //     request.fields.addAll(requestFields);
  //     print("\n📝 Request Fields:");
  //     requestFields.forEach((key, value) {
  //       print("  - $key: $value");
  //     });
  //
  //     // Set request headers
  //     Map<String, String> requestHeaders = {
  //       "Accept": "application/json",
  //     };
  //     request.headers.addAll(requestHeaders);
  //     print("\n📜 Request Headers:");
  //     requestHeaders.forEach((key, value) {
  //       print("  - $key: $value");
  //     });
  //
  //     print("\n📤 Sending request...");
  //     var response = await request.send();
  //
  //     print("\n📥 Response received:");
  //     print("  - Status Code: ${response.statusCode}");
  //
  //     String responseBody = await response.stream.bytesToString();
  //     print("  - Response Body: $responseBody");
  //
  //     if (response.statusCode == 200) {
  //       print("\n✅ File uploaded successfully: ${file.path}");
  //     } else {
  //       print("\n❌ File upload failed.");
  //       print("  - Reason: ${response.reasonPhrase}");
  //       print("  - Full Response Body: $responseBody");
  //     }
  //   } catch (e, stacktrace) {
  //     print("\n🔥 Error uploading file: $e");
  //     print("🛑 Stack Trace:\n$stacktrace");
  //   }
  // }

  /// Fetch SAS token from backend
  Future<void> _getSasToken() async {
    print('calling token function');
    if (_sasToken.isEmpty ||
        DateTime
            .now()
            .millisecondsSinceEpoch > _expiryTime) {
      try {
        final response = await http.post(Uri.parse(
            '${ApiUrls.baseUrl}FileUploadAPI/NewGenerateSASToken'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _sasToken = data['sasToken'];
          _blobUrl = data['blobUrl'];
          _expiryTime =
              DateTime
                  .parse(data['expiryTime'])
                  .millisecondsSinceEpoch;

          print("SAS Token: $_sasToken");
          print("Blob URL: $_blobUrl");
          print("Expiry Time: $_expiryTime");
        } else {
          throw Exception("Failed to fetch SAS token");
        }
      } catch (e) {
        throw Exception("Error fetching SAS token: $e");
      }
    }
  }

  String _getMimeType(String path) {
    final extension = path
        .split('.')
        .last
        .toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  final String containerName = "documents";


  Future<dynamic> _uploadFile(File file) async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing
      builder: (BuildContext context) {
        return Center(
          child: LoadingAnimationWidget.inkDrop(
            color: Colors.deepOrange,
            size: 35,
          ),
        );
      },
    );
    print('Fetching SAS Token...');
    await _getSasToken();
    print('SAS Token fetched: $_sasToken');
    print('SAS bloburl fetched: $_blobUrl');

    bool fileUploadErrorLogs = false; // Declare error flag
    double uniqueId = DateTime
        .now()
        .millisecondsSinceEpoch + 1;
    for (XFile file in _selectedFiles) {
      // Check if file size is 0 KB
      int fileSizeInBytes = await file.length();
      double fileSizeInKB = fileSizeInBytes / 1024;
      if (fileSizeInKB == 0) {
        print('test file size');
        fileUploadErrorLogs = true; // Set error flag
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'The uploaded file is 0 KB. Please upload a larger file.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        continue; // Skip this file
      }

      // Check if file already exists in _selectedFiles
      String originalFileName = file.path
          .split('/')
          .last; // Extract file name
      // bool isExistFile = _selectedFiles.any((item) {
      //   return item.path.split('/').last == originalFileName;
      // });
      //
      // if (isExistFile) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('This file already exists in the selected files.'),
      //       backgroundColor: Colors.orange,
      //       duration: Duration(seconds: 3),
      //     ),
      //   );
      //   continue; // Skip this file without stopping the loop
      // }


      Map<String, dynamic> fileRecord = {
        "UniqueId": uniqueId,
        "FileName": file.path
            .split('/')
            .last, // Extract file name
        "Size": file.length(),
        "Files": file,
        "IsMain": false, // Default main file flag
        "Thumbnail": '', // Initialize with an empty string
        "Progress": 0, // Track upload progress
        "Uploading": true, // File is uploading
        "Url": null, // URL to store the uploaded file's location
        "CloudName": '',
        "ThumbnailUrl": ''
      };

      print(fileRecord);

      _GacAttachmentFileuplod.add(fileRecord);


      String folderPath = "Draft/${userData['userId']}";

      //////////File should be save on azure
      File convertedFile = File(file.path);
      String fileName = file.name;
      try {
        print('streamBox');


        print("folder Path ${folderPath}");
        print("Unique Id ${uniqueId}");
        print("$containerName/$folderPath/${uniqueId}_${file.path
            .split('/')
            .last}");
        print(_blobUrl);
        final String sasToken = _sasToken; // Use SAS for authentication
        final storage = AzureStorage.parse(
            "DefaultEndpointsProtocol=https;AccountName=yrglobaldocuments;AccountKey=BpcizQ8jUtvYwrmsp71yIrsfJMEoCqCf/n6Ayro/dS/Ak4WPxRXlXTc9LWN8dKw6Yv9c79IyUzO3tOx1sf3rbA==;EndpointSuffix=core.windows.net");
        //final storage = "https://yrglobaldocuments.blob.core.windows.net/documents/";
        print("folder path $folderPath");
        print('printing folder path');
        print("$containerName/$folderPath/${uniqueId}_${file.path
            .split('/')
            .last}");
        await storage.putBlob(
          '$containerName/$folderPath/${uniqueId}_${file.path
              .split('/')
              .last}', // Correct way to provide blob path
          bodyBytes: convertedFile.readAsBytesSync(),
          // Use `bodyBytes` instead of `body`
          contentType: "image/jpeg",
          // Set appropriate content type
          type: BlobType.blockBlob,
        );

        print("Uploaded: $fileName");
      }
      catch (e) {
        print("Error uploading $fileName: $e");
        _selectedFiles = [];  // ✅ Safe way to clear the list
        bodyBytes = Uint8List(0);  // ✅ Safe way to clear a Uint8List
      }


      ////////////////////////Generate thumbnail
      // String filePath = file.path.toLowerCase();
      //
      //
      //   String lowerCasePath = filePath.toLowerCase();
      //
      //           if (lowerCasePath.endsWith('.jpg') || lowerCasePath.endsWith('.jpeg') || lowerCasePath.endsWith('.png')) {
      //             var thumbnail = await generateImageThumbnail(file);
      //             print('Generated thumbnail: $thumbnail');
      //           }

      File? thumbnailFile;
      String fileType = path.extension(file.path)
          .toLowerCase(); // Output: ".jpg"
      // try {
      //
      //
      //   if (fileType == '.jpg' || fileType == '.jpeg' || fileType == '.png'){
      //     print('Generating file of thumbnail here....');
      //    File? imgThumbnail =  await generateImageThumbnail(file);
      //   }
      //   else if(fileType == '.pdf'){
      //      thumbnailNamepdf = await generateThumbnailPdf(file);
      //   }
      // } catch (e, stacktrace) {
      //   print("🔥 Error generating thumbnail: $e");
      //   print("🛑 Stack Trace:\n$stacktrace");
      //   thumbnailFile = null; // Ensure the variable is assigned even in case of failure
      // }
      if (fileType == '.jpg' || fileType == '.jpeg' || fileType == '.png') {
        print('Generating image thumbnail...');
        File? imgThumbnail = await generateImageThumbnail(file);

        if (imgThumbnail != null) {
          bodyBytes = imgThumbnail.readAsBytesSync();
        } else {
          print("❌ Failed to generate image thumbnail.");
        }
      } else if (fileType == '.pdf') {
        print('Generating PDF thumbnail...');
        File? pdfThumbnail = await generateThumbnailPdf(file);

        if (pdfThumbnail != null) {
          bodyBytes = pdfThumbnail.readAsBytesSync();
        } else {
          print("❌ Failed to generate PDF thumbnail.");
        }
      } else if (fileType == '.docx' || fileType == '.doc' || fileType == '.txt') {
        print('Generating DOCX thumbnail...');
        XFile? docxThumbnail = await convertDocxToPdf(file);
        File? pdfThumbnail = await generateThumbnailPdf(docxThumbnail!);
        if (pdfThumbnail != null) {
          bodyBytes = pdfThumbnail.readAsBytesSync();
        }
      }
      else if (fileType == '.xlsx' || fileType == '.xls') {
        File? xlThumbnail = await generateExcelThumbnail(file);
        print("this is excel thumbnail : $xlThumbnail");
        if (xlThumbnail != null) {
          bodyBytes = xlThumbnail.readAsBytesSync();
        }
      }
      else if(fileType == '.pptx'){
        File pptThumbnail = await generatePptxThumbnail(file);
        if(pptThumbnail != null){
          bodyBytes = pptThumbnail.readAsBytesSync();
        }

      }
      else{
        ByteData assetImage = await rootBundle.load('assets/defaultThumbnail.png');
        bodyBytes = assetImage.buffer.asUint8List();
      }


      // File? thumbnailFile = await generateThumbnail(file);

      // final String fileName = file.uri.pathSegments.last; // Extract only filename
      thumbnailName = 'thumbnails/$uniqueId\_pdf_thumb_${file.path
          .split('/')
          .last}.png';
      // if (fileType == '.pdf') {
      //   thumbnailName = 'thumbnails/$uniqueId\_pdf_thumb_$globalThumbnailName';
      // } else {
      //   thumbnailName = 'thumbnails/$uniqueId\_thumb_$thumbnailNamepdf';
      // }
      // String  = 'thumbnails/$uniqueId\_thumb\_${file.path}.png';
      String thumbnailUrl = '$_blobUrl/$thumbnailName';
      print("Archive thumbnil : ${thumbnailName}");
      print("Archive thumbnail url : ${thumbnailUrl}");
      final azureStorage = AzureStorage.parse(
          "DefaultEndpointsProtocol=https;AccountName=yrglobaldocuments;AccountKey=BpcizQ8jUtvYwrmsp71yIrsfJMEoCqCf/n6Ayro/dS/Ak4WPxRXlXTc9LWN8dKw6Yv9c79IyUzO3tOx1sf3rbA==;EndpointSuffix=core.windows.net");
      await azureStorage.putBlob(
        '${containerName}/$thumbnailName',
        bodyBytes: bodyBytes,
        contentType: 'image/png', // Setting content type
        type: BlobType.blockBlob,
      );
      print('Here exact thumbnail name : ${thumbnailName}');

      print("Here correct thumbnail url : ${thumbnailUrl}");


      print("\n🚀 Starting file upload...");

      var url = '${ApiUrls.baseUrl}ArchiveAPI/NewDocument';


      try {
        print("\n📂 File Info:");
        print("  - Path: ${file.path}");
        print("  - Name: ${file.path
            .split('/')
            .last}");
        print("  - File Size: ${await file.length()} bytes");

        // Determine MIME type
        String? mimeType = lookupMimeType(file.path) ??
            'application/octet-stream';
        print("  - Detected MIME Type: $mimeType");

        // Read file bytes and encode to Base64
        List<int> fileBytes = await file.readAsBytes();
        String base64File = base64Encode(fileBytes);

        // Prepare JSON payload
        Map<String, dynamic> requestBody = {

          "documentId" :0,
          "message":"",
          "CabinetId" :cabinetId,
          "FlagId": 0,
          "DocumentName": file.path
              .split('/')
              .last,
          "CreatedBy": userData['userId'],
          "FileName": file.path
              .split('/')
              .last,
          "obj": "someValue", // 🔥 REQUIRED FIELD (Replace with correct value)
          "copyFiles": jsonEncode({ // Convert to a String
            "sourcePaths": [
              "https://yrglobaldocuments.blob.core.windows.net/documents/$folderPath/$originalFileName"
            ],
            "destinationContainer": "documents",
            "destinationFolder": "Archive/"
          }),
          "deletedJson": jsonEncode([
            {
              "fullPath": "https://yrglobaldocuments.blob.core.windows.net/documents/$folderPath/$originalFileName"
            }
          ]),
          "extractedValuesJson": jsonEncode([
            {
              "FileName": file.path
                  .split('/')
                  .last,
              "CloudName": "${uniqueId}_${file.path
                  .split('/')
                  .last}",
              "IsMain": true,
              "Url": "https://yrglobaldocuments.blob.core.windows.net/documents/$folderPath/${uniqueId}_${originalFileName}",
              "ThumbnailUrl": "$thumbnailName",
            }
          ]),
          "ApprovalUserJson": "[]", // 🔥 Ensure this is a plain string
          "ShareUserJson": "{}", // 🔥 Ensure this is a plain string
          "ReportingUserID": 31,
          "IsArchiveApproval": false, // 🔥 Ensure this is a proper boolean
          "WorkflowJson": "[]", // 🔥 Ensure this is a plain string
          "DocumentInfoJson": "{}", // 🔥 Ensure this is a plain string
          "VersionName": "1.0",
          "ParentId": 0
        };

        print("\n📤 Sending request...");
        print("  - Request URL: $url");
        print("  - Request Body: ${jsonEncode(requestBody)}");

        // Send HTTP POST request
        var response = await http.post(
          Uri.parse(url),
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
          body: jsonEncode(requestBody),
        );

        print("\n📥 Response received:");
        print("  - Status Code: ${response.statusCode}");
        print("  - Response Body: ${response.body}");

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${fileName} uploaded successfully!'),
              duration: Duration(milliseconds: 500), // Show for 0.5 seconds
              backgroundColor: Colors.deepOrange,
            ),
          );
          // _selectedFiles.clear();
          await fetchDocuments(isRefresh: true, cabinetId: cabinetId);


          print("\n✅ File uploaded successfully.");
        } else {
          print("\n❌ File upload failed.");
          print("  - Reason: ${response.body}");
        }
      } catch (e, stacktrace) {
        print("\n🔥 Error uploading file: $e");
        print("🛑 Stack Trace:\n$stacktrace");
        _selectedFiles = [];  // ✅ Safe way to clear the list
        bodyBytes = Uint8List(0);  // ✅ Safe way to clear a Uint8List
      }
    }

    _selectedFiles = [];  // ✅ Safe way to clear the list
    bodyBytes = Uint8List(0);  // ✅ Safe way to clear a Uint8List



    Navigator.of(context).pop();
  }

  // Future<dynamic> generateThumbnail(XFile file) async {
  //   try {
  //     String fileType = (file.path).toLowerCase();
  //
  //     // if (fileType == '.jpg' || fileType == '.jpeg' || fileType == '.png') {
  //     //   print('Generate img thumbnail');
  //     //   return
  //         await generateImageThumbnail(file);
  //     // }
  //     // else if (fileType == '.pdf') {
  //     //   return await generatePdfThumbnail(file);
  //     // } else if (fileType == '.docx') {
  //     //   return await generateDocxThumbnail(file);
  //     // } else if (fileType == '.xlsx') {
  //     //   return await generateExcelThumbnail(file);
  //     // } else if (fileType == '.pptx') {
  //     //   return await generatePlaceholderThumbnail('PPTX');
  //     // } else if (fileType == '.txt') {
  //     //   return await generatePlaceholderThumbnail('TXT');
  //     // } else if (fileType == '.html') {
  //     //   return await generatePlaceholderThumbnail('HTML');
  //     // } else {
  //     //   return await generateContentTypeThumbnail(fileType);
  //     // }
  //   } catch (e) {
  //     print('Error generating thumbnail: $e');
  //     return null;
  //   }
  // }


  Future<File?> generateImageThumbnail(XFile xFile) async {
    try {
      Uint8List imageBytes = await xFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      // ✅ Resize image to max 100px (keeping aspect ratio)
      const int maxSize = 100;
      int width = image.width;
      int height = image.height;

      if (width > height) {
        if (width > maxSize) {
          height = (height * maxSize) ~/ width;
          width = maxSize;
        }
      } else {
        if (height > maxSize) {
          width = (width * maxSize) ~/ height;
          height = maxSize;
        }
      }

      img.Image resizedImage = img.copyResize(
          image, width: width, height: height);
      Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resizedImage));

      // ✅ Save thumbnail as a file
      final tempDir = await getTemporaryDirectory();
      String thumbnailPath = '${tempDir.path}/thumbnail_${DateTime
          .now()
          .millisecondsSinceEpoch}.png';
      File thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(resizedBytes);

      print("📂 Thumbnail Path: $thumbnailPath");

      // ✅ Return the thumbnail file
      return thumbnailFile;
    } catch (e) {
      print("❌ Error generating thumbnail: $e");
      return null;
    }
  }


  Future<File?> generateThumbnailPdf(XFile xFile) async {
    try {
      // ✅ Read PDF bytes
      Uint8List pdfBytes = await xFile.readAsBytes();

      // ✅ Save temporary PDF file
      final tempDir = await getTemporaryDirectory();
      String tempPdfPath = '${tempDir.path}/temp_${DateTime
          .now()
          .millisecondsSinceEpoch}.pdf';
      File tempPdfFile = File(tempPdfPath);
      await tempPdfFile.writeAsBytes(pdfBytes);

      // ✅ Open PDF document & render first page
      final pdfx.PdfDocument document = await pdfx.PdfDocument.openFile(
          tempPdfPath);
      final pdfx.PdfPage page = await document.getPage(1);
      final pdfx.PdfPageImage? image = await page.render(
        width: (page.width / 4).toDouble(),
        height: (page.height / 4).toDouble(),
        format: pdfx.PdfPageImageFormat.png,
      );

      if (image == null) throw Exception('Failed to render PDF page');

      // ✅ Save thumbnail as a file
      String thumbnailPath = '${tempDir.path}/thumbnail_${DateTime
          .now()
          .millisecondsSinceEpoch}.png';
      File thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(image.bytes);

      print("📂 PDF Thumbnail Path: $thumbnailPath");

      // ✅ Close resources
      await page.close();
      await document.close();

      // ✅ Return thumbnail file (can be used for uploading)
      return thumbnailFile;
    } catch (e, stacktrace) {
      print("❌ Error generating PDF thumbnail: $e");
      print("🛑 Stack Trace:\n$stacktrace");
      return null; // Return null if an error occurs
    }
  }


  Future<XFile?> convertDocxToPdf(XFile docxFile) async {
    try {
      // Read the DOCX file as bytes
      final Uint8List docxBytes = await docxFile.readAsBytes();

      // Convert bytes to String (Basic Extraction)
      final String extractedText = String.fromCharCodes(docxBytes);

      // Create a PDF Document
      final pw.Document pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) =>
              pw.Center(
                child: pw.Text(
                    extractedText, style: pw.TextStyle(fontSize: 14)),
              ),
        ),
      );

      // Get directory
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/converted.pdf';
      final File pdfFile = File(outputPath);

      // Save the document
      final List<int> bytes = await pdf.save();
      await pdfFile.writeAsBytes(bytes);

      // Return as XFile
      return XFile(pdfFile.path);
    } catch (e) {
      print('Error converting DOCX to PDF: $e');
      return null;
    }
  }


  // Future<XFile?> convertExcelToPdf(File xlsxFile) async {
  //   try {
  //     // Load Excel file as bytes
  //     List<int> bytes = await xlsxFile.readAsBytes();
  //
  //     // Create a workbook
  //     final xls.Workbook workbook = xls.Workbook();
  //     final xls.Worksheet sheet = workbook.worksheets[0];
  //
  //     // Load some data (for testing purposes)
  //     sheet.getRangeByIndex(1, 1).setText("Converted from Excel!");
  //
  //     // Convert Excel to PDF
  //     // final PdfDocument pdfDocument = PdfDocument();
  //     final pw.Document pdfDocument = pw.Document();
  //     final PdfGrid pdfGrid = PdfGrid();
  //     pdfGrid.columns.add(count: 3); // Define columns
  //     final PdfGridRow row = pdfGrid.rows.add();
  //     row.cells[0].value = 'Column 1';
  //     row.cells[1].value = 'Column 2';
  //     row.cells[2].value = 'Column 3';
  //
  //     pdfGrid.draw(
  //         page: pdfDocument._pages.add(), bounds: const Rect.fromLTWH(0, 0, 500, 500));
  //
  //     // Save the PDF file
  //     final List<int> pdfBytes = pdfDocument.save();
  //     pdfDocument.dispose();
  //
  //     // Get the app directory
  //     final directory = await getTemporaryDirectory(); // Use temp directory
  //     final String pdfPath = '${directory.path}/${basenameWithoutExtension(xlsxFile.path)}.pdf';
  //     final File pdfFile = File(pdfPath);
  //     await pdfFile.writeAsBytes(pdfBytes);
  //
  //     print("PDF saved at $pdfPath");
  //
  //     // Return the PDF as XFile
  //     return XFile(pdfFile.path);
  //   } catch (e) {
  //     print("Error: $e");
  //     return null;
  //   }
  // }

  // Future<XFile?> convertExcelToPdf(File xlsxFile) async {
  //   try {
  //     // Create a PDF document
  //     final pdfDocument = pw.Document();
  //
  //     // Add a page to the PDF
  //     pdfDocument.addPage(
  //       pw.Page(
  //         build: (pw.Context context) {
  //           return pw.Center(
  //             child: pw.Text("Converted from Excel!"),
  //           );
  //         },
  //       ),
  //     );
  //
  //     // Save the PDF document
  //     final List<int> pdfBytes = await pdfDocument.save();
  //
  //     // Get the temporary directory
  //     final directory = await getTemporaryDirectory();
  //     final String pdfPath = '${directory.path}/${basenameWithoutExtension(xlsxFile.path)}.pdf';
  //     final File pdfFile = File(pdfPath);
  //     await pdfFile.writeAsBytes(pdfBytes);
  //
  //     print("PDF saved at $pdfPath");
  //
  //     return XFile(pdfFile.path);
  //   } catch (e) {
  //     print("Error: $e");
  //     return null;
  //   }
  // }


  // Future<File> generateExcelThumbnail(XFile file) async {
  //   try {
  //     // Read the Excel file
  //     final Uint8List bytes = await file.readAsBytes();
  //     final excel = Excel.decodeBytes(bytes);
  //
  //     // Get the first sheet
  //     final Sheet? sheet = excel.tables[excel.tables.keys.first];
  //     if (sheet == null) throw Exception("No sheets found in Excel");
  //
  //     // Create an image canvas
  //     final double canvasWidth = 800; // Define your canvas width
  //     final double canvasHeight = 600; // Define your canvas height
  //     final ui.PictureRecorder recorder = ui.PictureRecorder();
  //     final ui.Canvas canvas = ui.Canvas(
  //         recorder, Rect.fromLTWH(0, 0, canvasWidth, canvasHeight ));
  //
  //     // Set text properties
  //     int startX = 10,
  //         startY = 20,
  //         rowHeight = 20,
  //         colWidth = 50;
  //     int maxRows = 5,
  //         maxCols = 5;
  //
  //     // Draw the first few rows & columns onto the image
  //     for (int rowIndex = 0; rowIndex < maxRows &&
  //         rowIndex < sheet.maxRows; rowIndex++) {
  //       for (int colIndex = 0; colIndex < maxCols &&
  //           colIndex < sheet.maxColumns; colIndex++) {
  //         var cell = sheet.cell(CellIndex.indexByColumnRow(
  //             columnIndex: colIndex, rowIndex: rowIndex));
  //         String text = cell.value?.toString() ?? "";
  //
  //         final double x = colIndex * 100; // Adjust x position as needed
  //         final double y = rowIndex * 50; // Adjust y position as needed
  //
  //         // Draw text
  //         final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
  //           ui.ParagraphStyle(textAlign: TextAlign.left),
  //         )
  //           ..pushStyle(ui.TextStyle(fontSize: 20))
  //           ..addText(text);
  //
  //         final ui.Paragraph paragraph = paragraphBuilder.build()
  //           ..layout(ui.ParagraphConstraints(width: canvasWidth - x));
  //
  //         canvas.drawParagraph(paragraph, Offset(x, y));
  //       }
  //     }
  //
  //     // Finalize the drawing and obtain the image
  //     final ui.Picture picture = recorder.endRecording();
  //     final ui.Image img = await picture.toImage(
  //         canvasWidth.toInt(), canvasHeight.toInt());
  //
  //     // Convert image to PNG
  //     final ByteData? pngBytes = await img.toByteData(
  //         format: ui.ImageByteFormat.png);
  //     final Uint8List pngData = pngBytes!.buffer.asUint8List();
  //
  //     // Save thumbnail locally
  //     final dir = await getTemporaryDirectory();
  //     final File outputFile = File('${dir.path}/excel_thumbnail.png');
  //     await outputFile.writeAsBytes(pngData);
  //
  //     return outputFile;
  //   } catch (e) {
  //     throw Exception("Error processing Excel file: $e");
  //   }
  // }
  // import 'dart:io';
  // import 'dart:typed_data';
  // import 'dart:ui' as ui;
  // import 'package:flutter/material.dart';
  // import 'package:path_provider/path_provider.dart';
  // import 'package:excel/excel.dart';
  // import 'package:image/image.dart' as img;

  Future<File> generateExcelThumbnail(XFile file) async {
    try {
      // Read the Excel file
      final Uint8List bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Get the first sheet
      final Sheet? sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) throw Exception("No sheets found in Excel");

      // Define Canvas Size
      final double canvasWidth = 800;
      final double canvasHeight = 600;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas =
      ui.Canvas(recorder, Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));

      // Fill background with white
      final Paint backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), backgroundPaint);

      // Text Paint
      final Paint textPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      // Grid Line Paint
      final Paint gridPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2;

      // Define table properties
      double startX = 20, startY = 50;
      double rowHeight = 60, colWidth = 150;
      int maxRows = 10, maxCols = 10;

      // Draw table grid
      for (int rowIndex = 0; rowIndex <= maxRows; rowIndex++) {
        double y = startY + rowIndex * rowHeight;
        canvas.drawLine(Offset(startX, y), Offset(startX + maxCols * colWidth, y), gridPaint);
      }
      for (int colIndex = 0; colIndex <= maxCols; colIndex++) {
        double x = startX + colIndex * colWidth;
        canvas.drawLine(Offset(x, startY), Offset(x, startY + maxRows * rowHeight), gridPaint);
      }

      // Draw table content
      for (int rowIndex = 0;
      rowIndex < maxRows && rowIndex < sheet.maxRows;
      rowIndex++) {
        for (int colIndex = 0;
        colIndex < maxCols && colIndex < sheet.maxColumns;
        colIndex++) {
          var cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: colIndex, rowIndex: rowIndex));
          String text = cell.value?.toString() ?? "";

          double x = startX + colIndex * colWidth + 10;
          double y = startY + rowIndex * rowHeight + 20;

          // Draw text using ParagraphBuilder
          final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
            ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 18),
          )
            ..pushStyle(ui.TextStyle(color: Colors.black))
            ..addText(text);

          final ui.Paragraph paragraph = paragraphBuilder.build()
            ..layout(ui.ParagraphConstraints(width: colWidth - 20));

          canvas.drawParagraph(paragraph, Offset(x, y));
        }
      }

      // Finalize the drawing
      final ui.Picture picture = recorder.endRecording();
      final ui.Image img =
      await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());

      // Convert image to PNG
      final ByteData? pngBytes =
      await img.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngData = pngBytes!.buffer.asUint8List();

      // Save image locally
      final dir = await getTemporaryDirectory();
      final File outputFile = File('${dir.path}/excel_thumbnail.png');
      await outputFile.writeAsBytes(pngData);

      return outputFile;
    } catch (e) {
      throw Exception("Error processing Excel file: $e");
    }
  }

  Future<File> generatePptxThumbnail(XFile file) async {
    try {
      // Read PPTX file as bytes
      final Uint8List pptxBytes = await file.readAsBytes();

      // Extract content using archive package
      final Archive archive = ZipDecoder().decodeBytes(pptxBytes);

      // Locate the first slide XML
      ArchiveFile? slideFile;
      for (var file in archive.files) {
        if (file.name.contains("ppt/slides/slide1.xml")) {
          slideFile = file;
          break;
        }
      }

      if (slideFile == null) {
        throw Exception("No slides found in the PPTX file.");
      }

      // Parse slide text (basic XML parsing)
      String slideContent = String.fromCharCodes(slideFile.content);
      RegExp textRegex = RegExp(r"<a:t>(.*?)<\/a:t>");
      Iterable<RegExpMatch> matches = textRegex.allMatches(slideContent);
      List<String> extractedTexts =
      matches.map((match) => match.group(1) ?? "").toList();

      // Define Canvas Size
      final double canvasWidth = 800;
      final double canvasHeight = 600;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas =
      ui.Canvas(recorder, Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));

      // Fill background with white
      final Paint backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(
          Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), backgroundPaint);

      // Text Paint
      final Paint textPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      // Render text from slide
      double startX = 50, startY = 100;
      double lineSpacing = 40;

      for (int i = 0; i < extractedTexts.length && i < 10; i++) {
        String text = extractedTexts[i];

        // Draw text using ParagraphBuilder
        final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
          ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 24),
        )
          ..pushStyle(ui.TextStyle(color: Colors.black))
          ..addText(text);

        final ui.Paragraph paragraph = paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: canvasWidth - 100));

        canvas.drawParagraph(paragraph, Offset(startX, startY + i * lineSpacing));
      }

      // Finalize the drawing
      final ui.Picture picture = recorder.endRecording();
      final ui.Image img =
      await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());

      // Convert image to PNG
      final ByteData? pngBytes =
      await img.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngData = pngBytes!.buffer.asUint8List();

      // Save image locally
      final dir = await getTemporaryDirectory();
      final File outputFile = File('${dir.path}/pptx_thumbnail.png');
      await outputFile.writeAsBytes(pngData);

      return outputFile;
    } catch (e) {
      throw Exception("Error processing PPTX file: $e");
    }
  }
  // Future<void> _uploadFile(File file) async {
  //   if (_selectedFiles.isEmpty) {
  //     print('No files selected for upload');
  //     setState(() {
  //       _fileUploadStatuses = []; // Clear any previous statuses
  //     });
  //     return;
  //   }
  //
  //   for (int i = 0; i < _selectedFiles.length; i++) {
  //     try {
  //       var request = http.MultipartRequest(
  //         'POST',
  //         Uri.parse(
  //             '${ApiUrls.baseUrl}ArchiveAPI/NewDocument'),
  //       );
  //
  //       print('Uploading file ${i + 1}/${_selectedFiles.length}: ${_selectedFiles[i].path}');
  //
  //       setState(() {
  //         _fileUploadStatuses[i] = 'uploading';
  //       });
  //
  //       request.files.add(
  //         await http.MultipartFile.fromPath('Files', _selectedFiles[i].path),
  //       );
  //
  //       // Add other required fields
  //       request.fields['FlagId'] = "0";
  //       request.fields['DocumentName'] = _selectedFiles[i].path.split('/').last;
  //       request.fields['CreatedBy'] = userData['userId'].toString();
  //       request.fields['extractedValuesJson'] = jsonEncode([
  //         {
  //           "FileName": _selectedFiles[i].path.split('/').last,
  //           "CloudName": "",
  //           "IsMain": true,
  //           "Url": _selectedFiles[i].uri.toString(),
  //           "ThumbnailUrl": "null"
  //         }
  //       ]);
  //       request.fields['ApprovalUserJson'] = "[]";
  //       request.fields['ShareUserJson'] = userData['userId'].toString();
  //       request.fields['ReportingUserID'] = "31";
  //       request.fields['IsArchiveApproval'] = "false";
  //       request.fields['WorkflowJson'] = "[]";
  //       request.fields['DocumentInfoJson'] = "[]";
  //       request.fields['VersionName'] = "1.0";
  //       request.fields['ParentId'] = "0";
  //
  //       // Debugging: Print request details
  //       print('--- Request Details for file ${i + 1} ---');
  //       print('URL: ${request.url}');
  //       print('Method: ${request.method}');
  //       print('Headers: ${request.headers}');
  //       print('Fields: ${request.fields}');
  //       print('Files:');
  //       for (var file in request.files) {
  //         print('  Field: ${file.field}');
  //         print('  Filename: ${file.filename}');
  //         print('  Content-Type: ${file.contentType}');
  //       }
  //       print('--- End of Request ---');
  //
  //       // Send request
  //       var response = await request.send();
  //       var responseBody = await response.stream.bytesToString();
  //
  //       if (response.statusCode == 200) {
  //         print('✅ File ${i + 1} uploaded successfully');
  //         setState(() {
  //           _fileUploadStatuses[i] = 'done';
  //         });
  //       } else {
  //         print('❌ File ${i + 1} upload failed - Status: ${response.statusCode}');
  //         print('Response body: $responseBody');
  //         setState(() {
  //           _fileUploadStatuses[i] = 'failed';
  //         });
  //       }
  //     } catch (e) {
  //       print('🚨 Error while uploading file ${i + 1}: $e');
  //       setState(() {
  //         _fileUploadStatuses[i] = 'failed';
  //       });
  //     }
  //   }
  // }

  String getShortenedText(String text) {
    if (text.length > 25) {
      return text.substring(0, 10) + '...'; // Keeping more text before truncation
    } else {
      return text;
    }
  }



  void fetchCabinetData() async {
    final url = Uri.parse("https://cswebapps.com/dmsapitest/api/ArchiveAPI/NewGetAssignedCabinet");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"CreatedBy": 31}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> cabinetJson = body["Data"]["CabinetJson"];

      setState(() {
        cabinets = cabinetJson.map((e) => Cabinet.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      // handle error
      setState(() {
        isLoading = false;
      });
      print("Error: ${response.statusCode}");
    }
  }

  Future<void> fetchLabels() async {
    print("3");
    final url =
        '${ApiUrls.baseUrl}LabelsAPI/GetLabelsMaster';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode({'UserId': userData['userId']}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> labelsJson = data['Data']['LablesJson'];
        print('call labels');

        setState(() {
          labels = labelsJson.map((label) => Label.fromJson(label)).toList();
          isLoading = false; // Data is loaded, stop showing loading spinner
        });
      } else {
        print("API request failed with status code:${response.statusCode}");
        setState(() {

          isLoading = false;
        });
      }
    } catch (e) {

      setState(() {

        isLoading = false;
      });
    }
  }

}

Widget _getFileIconForActivity(String fileName) {
  if (fileName.endsWith('.doc')) {
    return SvgPicture.asset(
      'assets/svg_icons/DOC.svg',
      width: 20, // Size equivalent to the original
      height: 20,
    );
  } else if (fileName.endsWith('.pdf')) {
    return SvgPicture.asset(
      'assets/svg_icons/PDF.svg',
      width: 20, // Size equivalent to the original
      height: 20,
    );
  } else if (fileName.endsWith('.docx')) {
    return SvgPicture.asset(
      'assets/svg_icons/DOCX.svg',
      width: 20, // Size equivalent to the original
      height: 20,
    );
  } else if (fileName.endsWith('.xsl') || fileName.endsWith('.xlsx')) {
    return SvgPicture.asset(
      'assets/svg_icons/XSL.svg',
      width: 20, // Size equivalent to the original
      height: 20,
    );
  } else if (fileName.endsWith('.jpg')) {
    return SvgPicture.asset(
      'assets/svg_icons/JPG.svg',
      width: 20, // Size equivalent to the original
      height: 20,
    );
  } else if (fileName.endsWith('.ai')) {
    return SvgPicture.asset(
      'assets/svg_icons/AI.svg', width: 20, // Size equivalent to the original
      height: 20,
    );
  } else if (fileName.endsWith('.avi')) {
    return SvgPicture.asset(
      'assets/svg_icons/AVI.svg',
      width: 20, // Size equivalent to the original
      height: 20,
    );
  } else if (fileName.endsWith('.mp3')) {
    return SvgPicture.asset(
      'assets/svg_icons/MP3.svg',
      width: 20, // Size equivalent to the original
      height: 20,
    );
  } else if (fileName.endsWith('.mp4')) {
    return SvgPicture.asset(
      'assets/svg_icons/MP4.svg',
      width: 20, // Size equivalent to the original
      height: 20,
    );
  } else if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
    return SvgPicture.asset(
      'assets/svg_icons/PPT.svg',
      width: 20, // Size equivalent to the original
      height: 20,
    );
  } else if (fileName.endsWith('.ps')) {
    return SvgPicture.asset(
      'assets/svg_icons/PS.svg', width: 20, // Size equivalent to the original
      height: 20,
    );
  } else if (fileName.endsWith('.png')) {
    return SvgPicture.asset(
      'assets/svg_icons/PNG.svg',
      width: 20, // Size equivalent to the original
      height: 20,
    );
  } else {
    return SvgPicture.asset(
      'assets/svg_icons/DOC.svg',
      width: 20, // Size equivalent to the original
      height: 20,
    );
  }
}
