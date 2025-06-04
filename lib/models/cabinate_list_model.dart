class Cabinet {
  int? cabinetId;
  String? cabinetName;
  String? cabinietNameAr;
  int? archiveCount;

  Cabinet({this.cabinetId, this.cabinetName, this.cabinietNameAr, this.archiveCount});

  Cabinet.fromJson(Map<String, dynamic> json) {
    cabinetId = json['CabinetId'];
    cabinetName = json['CabinetName'];
    cabinietNameAr = json['CabinietName_Ar'];
    archiveCount = json['ArchiveCount'];
  }
}