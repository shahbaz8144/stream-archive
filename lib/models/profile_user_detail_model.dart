class UserDetail {
  final int userId;
  final String displayName;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String telephone1;
  final String telephone2;
  final String phone;
  final String address;
  final int employeeCode;
  final String city;
  final String country;
  final String companyName;
  final String departmentName;
  final String roleName;
  final String userName;
  final String reportingUserName;
  final String signature;
  final String userProfile;
  final String day;
  final bool userIsActive;
  final String designationName;
  final int emplyeeCode;

  UserDetail({
    required this.userId,
    required this.displayName,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.telephone1,
    required this.telephone2,
    required this.phone,
    required this.address,
    required this.employeeCode,
    required this.city,
    required this.country,
    required this.companyName,
    required this.departmentName,
    required this.roleName,
    required this.userName,
    required this.reportingUserName,
    required this.signature,
    required this.userProfile,
    required this.day,
    required this.userIsActive,
    required this.designationName,
    required this.emplyeeCode,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
        userId: json['userId'] ?? 0, // Default value if null
        displayName: json['DisplayName'] ?? '', // Default to empty string
        firstName: json['FirstName'] ?? '', // Default to empty string
        middleName: json['MiddleName'] ?? '', // Default to empty string
        lastName: json['LastName'] ?? '', // Default to empty string
        email: json['Email'] ?? '', // Default to empty string
        telephone1: json['Telephone1'] ?? '', // Default to empty string
        telephone2: json['Telephone2'] ?? '', // Default to empty string
        phone: json['Phone'] ?? '', // Default to empty string
        address: json['Address'] ?? '', // Default to empty string
        employeeCode: json['EmployeeCode'] ?? 0, // Default value if null
        city: json['City'] ?? '', // Default to empty string
        country: json['Country'] ?? '', // Default to empty string
        companyName: json['CompanyName'] ?? '', // Default to empty string
        departmentName: json['DepartmentName'] ?? '', // Default to empty string
        roleName: json['RoleName'] ?? '', // Default to empty string
        userName: json['UserName'] ?? '', // Default to empty string
        reportingUserName: json['ReportingUserName'] ?? '', // Default to empty string
        signature: json['Signature'] ?? '', // Default to empty string
        userProfile: json['UserProfile'] ?? '', // Default to empty string
        day: json['Day'] ?? '', // Default to empty string
        userIsActive: json['UserIsActive'] ?? false, // Default to false if null
        designationName: json['DesignationName'] ?? '', // Default to empty string
        emplyeeCode: json['EmployeeCode'] ?? 0
    );
  }
}
