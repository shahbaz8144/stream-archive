class FavoriteDocument {
  final int documentId;
  final String documentName;
  final String documentTypeName;
  final String sourceName;
  final String distributorAndManufacture;
  final String description;
  final String location;
  final bool isFoodItem;
  final String isFoodItemExpiryDate;
  final String displayName;
  final String shareType;
  final String startDate;
  final String endDate;
  final bool isFavorite;
  final bool isRead;
  final bool isPermanent;
  final bool isFullAccess;
  final bool isPhysical;
  final String status;
  final String url;
  final String fileName;
  final String createdDateString;
  final String createdDate;
  final String versionName;
  final String userName;
  final int sharedId;

  FavoriteDocument({
    required this.documentId,
    required this.documentName,
    required this.documentTypeName,
    required this.sourceName,
    required this.distributorAndManufacture,
    required this.description,
    required this.location,
    required this.isFoodItem,
    required this.isFoodItemExpiryDate,
    required this.displayName,
    required this.shareType,
    required this.startDate,
    required this.endDate,
    required this.isFavorite,
    required this.isRead,
    required this.isPermanent,
    required this.isFullAccess,
    required this.isPhysical,
    required this.status,
    required this.url,
    required this.fileName,
    required this.createdDateString,
    required this.createdDate,
    required this.versionName,
    required this.userName,
    required this.sharedId,
  });

  factory FavoriteDocument.fromJson(Map<String, dynamic> json) {
    return FavoriteDocument(
      documentId: json["DocumentId"] ?? 0,
      documentName: json["DocumentName"] ?? "Unknown",
      documentTypeName: json["DocumentTypeName"] ?? "",
      sourceName: json["SourceName"] ?? "",
      distributorAndManufacture: json["DistributorAndManufacture"] ?? "",
      description: json["Description"] ?? "",
      location: json["Location"] ?? "",
      isFoodItem: json["IsFoodItem"] ?? false,
      isFoodItemExpiryDate: json["IsFoodItemExpiryDate"] ?? "",
      displayName: json["DisplayName"] ?? "Unknown",
      shareType: json["ShareType"] ?? "",
      startDate: json["StartDate"] ?? "",
      endDate: json["EndDate"] ?? "",
      isFavorite: json["IsFavorite"] ?? false,
      isRead: json["IsRead"] ?? false,
      isPermanent: json["IsPermanent"] ?? false,
      isFullAccess: json["IsFullAccess"] ?? false,
      isPhysical: json["IsPhysical"] ?? false,
      status: json["Status"] ?? "Unknown",
      url: json["Url"] ?? "",
      fileName: json["FileName"] ?? "",
      createdDateString: json["CreatedDateString"] ?? "",
      createdDate: json["CreatedDate"] ?? "",
      versionName: json["VersionName"] ?? "",
      userName: json["UserName"] ?? "",
      sharedId: json['ShareId'] ?? 0
    );
  }
}
