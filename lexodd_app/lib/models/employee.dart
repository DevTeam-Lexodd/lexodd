class Employee {
  final String? id;
  final String? employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? alternatePhone;
  final DateTime? dateOfBirth;
  final String gender;
  final String? bloodGroup;
  final String? maritalStatus;
  final String? profilePhoto;
  final Address? address;
  final Address? permanentAddress;
  final bool sameAsPermanent;
  final String department;
  final String designation;
  final DateTime? dateOfJoining;
  final String employmentType;
  final String? workLocation;
  final String? reportingManager;
  final double? ctc;
  final EmergencyContact? emergencyContact;
  final BankDetails? bankDetails;
  final DocumentDetails? documents;
  final List<Education>? education;
  final LeaveBalance? leaveBalance;
  final String? role;
  final bool isEmailVerified;
  final bool isActive;
  final String approvalStatus;
  final DateTime? approvalDate;
  final String? rejectionReason;

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  int? get age {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String get tenure {
    if (dateOfJoining == null) return 'N/A';
    final today = DateTime.now();
    int totalMonths = (today.year - dateOfJoining!.year) * 12 +
        (today.month - dateOfJoining!.month);
    int years = totalMonths ~/ 12;
    int months = totalMonths % 12;
    return years > 0 ? '$years yr $months mo' : '$months months';
  }

  Employee({
    this.id,
    this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.alternatePhone,
    this.dateOfBirth,
    required this.gender,
    this.bloodGroup,
    this.maritalStatus,
    this.profilePhoto,
    this.address,
    this.permanentAddress,
    this.sameAsPermanent = false,
    required this.department,
    required this.designation,
    this.dateOfJoining,
    required this.employmentType,
    this.workLocation,
    this.reportingManager,
    this.ctc,
    this.emergencyContact,
    this.bankDetails,
    this.documents,
    this.education,
    this.leaveBalance,
    this.role,
    this.isEmailVerified = false,
    this.isActive = true,
    this.approvalStatus = 'pending',
    this.approvalDate,
    this.rejectionReason,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] ?? json['id'],
      employeeId: json['employeeId'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      alternatePhone: json['alternatePhone'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      gender: json['gender'] ?? '',
      bloodGroup: json['bloodGroup'],
      maritalStatus: json['maritalStatus'],
      profilePhoto: json['profilePhoto'],
      address:
          json['address'] != null ? Address.fromJson(json['address']) : null,
      permanentAddress: json['permanentAddress'] != null
          ? Address.fromJson(json['permanentAddress'])
          : null,
      sameAsPermanent: json['sameAsPermanent'] ?? false,
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      dateOfJoining: json['dateOfJoining'] != null
          ? DateTime.tryParse(json['dateOfJoining'].toString())
          : null,
      employmentType: json['employmentType'] ?? '',
      workLocation: json['workLocation'],
      reportingManager: json['reportingManager'],
      ctc: json['ctc'] is num ? (json['ctc'] as num).toDouble() : null,
      emergencyContact: json['emergencyContact'] != null
          ? EmergencyContact.fromJson(json['emergencyContact'])
          : null,
      bankDetails: json['bankDetails'] != null
          ? BankDetails.fromJson(json['bankDetails'])
          : null,
      documents: json['documents'] != null
          ? DocumentDetails.fromJson(json['documents'])
          : null,
      education: json['education'] != null
          ? (json['education'] as List)
              .map((e) => Education.fromJson(e))
              .toList()
          : null,
      leaveBalance: json['leaveBalance'] != null
          ? LeaveBalance.fromJson(json['leaveBalance'])
          : null,
      role: json['role'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      approvalStatus: json['approvalStatus'] ?? 'pending',
      approvalDate: json['approvalDate'] != null
          ? DateTime.tryParse(json['approvalDate'].toString())
          : null,
      rejectionReason: json['rejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'bloodGroup': bloodGroup,
      'profilePhoto': profilePhoto,
      'maritalStatus': maritalStatus,
      'address': address?.toJson(),
      'permanentAddress': permanentAddress?.toJson(),
      'sameAsPermanent': sameAsPermanent,
      'department': department,
      'designation': designation,
      'dateOfJoining': dateOfJoining?.toIso8601String(),
      'employmentType': employmentType,
      'workLocation': workLocation,
      'reportingManager': reportingManager,
      'ctc': ctc,
      'emergencyContact': emergencyContact?.toJson(),
      'bankDetails': bankDetails?.toJson(),
      'documents': documents?.toJson(),
      'education': education?.map((e) => e.toJson()).toList(),
      'role': role,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'approvalStatus': approvalStatus,
      'approvalDate': approvalDate?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }
}

class Address {
  final String? street, city, state, pincode, country;
  Address({this.street, this.city, this.state, this.pincode, this.country});
  factory Address.fromJson(Map<String, dynamic> json) => Address(
        street: json['street'],
        city: json['city'],
        state: json['state'],
        pincode: json['pincode'],
        country: json['country'],
      );
  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'state': state,
        'pincode': pincode,
        'country': country,
      };
  String get fullAddress => [street, city, state, pincode, country]
      .where((e) => e != null && e.isNotEmpty)
      .join(', ');
}

class EmergencyContact {
  final String? name, relationship, phone;
  EmergencyContact({this.name, this.relationship, this.phone});
  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name'],
        relationship: json['relationship'],
        phone: json['phone'],
      );
  Map<String, dynamic> toJson() =>
      {'name': name, 'relationship': relationship, 'phone': phone};
}

class BankDetails {
  final String? accountNumber, bankName, branchName, ifscCode, accountType;
  BankDetails(
      {this.accountNumber,
      this.bankName,
      this.branchName,
      this.ifscCode,
      this.accountType});
  factory BankDetails.fromJson(Map<String, dynamic> json) => BankDetails(
        accountNumber: json['accountNumber'],
        bankName: json['bankName'],
        branchName: json['branchName'],
        ifscCode: json['ifscCode'],
        accountType: json['accountType'],
      );
  Map<String, dynamic> toJson() => {
        'accountNumber': accountNumber,
        'bankName': bankName,
        'branchName': branchName,
        'ifscCode': ifscCode,
        'accountType': accountType,
      };
}

class DocumentDetails {
  final String? aadharNumber, panNumber, passportNumber, drivingLicense;
  DocumentDetails(
      {this.aadharNumber,
      this.panNumber,
      this.passportNumber,
      this.drivingLicense});
  factory DocumentDetails.fromJson(Map<String, dynamic> json) =>
      DocumentDetails(
        aadharNumber: json['aadharNumber'],
        panNumber: json['panNumber'],
        passportNumber: json['passportNumber'],
        drivingLicense: json['drivingLicense'],
      );
  Map<String, dynamic> toJson() => {
        'aadharNumber': aadharNumber,
        'panNumber': panNumber,
        'passportNumber': passportNumber,
        'drivingLicense': drivingLicense,
      };
}

class Education {
  final String? degree, institution, university;
  final int? yearOfPassing;
  final double? percentage;
  Education(
      {this.degree,
      this.institution,
      this.university,
      this.yearOfPassing,
      this.percentage});
  factory Education.fromJson(Map<String, dynamic> json) => Education(
        degree: json['degree'],
        institution: json['institution'],
        university: json['university'],
        yearOfPassing: json['yearOfPassing'],
        percentage: json['percentage']?.toDouble(),
      );
  Map<String, dynamic> toJson() => {
        'degree': degree,
        'institution': institution,
        'university': university,
        'yearOfPassing': yearOfPassing,
        'percentage': percentage,
      };
}

class LeaveBalance {
  final double casual, sick, earned, maternity, paternity, compOff;
  LeaveBalance(
      {this.casual = 12,
      this.sick = 12,
      this.earned = 15,
      this.maternity = 0,
      this.paternity = 0,
      this.compOff = 0});
  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
        casual: (json['casual'] ?? 12).toDouble(),
        sick: (json['sick'] ?? 12).toDouble(),
        earned: (json['earned'] ?? 15).toDouble(),
        maternity: (json['maternity'] ?? 0).toDouble(),
        paternity: (json['paternity'] ?? 0).toDouble(),
        compOff: (json['compOff'] ?? 0).toDouble(),
      );
  double get total => casual + sick + earned + compOff;
}
