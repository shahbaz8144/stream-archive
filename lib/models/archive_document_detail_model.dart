import 'dart:convert';

class ArchiveDocumentDetailModel {
  final int documentId;
  final String documentName;
  final String userName;
  final String createdDate;
  final String designationName;
  final String url;
   bool isFavorite;
  final List<UserAction> userActions;
  final List<UserInfo> userList;
  final List<VersionInfo> versions;
  final String status;
  final String description;
  final String displayName;
  final String sourceName;
  final String documentTypeName;
  final String dmName;
  final List<dynamic> subCategoryJson;
  final List<dynamic> referenceJson;
  final String fileName;
  final String dateStatus;
  final bool isFullAccess;
  final String versionName;
  final int parentId;
  final int labelCount;
  final bool isDeleted;
   bool isPin;
  final String labelIds;
  final int shareId;
  final bool isPhysical;
  final int length;
  final int breadth;
  final int height;
  final bool isFoodItem;
  final String documentWith;
  final List<dynamic> documentLocationJ;
  final String workFlowName;
  final int workFlowId;
  final String workFlowStatus;
  final int totalUserActions;
  final int documentTypeId;
  final int sourceId;
  final int dmId;
  final int cabinetId;
  final String barcode;
  final String prefix;
  final String cabinetName;
  final String cabinetNameAr;
  final String yyyyMmDd;
  final String positionX;
  final String positionY;
  final Map<String, dynamic> templateData;

  ArchiveDocumentDetailModel({
    required this.documentId,
    required this.documentName,
    required this.userName,
    required this.createdDate,
    required this.designationName,
    required this.url,
    required this.isFavorite,
    required this.userActions,
    required this.userList,
    required this.versions,
    required this.status,
    required this.description,
    required this.displayName,
    required this.sourceName,
    required this.documentTypeName,
    required this.dmName,
    required this.subCategoryJson,
    required this.referenceJson,
    required this.fileName,
    required this.dateStatus,
    required this.isFullAccess,
    required this.versionName,
    required this.parentId,
    required this.labelCount,
    required this.isDeleted,
    required this.isPin,
    required this.labelIds,
    required this.shareId,
    required this.isPhysical,
    required this.length,
    required this.breadth,
    required this.height,
    required this.isFoodItem,
    required this.documentWith,
    required this.documentLocationJ,
    required this.workFlowName,
    required this.workFlowId,
    required this.workFlowStatus,
    required this.totalUserActions,
    required this.documentTypeId,
    required this.sourceId,
    required this.dmId,
    required this.cabinetId,
    required this.barcode,
    required this.prefix,
    required this.cabinetName,
    required this.cabinetNameAr,
    required this.yyyyMmDd,
    required this.positionX,
    required this.positionY,
    required this.templateData,
  });

  factory ArchiveDocumentDetailModel.fromJson(Map<String, dynamic> json) {
    return ArchiveDocumentDetailModel(
      documentId: json['DocumentId'] ?? 0,
      documentName: json['DocumentName'] ?? '',
      userName: json['UserName'] ?? '',
      createdDate: json['CreatedDateString'] ?? '',
      designationName: json['DesignationName'] ?? '',
      url: json['Url'] ?? '',
      isFavorite: json['IsFavorite'] ?? false,
      userActions: (json['UserActions'] as List? ?? [])
          .map((e) => UserAction.fromJson(e))
          .toList(),
      userList: (jsonDecode(json['UserListJson'] ?? '[]') as List)
          .map((e) => UserInfo.fromJson(e))
          .toList(),
      versions: (jsonDecode(json['VersionJson'] ?? '[]') as List)
          .map((e) => VersionInfo.fromJson(e))
          .toList(),
      status: json['Status'] ?? '',
      description: json['Description'] ?? '',
      displayName: json['DisplayName'] ?? '',
      sourceName: json['SourceName'] ?? '',
      documentTypeName: json['DocumentTypeName'] ?? '',
      dmName: json['DMName'] ?? '',
      subCategoryJson: json['SubCategoryJson'] ?? [],
      referenceJson: json['ReferenceJson'] ?? [],
      fileName: json['FileName'] ?? '',
      dateStatus: json['DateStatus'] ?? '',
      isFullAccess: json['IsFullAccess'] ?? false,
      versionName: json['VersionName'] ?? '',
      parentId: json['ParentId'] ?? 0,
      labelCount: json['LabelCount'] ?? 0,
      isDeleted: json['IsDeleted'] ?? false,
      isPin: json['IsPin'] ?? false,
      labelIds: json['LabelIds'] ?? '',
      shareId: json['ShareId'] ?? 0,
      isPhysical: json['IsPhysical'] ?? false,
      length: json['Length'] ?? 0,
      breadth: json['Breadth'] ?? 0,
      height: json['Height'] ?? 0,
      isFoodItem: json['IsFoodItem'] ?? false,
      documentWith: json['DocumentWith'] ?? '',
      documentLocationJ: json['DocumentLocationJ'] ?? [],
      workFlowName: json['WorkFlowName'] ?? '',
      workFlowId: json['WorkFlowId'] ?? 0,
      workFlowStatus: json['WorkFlowStatus'] ?? '',
      totalUserActions: json['TotalUserActions'] ?? 0,
      documentTypeId: json['DocumentTypeId'] ?? 0,
      sourceId: json['SourceId'] ?? 0,
      dmId: json['DMId'] ?? 0,
      cabinetId: json['CabinetId'] ?? 0,
      barcode: json['Barcode'] ?? '',
      prefix: json['Prefix'] ?? '',
      cabinetName: json['CabinetName'] ?? '',
      cabinetNameAr: json['CabinietName_Ar'] ?? '',
      yyyyMmDd: json['YYYYMMDD'] ?? '',
      positionX: json['PositionX'] ?? '',
      positionY: json['PositionY'] ?? '',
      templateData: jsonDecode(json['TemplateData'] ?? '{}') as Map<String, dynamic>,
    );
  }
}

