class TrashItem {
  final int documentId;
  final String documentName;
  final String description;
  final String displayName;
  final String startDate;
  final String endDate;
  final bool isDeleted;
  final String url;
  final String createdDate;

  TrashItem({
    required this.documentId,
    required this.documentName,
    required this.description,
    required this.displayName,
    required this.startDate,
    required this.endDate,
    required this.isDeleted,
    required this.url,
    required this.createdDate,
  });

  factory TrashItem.fromJson(Map<String, dynamic> json) {
    return TrashItem(
      documentId: json['DocumentId'] ?? 0,
      documentName: json['DocumentName'] ?? '',
      description: json['Description'] ?? '',
      displayName: json['DisplayName'] ?? '',
      startDate: json['StartDate'] ?? '',
      endDate: json['EndDate'] ?? '',
      isDeleted: json['IsDeleted'] ?? false,
      url: json['Url'] ?? '',
      createdDate: json['CreatedDate'] ?? "",
    );
  }
}
