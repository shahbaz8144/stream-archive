class Label {
  final int labelId;
  final String labelName;
  final bool isActive;
  final int memoCount;

  Label({
    required this.labelId,
    required this.labelName,
    required this.isActive,
    required this.memoCount,
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      labelId: json['LabelId'] ?? 0,
      labelName: json['LabelName'] ?? '',
      isActive: json['isActive'] ?? false,
      memoCount: json['MemoCount'] ?? 0,
    );
  }
}

class LabelResponse {
  final bool status;
  final String message;
  final List<Label> labels;

  LabelResponse({
    required this.status,
    required this.message,
    required this.labels,
  });

  factory LabelResponse.fromJson(Map<String, dynamic> json) {
    var labelsJson = json['Data']?['LablesJson'] as List? ?? [];
    List<Label> labelList = labelsJson.map((label) => Label.fromJson(label)).toList();

    return LabelResponse(
      status: json['Status'] ?? false,
      message: json['Message'] ?? '',
      labels: labelList,
    );
  }
}