class UserAction {
  final int actionId;
  final String status;
  final String receiverName;
  final String designation;

  UserAction({
    required this.actionId,
    required this.status,
    required this.receiverName,
    required this.designation,
  });

  factory UserAction.fromJson(Map<String, dynamic> json) {
    return UserAction(
      actionId: json['ActionId'] ?? 0,
      status: json['Status'] ?? '',
      receiverName: json['ReceiverName'] ?? '',
      designation: json['DesignationName'] ?? '',
    );
  }
}

class UserInfo {
  final String userName;
  final String designationName;
  final String companyName;
  final String email;
  final bool isActive;
  final int employeeId;
  final bool activeInArchive;
  final String status;
  final String departmentName;
  final bool isFullAccess;
  final bool isPermanent;
  final bool isPhysical;
  final String shareType;
  final String dateStatus;
  final String userInboxThumbnail;
  final String endDate;

  UserInfo({
    required this.userName,
    required this.designationName,
    required this.companyName,
    required this.email,
    required this.isActive,
    required this.employeeId,
    required this.activeInArchive,
    required this.status,
    required this.departmentName,
    required this.isFullAccess,
    required this.isPermanent,
    required this.isPhysical,
    required this.shareType,
    required this.dateStatus,
    required this.userInboxThumbnail,
    required this.endDate,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userName: json['UserName'] ?? '',
      designationName: json['DesignationName'] ?? '',
      companyName: json['CompanyName'] ?? '',
      email: json['Email'] ?? '',
      isActive: json['IsActive'] ?? false,
      employeeId: json['EmployeeId'] ?? 0,
      activeInArchive: json['ActiveInArchive'] ?? false,
      status: json['Status'] ?? '',
      departmentName: json['DepartmentName'] ?? '',
      isFullAccess: json['IsFullAccess'] ?? false,
      isPermanent: json['IsPermanent'] ?? false,
      isPhysical: json['IsPhysical'] ?? false,
      shareType: json['ShareType'] ?? '',
      dateStatus: json['DateStatus'] ?? '',
      userInboxThumbnail: json['UserInboxThumbnail'] ?? '',
      endDate: json['EndDate'] ?? '',
    );
  }
}

class VersionInfo {
  final int documentId;
  final int parentId;
  final String versionName;
  final int createdBy;
  final String documentName;
  final String status;
  final int shareId;

  VersionInfo({
    required this.documentId,
    required this.parentId,
    required this.versionName,
    required this.createdBy,
    required this.documentName,
    required this.status,
    required this.shareId,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      documentId: json['DocumentId'] ?? 0,
      parentId: json['ParentID'] ?? 0,
      versionName: json['VersionName'] ?? '',
      createdBy: json['CreatedBy'] ?? 0,
      documentName: json['DocumentName'] ?? '',
      status: json['Status'] ?? '',
      shareId: json['ShareId'] ?? 0,
    );
  }
}

class TemplateData {
  final double width;
  final double height;
  final String backgroundColor;
  final String borderColor;
  final double borderWidth;
  final double borderRadius;
  final List<Element> elements;

  TemplateData({
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.elements,
  });

  factory TemplateData.fromJson(Map<String, dynamic> json) {
    return TemplateData(
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      backgroundColor: json['backgroundColor'] ?? '#ffffff',
      borderColor: json['borderColor'] ?? '#000000',
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 0.0,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 0.0,
      elements: (json['elements'] as List? ?? [])
          .map((e) => Element.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Element {
  final int id;
  final String type;
  final String? text;
  final String? staticText;
  final String? renderedText;
  final String? placeholder;
  final String? fileUrl;
  final String? barcodeNumber;
  final double x;
  final double y;
  final double width;
  final double height;
  final String backgroundColor;
  final String fontColor;
  final String fontStyle;
  final String fontWeight;
  final double fontSize;
  final String valueType;

  Element({
    required this.id,
    required this.type,
    this.text,
    this.staticText,
    this.renderedText,
    this.placeholder,
    this.fileUrl,
    this.barcodeNumber,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.fontColor,
    required this.fontStyle,
    required this.fontWeight,
    required this.fontSize,
    required this.valueType,
  });

  factory Element.fromJson(Map<String, dynamic> json) {
    return Element(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      text: json['text'] ?? '',
      staticText: json['staticText'] ?? '',
      renderedText: json['renderedText'] ?? '',
      placeholder: json['placeholder'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      barcodeNumber: json['barcodeNumber'] ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      backgroundColor: json['backgroundColor'] ?? '#ffffff',
      fontColor: json['fontColor'] ?? '#000000',
      fontStyle: json['fontStyle'] ?? 'normal',
      fontWeight: json['fontWeight'] ?? 'normal',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 8.6,
      valueType: json['valueType'] ?? '',
    );
  }
}