import 'dart:io';

import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
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





import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdf/pdf.dart' as pdf;

import '../models/archive_inbox_model.dart';
import '../models/archive_pin_model.dart';
import '../models/archive_share_by_me_model.dart';
import '../models/archive_share_with_me_model.dart';
import '../models/archive_trash_model.dart';
import 'dart:ui' as ui;

import 'package:pdf_render/pdf_render.dart' as pdfRender;
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion_pdf;

import 'package:http_parser/http_parser.dart'; // Required for Content-Type

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

  ///////////////For OCR /////////////
  File? _selectedFile;
  String _fileType = '';
  String _extractedText = '';
  final TextRecognizer _textRecognizer = TextRecognizer();

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
    setModalState(() {
      _extractedText = 'Processing .doc file... Please convert it to .docx first.';
    });

    debugPrint('Processing .doc file: ${file.path}');
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showList = !showList;
                    });
                  },
                  child: Icon(showList ? Icons.grid_on : Icons.list),
                ),
              ),
            ],
          ),
          showList
              ? Expanded(
              child: SmartRefresher(
                  controller: _refreshControllerForMainArchiveList,
                  onRefresh: () async {
                    // Reset the page and fetch again
                    await fetchDocuments(isRefresh: true);
                    _refreshControllerForMainArchiveList.refreshCompleted();
                  },
                  enablePullUp: true,
                  enablePullDown: true,
                  onLoading: () async {
                    print('working');
                    // Load more documents
                    await fetchDocuments(isRefresh: false);
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

                      return Card(
                        child: ListTile(
                          contentPadding:
                          const EdgeInsets.only(left: 8.0, right: 0.0),
                          leading: Container(
                            width:
                            50,
                            // Explicitly set the width of the leading widget
                            height:
                            50,
                            // Explicitly set the height of the leading widget
                            child: ClipRRect(
                              borderRadius: BorderRadius
                                  .zero,
                              // Removes the circle and gives a square look
                              child: Image.network(
                                doc.url,
                                fit: BoxFit
                                    .cover, // Ensures the image fits properly
                              ),
                            ),
                          ),
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize
                                .min,
                            // Ensures the Row only takes up necessary space
                            children: [
                              if (doc.isPin)
                                Icon(
                                  Icons.push_pin_sharp,
                                  size: 15,
                                  color: Colors.blue,
                                ),
                              if (doc.isFavorite)
                                Icon(
                                  LineAwesomeIcons.star,
                                  size: 15,
                                  color: Colors.yellow.shade800,
                                ),
                              IconButton(
                                icon: Icon(
                                  Symbols.keyboard_arrow_down,
                                  size: 20.0,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  // Handle more options
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Container(
                                        height:
                                        450,
                                        // Set the height of the bottom sheet
                                        width: double.infinity,
                                        color: Colors
                                            .white,
                                        // Background color of the bottom sheet
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              top: 20.0),
                                          child: Column(
                                            children: [
                                              Container(
                                                height: 5,
                                                width: 60,
                                                decoration: BoxDecoration(
                                                  color:
                                                  Colors.grey.shade300,
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      8),
                                                ),
                                              ),
                                              SizedBox(height: 20.0),
                                              Container(
                                                width:
                                                100,
                                                // Explicitly set the width of the leading widget
                                                height:
                                                100,
                                                // Explicitly set the height of the leading widget
                                                child: ClipRRect(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      5.0),
                                                  child: Image.network(
                                                    doc.url,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 20.0),
                                              Text(
                                                  getShortenedText(
                                                      doc.documentName),
                                                  style: TextStyle(
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                      FontWeight.w600)),
                                              Text(
                                                  DateFormat(
                                                      'MMMM dd, yyyy, hh:mm:ss a')
                                                      .format(DateTime.parse(doc
                                                      .createdDateWithTime)),
                                                  style: TextStyle(
                                                      fontSize: 12.0)),
                                              SizedBox(height: 10.0),
                                              Container(
                                                height: 0.15,
                                                color: Colors.grey,
                                              ),
                                              Expanded(
                                                child: ListView(
                                                  children: [
                                                    ListTile(
                                                      leading: Icon(
                                                          Symbols.keep_pin),
                                                      title: Text('Pin'),
                                                      onTap: () {
                                                        // Handle tap action
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading:
                                                      Icon(Icons.star),
                                                      title:
                                                      Text('Favorite'),
                                                      onTap: () async {
                                                        await archiveFavorite(
                                                            doc.documentId,
                                                            doc.shareId,
                                                            doc.isFavorite);
                                                        setState(() {
                                                          fetchDocuments(
                                                              isRefresh:
                                                              true);
                                                        });
                                                        Navigator.pop(
                                                            context);
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading:
                                                      Icon(Icons.mail),
                                                      title: Text('Unread'),
                                                      onTap: () {
                                                        // Handle tap action
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading: Icon(
                                                          Icons.delete),
                                                      title: Text('Delete'),
                                                      onTap: () async {
                                                        await archiveTrash(
                                                            doc.shareId,
                                                            doc.documentId);
                                                        setState(() {
                                                          fetchDocuments(
                                                              isRefresh:
                                                              true);
                                                        });
                                                        Navigator.pop(
                                                            context);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            print('Tapped on list');
                          },
                        ),
                      );
                    },
                  )))
              : Expanded(
              child: SmartRefresher(
                  controller: _refreshControllerForMainArchiveList,
                  onRefresh: () async {
                    // Reset the page and fetch again
                    await fetchDocuments(isRefresh: true);
                    _refreshControllerForMainArchiveList.refreshCompleted();
                  },
                  enablePullUp: true,
                  enablePullDown: true,
                  onLoading: () async {
                    print('working');
                    // Load more documents
                    await fetchDocuments(isRefresh: false);
                  },
                  child: GridView.builder(
                    itemCount: pinDocuments.length +
                        documents
                            .length, // Combine the length of both lists
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of columns
                      crossAxisSpacing: 8.0, // Space between columns
                      mainAxisSpacing: 8.0, // Space between rows
                      childAspectRatio:
                      0.75, // Aspect ratio for each grid item (width/height)
                    ),
                    itemBuilder: (context, index) {
                      // Determine which list the current index belongs to
                      final isPinDocument = index < pinDocuments.length;
                      final doc = isPinDocument
                          ? pinDocuments[index]
                          : documents[index - pinDocuments.length];

                      return Card(
                        elevation:
                        4.0,
                        // Optional: Add some elevation to make it stand out
                        margin: EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DocDetails()),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (doc.isPin)
                                    Icon(Icons.push_pin_sharp,
                                        size: 15, color: Colors.blue),
                                  if (doc.isFavorite)
                                    Icon(LineAwesomeIcons.star,
                                        size: 15,
                                        color: Colors.yellow.shade800),
                                  IconButton(
                                    icon: Icon(
                                      Icons.more_vert_outlined,
                                      size: 20.0,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      // Handle more options
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Container(
                                            height:
                                            450,
                                            // Set the height of the bottom sheet
                                            width: double.infinity,
                                            color: Colors
                                                .white,
                                            // Background color of the bottom sheet
                                            child: Padding(
                                              padding:
                                              const EdgeInsets.only(
                                                  top: 20.0),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    height: 5,
                                                    width: 60,
                                                    decoration:
                                                    BoxDecoration(
                                                      color: Colors
                                                          .grey.shade300,
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(8),
                                                    ),
                                                  ),
                                                  SizedBox(height: 20.0),
                                                  Container(
                                                    width:
                                                    100,
                                                    // Explicitly set the width of the leading widget
                                                    height:
                                                    100,
                                                    // Explicitly set the height of the leading widget
                                                    child: ClipRRect(
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                          5.0),
                                                      child: Image.network(
                                                        doc.url,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 20.0),
                                                  Text(
                                                      getShortenedText(
                                                          doc.documentName),
                                                      style: TextStyle(
                                                          fontSize: 16.0,
                                                          fontWeight:
                                                          FontWeight
                                                              .w600)),
                                                  Text(
                                                      DateFormat(
                                                          'MMMM dd, yyyy, hh:mm:ss a')
                                                          .format(DateTime
                                                          .parse(doc
                                                          .createdDateWithTime)),
                                                      style: TextStyle(
                                                          fontSize: 12.0)),
                                                  SizedBox(height: 10.0),
                                                  Container(
                                                    height: 0.15,
                                                    color: Colors.grey,
                                                  ),
                                                  Expanded(
                                                    child: ListView(
                                                      children: [
                                                        ListTile(
                                                          leading: Icon(
                                                              Symbols
                                                                  .keep_pin),
                                                          title:
                                                          Text('Pin'),
                                                          onTap: () {
                                                            // Handle tap action
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: Icon(
                                                              Icons.star),
                                                          title: Text(
                                                              'Favorite'),
                                                          onTap: () async {
                                                            await archiveFavorite(
                                                                doc.documentId,
                                                                doc.shareId,
                                                                doc.isFavorite);
                                                            setState(() {
                                                              fetchDocuments(
                                                                  isRefresh:
                                                                  true);
                                                            });
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: Icon(
                                                              Icons.mail),
                                                          title: Text(
                                                              'Unread'),
                                                          onTap: () {
                                                            // Handle tap action
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: Icon(
                                                              Icons.delete),
                                                          title: Text(
                                                              'Delete'),
                                                          onTap: () async {
                                                            await archiveTrash(
                                                                doc.shareId,
                                                                doc.documentId);
                                                            setState(() {
                                                              fetchDocuments(
                                                                  isRefresh:
                                                                  true);
                                                            });
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Container(
                                height:
                                120, // Set a fixed height for the image
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius
                                      .zero,
                                  // Removes the circle and gives a square look
                                  child: Image.network(
                                    doc.url,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  getShortenedText(doc.documentName),
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color: doc.isRead
                                        ? Colors.black
                                        : Colors.blue,
                                  ),
                                ),
                              ),
                              // Padding(
                              //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              //   child: Text(
                              //     doc.userName,
                              //     style: TextStyle(
                              //       fontSize: 11,
                              //       color: doc.isRead ? Colors.black : Colors.blue,
                              //     ),
                              //   ),
                              // ),
                              // Padding(
                              //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              //   child: Text(
                              //     getShortenedText(doc.description),
                              //     style: TextStyle(
                              //       fontSize: 9,
                              //       color: doc.isRead ? Colors.grey : Colors.blue,
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      );
                    },
                  )))
        ],
      ),

      // Favorite page
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
            return ListTile(
              contentPadding:
              const EdgeInsets.only(left: 8.0, right: 0.0),
              leading: Container(
                width:
                50, // Explicitly set the width of the leading widget
                height:
                50, // Explicitly set the height of the leading widget
                child: ClipRRect(
                  borderRadius: BorderRadius
                      .zero, // Removes the circle and gives a square look
                  child: Image.network(
                    doc.url,
                    fit: BoxFit
                        .cover, // Ensures the image fits properly
                  ),
                ),
              ),
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
              trailing: Row(
                mainAxisSize: MainAxisSize
                    .min, // Ensures the Row only takes up necessary space
                children: [
                  if (doc.isFavorite == true)
                    Icon(
                      LineAwesomeIcons.star,
                      size: 15,
                      color: Colors.yellow.shade800,
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert_outlined,
                      size: 20.0,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      print("More icon tapped");

                      // Show the bottom sheet
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height:
                            300, // Set the height of the bottom sheet
                            width: double.infinity,
                            color: Colors
                                .white, // Background color of the bottom sheet
                            child: Padding(
                              padding:
                              const EdgeInsets.only(top: 20.0),
                              child: Column(
                                children: [
                                  Container(
                                    height: 5,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                  ),
                                  SizedBox(height: 20.0),
                                  Container(
                                    width:
                                    100,
                                    // Explicitly set the width of the leading widget
                                    height:
                                    100,
                                    // Explicitly set the height of the leading widget
                                    child: ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(5.0),
                                      child: Image.network(
                                        doc.url,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20.0),
                                  Text(
                                      getShortenedText(
                                          doc.documentName),
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight:
                                          FontWeight.w600)),
                                  Text(
                                      DateFormat(
                                          'MMMM dd, yyyy, hh:mm:ss a')
                                          .format(DateTime.parse(
                                          doc.createdDate)),
                                      style:
                                      TextStyle(fontSize: 12.0)),
                                  SizedBox(height: 10.0),
                                  Container(
                                    height: 0.15,
                                    color: Colors.grey,
                                  ),
                                  Expanded(
                                    child: ListView(
                                      children: [
                                        ListTile(
                                          leading: Icon(Icons.star),
                                          title: Text('Favorite'),
                                          onTap: () {
                                            // Handle tap action if needed
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              onTap: () {
                print('Tapped on list');
              },
            );
          },
        ),
      ),
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

            return ListTile(
              leading: Container(
                width:
                50, // Explicitly set the width of the leading widget
                height:
                50, // Explicitly set the height of the leading widget
                child: ClipRRect(
                  borderRadius: BorderRadius
                      .zero, // Removes the circle and gives a square look
                  child: Image.network(
                    doc.url,
                    fit: BoxFit
                        .cover, // Ensures the image fits properly
                  ),
                ),
              ),
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
              trailing: Row(
                mainAxisSize: MainAxisSize
                    .min, // Ensures the Row only takes up necessary space
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.more_vert_outlined,
                      size: 20.0,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      print("More icon tapped");

                      // Show the bottom sheet
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height:
                            300, // Set the height of the bottom sheet
                            width: double.infinity,
                            color: Colors
                                .white, // Background color of the bottom sheet
                            child: Padding(
                              padding:
                              const EdgeInsets.only(top: 20.0),
                              child: Column(
                                children: [
                                  Container(
                                    height: 5,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                  ),
                                  SizedBox(height: 20.0),
                                  Container(
                                    width:
                                    100,
                                    // Explicitly set the width of the leading widget
                                    height:
                                    100,
                                    // Explicitly set the height of the leading widget
                                    child: ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(5.0),
                                      child: Image.network(
                                        doc.url,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20.0),
                                  Text(
                                      getShortenedText(
                                          doc.documentName),
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight:
                                          FontWeight.w600)),
                                  Text(
                                      DateFormat(
                                          'MMMM dd, yyyy, hh:mm:ss a')
                                          .format(DateTime.parse(
                                          doc.createdDate)),
                                      style:
                                      TextStyle(fontSize: 12.0)),
                                  SizedBox(height: 10.0),
                                  Container(
                                    height: 0.15,
                                    color: Colors.grey,
                                  ),
                                  Expanded(
                                    child: ListView(
                                      children: [
                                        ListTile(
                                          leading: Icon(Symbols
                                              .restore_from_trash),
                                          title: Text('Restore'),
                                          onTap: () {
                                            // Handle tap action
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              onTap: () {
                print('Tapped on list');
              },
            );
          },
        ),
      ),

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

                    return ListTile(
                      leading: Container(
                        width:
                        50, // Explicitly set the width of the leading widget
                        height:
                        50, // Explicitly set the height of the leading widget
                        child: ClipRRect(
                          borderRadius: BorderRadius
                              .zero,
                          // Removes the circle and gives a square look
                          child: Image.network(
                            doc.url,
                            fit: BoxFit
                                .cover, // Ensures the image fits properly
                          ),
                        ),
                      ),
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
                          Text(
                            getShortenedText(doc.description),
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize
                            .min,
                        // Ensures the Row only takes up necessary space
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.more_vert_outlined,
                              size: 20.0,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              print("More icon tapped");

                              // Show the bottom sheet
                              showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return Container(
                                    height:
                                    350,
                                    // Set the height of the bottom sheet
                                    width: double.infinity,
                                    color: Colors
                                        .white,
                                    // Background color of the bottom sheet
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 20.0),
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 5,
                                            width: 60,
                                            decoration: BoxDecoration(
                                              color: Colors
                                                  .grey.shade300,
                                              borderRadius:
                                              BorderRadius
                                                  .circular(8),
                                            ),
                                          ),
                                          SizedBox(height: 20.0),
                                          Container(
                                            width:
                                            100,
                                            // Explicitly set the width of the leading widget
                                            height:
                                            100,
                                            // Explicitly set the height of the leading widget
                                            child: ClipRRect(
                                              borderRadius:
                                              BorderRadius
                                                  .circular(5.0),
                                              child: Image.network(
                                                doc.url,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 20.0),
                                          Text(
                                              getShortenedText(
                                                  doc.documentName),
                                              style: TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight:
                                                  FontWeight
                                                      .w600)),
                                          Text(
                                              DateFormat(
                                                  'MMMM dd, yyyy, hh:mm:ss a')
                                                  .format(DateTime
                                                  .parse(doc
                                                  .createdDate)),
                                              style: TextStyle(
                                                  fontSize: 12.0)),
                                          SizedBox(height: 10.0),
                                          Container(
                                            height: 0.15,
                                            color: Colors.grey,
                                          ),
                                          Expanded(
                                            child: ListView(
                                              children: [
                                                ListTile(
                                                  leading: Icon(
                                                      Symbols
                                                          .keep_pin),
                                                  title: Text('Pin'),
                                                  onTap: () {
                                                    // Handle tap action
                                                  },
                                                ),
                                                ListTile(
                                                  leading: Icon(
                                                      Icons.star),
                                                  title: Text(
                                                      'Favorite'),
                                                  onTap: () {
                                                    // Handle tap action if needed
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        print('Tapped on list');
                      },
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

                    return ListTile(
                      leading: Container(
                        width:
                        50, // Explicitly set the width of the leading widget
                        height:
                        50, // Explicitly set the height of the leading widget
                        child: ClipRRect(
                          borderRadius: BorderRadius
                              .zero,
                          // Removes the circle and gives a square look
                          child: Image.network(
                            doc.url,
                            fit: BoxFit
                                .cover, // Ensures the image fits properly
                          ),
                        ),
                      ),
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
                          Text(
                            getShortenedText(doc.description),
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize
                            .min,
                        // Ensures the Row only takes up necessary space
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.more_vert_outlined,
                              size: 20.0,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              print("More icon tapped");

                              // Show the bottom sheet
                              showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return Container(
                                    height:
                                    350,
                                    // Set the height of the bottom sheet
                                    width: double.infinity,
                                    color: Colors
                                        .white,
                                    // Background color of the bottom sheet
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 20.0),
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 5,
                                            width: 60,
                                            decoration: BoxDecoration(
                                              color: Colors
                                                  .grey.shade300,
                                              borderRadius:
                                              BorderRadius
                                                  .circular(8),
                                            ),
                                          ),
                                          SizedBox(height: 20.0),
                                          Container(
                                            width:
                                            100,
                                            // Explicitly set the width of the leading widget
                                            height:
                                            100,
                                            // Explicitly set the height of the leading widget
                                            child: ClipRRect(
                                              borderRadius:
                                              BorderRadius
                                                  .circular(5.0),
                                              child: Image.network(
                                                doc.url,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 20.0),
                                          Text(
                                              getShortenedText(
                                                  doc.documentName),
                                              style: TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight:
                                                  FontWeight
                                                      .w600)),
                                          Text(
                                              DateFormat(
                                                  'MMMM dd, yyyy, hh:mm:ss a')
                                                  .format(DateTime
                                                  .parse(doc
                                                  .createdDate)),
                                              style: TextStyle(
                                                  fontSize: 12.0)),
                                          SizedBox(height: 10.0),
                                          Container(
                                            height: 0.15,
                                            color: Colors.grey,
                                          ),
                                          Expanded(
                                            child: ListView(
                                              children: [
                                                ListTile(
                                                  leading: Icon(
                                                      Symbols
                                                          .keep_pin),
                                                  title: Text('Pin'),
                                                  onTap: () {
                                                    // Handle tap action
                                                  },
                                                ),
                                                ListTile(
                                                  leading: Icon(
                                                      Icons.star),
                                                  title: Text(
                                                      'Favorite'),
                                                  onTap: () {
                                                    // Handle tap action if needed
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        print('Tapped on list');
                      },
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
      fetchDocuments(isRefresh: true);
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
    fetchDocuments(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                    "https://yrglobaldocuments.blob.core.windows.net/documents/" +
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
      ),
      body: _getWidgetOptions()
          .elementAt(_selectedIndex), // Display the selected widget
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // Ensure labels are always visible
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () => _onItemTapped(0), // Call function when tapped
              child: SvgPicture.asset(
                'assets/svg_icons/archive_inbox_icon.svg',
                color: _selectedIndex == 0 ? Colors.amber[800] : Colors.grey,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // showModalBottomSheet(
          //   context: context,
          //   builder: (BuildContext context) {
          //     return Container(
          //       height: 400, // Set the height of the bottom sheet
          //       width: double.infinity,
          //       color: Colors.white,
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         mainAxisAlignment: MainAxisAlignment.start,
          //         children: [
          //           SizedBox(
          //             height: 20.0,
          //           ),
          //           Padding(
          //             padding: const EdgeInsets.only(left: 8.0),
          //             child: Text(
          //               'Add to Stream Archive',
          //               style: TextStyle(
          //                   fontSize: 18.0,
          //                   fontWeight: FontWeight.w600,
          //                   color: Colors.grey),
          //             ),
          //           ),
          //          Expanded(child: ListView(
          //            children: [
          //              ListTile(
          //                leading: Icon(Icons.camera_alt),
          //                title: Text('Take a photo'),
          //
          //                onTap: () {
          //                  // Handle tap for Item 1
          //                  print('Item 1 tapped');
          //                },
          //              ),
          //              ListTile(
          //                leading: Icon(Icons.file_copy),
          //                title: Text('Upload a file'),
          //
          //                onTap: () {
          //                  // Handle tap for Item 2
          //                  print('Item 2 tapped');
          //                },
          //              ),
          //              ListTile(
          //                leading: Icon(Icons.document_scanner_outlined),
          //                title: Text('Scan document'),
          //
          //                onTap: () {
          //                  // Handle tap for Item 3
          //                  print('Item 3 tapped');
          //                },
          //              ),
          //            ],
          //          ),),
          //
          //         ],
          //       ),
          //     );
          //   },
          // );

          _openFilePicker();
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }

//Load user data from here
  Future<void> _loadUserData() async {
    userData = await UserDataManager.loadUserData();
  }

  //Api call function here
  Future<void> fetchDocuments({bool isRefresh = false}) async {
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
        "https://cswebapps.com/dmscoretestapi/api/ArchiveAPI/ArchiveDocumentList");
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
      "IsAll": true
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

          setState(() {
            if (isRefresh) {
              // If it's a refresh, clear the existing list
              documents = jsonList
                  .map((json) => ArchiveDocument.fromJson(json))
                  .toList();
              pinDocuments = jsonPinList
                  .map((json) => ArchivePinDocument.fromJson(json))
                  .toList();
            } else {
              // If it's loading more, append to the existing list
              documents.addAll(jsonList
                  .map((json) => ArchiveDocument.fromJson(json))
                  .toList());
            }
          });

          print("Documents loaded: ${documents.length}");

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

  Future<void> fetchFavoriteDocuments() async {
    final url = Uri.parse(
        'https://cswebapps.com/dmscoretestapi/api/Gac/ArchiveFavoriteList_V2');
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
          setState(() {
            favoriteDocuments = jsonList
                .map((json) => FavoriteDocument.fromJson(json))
                .toList();
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
        'https://cswebapps.com/dmscoretestapi/api/Gac/ArchiveTrashList_V2');
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

  Future<void> fetchShareWithMeList() async {
    final url = Uri.parse(
        'https://cswebapps.com/dmscoretestapi/api/ArchiveAPI/ArchiveShareWithMeList');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "CreatedBy": 44,
      "Organizationid": userData['organizationid'],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        if (data["Status"] == true) {
          List<dynamic> jsonList = data["Data"]["ArchiveJson"];
          setState(() {
            shareWithMeList = jsonList
                .map((json) => ArchiveDocumentShareWithMe.fromJson(json))
                .toList();
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

  Future<void> fetchShareByMeList() async {
    final url = Uri.parse(
        'https://cswebapps.com/dmscoretestapi/api/ArchiveAPI/ArchiveShareByMeList');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "CreatedBy": 44,
      "Organizationid": userData['organizationid'],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        if (data["Status"] == true) {
          List<dynamic> jsonList = data["Data"]["ArchiveJson"];
          setState(() {
            shareByMeList = jsonList
                .map((json) => ArchiveDocumentShareByMe.fromJson(json))
                .toList();
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

  //////////////call delete api function

  Future<void> archiveTrash(int shareId, int documentId) async {
    final url = Uri.parse(
        'https://cswebapps.com/dmscoretestapi/api/Gac/ArchiveTrash_V2');

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
        'https://cswebapps.com/dmscoretestapi/api/Gac/ArchiveFavorite_V2');
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'DocumentId': documentId,
      'ShareId': shareId,
      'isFavorite': isFavorite,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
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
  //   var url = 'https://cswebapps.com/dmscoretestapi/api/ArchiveAPI/NewDocument';
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
            'https://cswebapps.com/dmscoretestapi/api/FileUploadAPI/NewGenerateSASToken'));
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

      var url = 'https://cswebapps.com/dmscoretestapi/api/ArchiveAPI/NewDocument';


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
          "FlagId": 0,
          "DocumentName": file.path
              .split('/')
              .last,
          "CreatedBy": 31,
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
          await fetchDocuments(isRefresh: true);


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
  //             'https://cswebapps.com/dmscoretestapi/api/ArchiveAPI/NewDocument'),
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
    if (text.length > 35) {
      return text.substring(0, 30) + '...';
    } else {
      return text;
    }
  }
}
