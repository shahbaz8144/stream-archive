class ArchiveDocumentShareByMe {
  final int documentId;
  final String documentName;
  final String description;
  final String url;
  final String displayName;
  final String createdDate;

  ArchiveDocumentShareByMe({
    required this.documentId,
    required this.documentName,
    required this.description,
    required this.url,
    required this.displayName,
    required this.createdDate,
  });

  factory ArchiveDocumentShareByMe.fromJson(Map<String, dynamic> json) {
    return ArchiveDocumentShareByMe(
      documentId: json['DocumentId'] ?? 0,
      documentName: json['DocumentName'] ?? 'Unknown Document',
      description: json['Description'] ?? 'No description available',
      url: json['Url'] ?? '',
      displayName: json['DisplayName'] ?? 'Unknown User',
      createdDate: json['CreatedDate'] ?? '',
    );
  }
}
