class ArchiveDocument {
  final int documentId;
  final String documentName;
  final String description;
  final String userName;
  final String status;
  final String url;
  final String createdDate;
  final bool isRead;
  final String createdDateWithTime;
  final bool isFavorite;
  final int shareId;
  final bool isPin;
  final String? versionName;
  final String? createdDateString;


  ArchiveDocument({
    required this.documentId,
    required this.documentName,
    required this.description,
    required this.userName,
    required this.status,
    required this.url,
    required this.createdDate,
    required this.isRead,
    required this.createdDateWithTime,
    required this.isFavorite,
    required this.shareId,
    required this.isPin,
    required this.versionName,
    required this.createdDateString,

  });

  factory ArchiveDocument.fromJson(Map<String, dynamic> json) {
    return ArchiveDocument(
      documentId: json["DocumentId"] ?? 0,
      documentName: json["DocumentName"] ?? "Unknown",
      description: json["Description"] ?? "No Description",
      userName: json["UserName"] ?? "N/A",
      status: json["Status"] ?? "Unknown",
      url: json["Url"] ?? "",
      createdDate: json["CreatedDateString"] ?? "",
      isRead: json['IsRead'] ?? true,
      createdDateWithTime: json['CreatedDate'] ?? "",
      isFavorite: json['IsFavorite'] ?? false,
      shareId: json['ShareId'] ?? 0,
      isPin: json['IsPin'] ?? false,
      versionName: json['VersionName'] ?? "",
      createdDateString: json['CreatedDateString'] ?? "",
    );
  }

  static List<ArchiveDocument> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((item) => ArchiveDocument.fromJson(item)).toList();
  }
}
