// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as img;
// import 'package:path_provider/path_provider.dart';
//
// class AzureFileUploader {
//   String _sasToken = '';
//   String _blobUrl = '';
//   int _expiryTime = 0;
//   final String apiUrl = 'https://cswebapps.com/dmscoretestapi/api/FileUploadAPI/NewGenerateSASToken';
//
//   /// Fetch SAS token from backend
//   Future<void> _getSasToken() async {
//     if (_sasToken.isEmpty || DateTime.now().millisecondsSinceEpoch > _expiryTime) {
//       try {
//         final response = await http.post(Uri.parse('https://cswebapps.com/dmscoretestapi/api/FileUploadAPI/NewGenerateSASToken'));
//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           _sasToken = data['sasToken'];
//           _blobUrl = data['blobUrl'];
//           _expiryTime = DateTime.parse(data['expiryTime']).millisecondsSinceEpoch;
//         } else {
//           throw Exception("Failed to fetch SAS token");
//         }
//       } catch (e) {
//         throw Exception("Error fetching SAS token: $e");
//       }
//     }
//   }
//
//   /// Upload file to Azure Blob Storage
//   Future<Map<String, String>> uploadFile(File file, StreamController<double> progressStream, String folderPath, String uniqueId) async {
//     await _getSasToken();
//
//     final storage = AzureStorage.parse(_sasToken);
//     final containerName = "your-container-name"; // Replace with actual container name
//     final fileName = "$folderPath/$uniqueId_${file.path.split('/').last}";
//     final blobClient = storage.getBlobClient(containerName, fileName);
//
//     try {
//       await blobClient.putBlob(file.readAsBytesSync(), contentType: "application/octet-stream", onProgress: (progress) {
//         double percentDone = progress / file.lengthSync();
//         progressStream.add(percentDone);
//       });
//
//       String fileUrl = "$_blobUrl/$containerName/$fileName";
//       String? thumbnailUrl;
//
//       // Generate and Upload Thumbnail
//       File? thumbnail = await _generateThumbnail(file, uniqueId);
//       if (thumbnail != null) {
//         String thumbnailName = "thumbnails/$uniqueId_thumb_${file.path.split('/').last}.png";
//         final thumbnailClient = storage.getBlobClient(containerName, thumbnailName);
//         await thumbnailClient.putBlob(thumbnail.readAsBytesSync(), contentType: "image/png");
//         thumbnailUrl = "$_blobUrl/$containerName/$thumbnailName";
//       }
//
//       progressStream.close();
//       return {"fileUrl": fileUrl, "thumbnailUrl": thumbnailUrl ?? ""};
//     } catch (e) {
//       progressStream.close();
//       throw Exception("Error uploading file: $e");
//     }
//   }
//
//   /// Generate Thumbnails
//   Future<File?> _generateThumbnail(File file, String uniqueId) async {
//     String fileType = file.path.split('.').last.toLowerCase();
//
//     if (["jpg", "jpeg", "png"].contains(fileType)) {
//       return _generateImageThumbnail(file);
//     } else if (fileType == "pdf") {
//       return _generatePdfThumbnail(file);
//     } else {
//       return _generatePlaceholderThumbnail(fileType);
//     }
//   }
//
//   /// Generate Image Thumbnail
//   Future<File> _generateImageThumbnail(File file) async {
//     img.Image image = img.decodeImage(await file.readAsBytes())!;
//     img.Image thumbnail = img.copyResize(image, width: 100);
//
//     Directory tempDir = await getTemporaryDirectory();
//     File thumbnailFile = File("${tempDir.path}/thumb_${file.path.split('/').last}.png");
//     await thumbnailFile.writeAsBytes(img.encodePng(thumbnail));
//
//     return thumbnailFile;
//   }
//
//   /// Generate PDF Thumbnail
//   Future<File> _generatePdfThumbnail(File file) async {
//     final pdfDoc = await PDFDocument.fromFile(file);
//     final page = await pdfDoc.getPage(1);
//     final img.Image image = page.render(width: 100, height: 100).image;
//
//     Directory tempDir = await getTemporaryDirectory();
//     File thumbnailFile = File("${tempDir.path}/thumb_${file.path.split('/').last}.png");
//     await thumbnailFile.writeAsBytes(img.encodePng(image));
//
//     return thumbnailFile;
//   }
//
//   /// Generate Placeholder Thumbnail for Unknown File Types
//   Future<File> _generatePlaceholderThumbnail(String fileType) async {
//     img.Image placeholder = img.Image(100, 100);
//     img.fill(placeholder, img.getColor(240, 240, 240));
//     img.drawString(placeholder, img.arial_14, 20, 45, fileType.toUpperCase(), color: img.getColor(0, 0, 0));
//
//     Directory tempDir = await getTemporaryDirectory();
//     File thumbnailFile = File("${tempDir.path}/thumb_placeholder.png");
//     await thumbnailFile.writeAsBytes(img.encodePng(placeholder));
//
//     return thumbnailFile;
//   }
// }
