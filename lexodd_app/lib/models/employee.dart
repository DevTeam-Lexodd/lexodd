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
  final String? nationality;
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
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Computed
  String get fullName => '$firstName $lastName';
  
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
    final joining = dateOfJoining!;
    int totalMonths = (today.year - joining.year) * 12 + (today.month - joining.month);
    int years = totalMonths ~/ 12;
    int months = totalMonths % 12;
    if (years > 0) return '$years yr $months mo';
    return '$months months';
  }

  String get initials {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
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
    this.nationality,
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
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'],
      employeeId: json['employeeId'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      alternatePhone: json['alternatePhone'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      gender: json['gender'] ?? '',
      bloodGroup: json['bloodGroup'],
      maritalStatus: json['maritalStatus'],
      profilePhoto: json['profilePhoto'],
      nationality: json['nationality'],
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      permanentAddress: json['permanentAddress'] != null ? Address.fromJson(json['permanentAddress']) : null,
      sameAsPermanent: json['sameAsPermanent'] ?? false,
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      dateOfJoining: json['dateOfJoining'] != null ? DateTime.parse(json['dateOfJoining']) : null,
      employmentType: json['employmentType'] ?? '',
      workLocation: json['workLocation'],
      reportingManager: json['reportingManager'],
      ctc: json['ctc']?.toDouble(),
      emergencyContact: json['emergencyContact'] != null ? EmergencyContact.fromJson(json['emergencyContact']) : null,
      bankDetails: json['bankDetails'] != null ? BankDetails.fromJson(json['bankDetails']) : null,
      documents: json['documents'] != null ? DocumentDetails.fromJson(json['documents']) : null,
      education: json['education'] != null 
          ? (json['education'] as List).map((e) => Education.fromJson(e)).toList() 
          : null,
      leaveBalance: json['leaveBalance'] != null ? LeaveBalance.fromJson(json['leaveBalance']) : null,
      role: json['role'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
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
    };
  }

  Employee copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? department,
    String? designation,
  }) {
    return Employee(
      id: id,
      employeeId: employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth,
      gender: gender,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      dateOfJoining: dateOfJoining,
      employmentType: employmentType,
    );
  }
}

class Address {
  final String? street;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;

  Address({this.street, this.city, this.state, this.pincode, this.country});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
    };
  }

  String get fullAddress {
    List<String> parts = [];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (pincode != null && pincode!.isNotEmpty) parts.add(pincode!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }
}

class EmergencyContact {
  final String? name;
  final String? relationship;
  final String? phone;

  EmergencyContact({this.name, this.relationship, this.phone});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      relationship: json['relationship'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
    };
  }
}

class BankDetails {
  final String? accountNumber;
  final String? bankName;
  final String? branchName;
  final String? ifscCode;
  final String? accountType;

  BankDetails({this.accountNumber, this.bankName, this.branchName, this.ifscCode, this.accountType});

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      accountNumber: json['accountNumber'],
      bankName: json['bankName'],
      branchName: json['branchName'],
      ifscCode: json['ifscCode'],
      accountType: json['accountType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'bankName': bankName,
      'branchName': branchName,
      'ifscCode': ifscCode,
      'accountType': accountType,
    };
  }
}

class DocumentDetails {
  final String? aadharNumber;
  final String? panNumber;
  final String? passportNumber;
  final String? drivingLicense;

  DocumentDetails({this.aadharNumber, this.panNumber, this.passportNumber, this.drivingLicense});

  factory DocumentDetails.fromJson(Map<String, dynamic> json) {
    return DocumentDetails(
      aadharNumber: json['aadharNumber'],
      panNumber: json['panNumber'],
      passportNumber: json['passportNumber'],
      drivingLicense: json['drivingLicense'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aadharNumber': aadharNumber,
      'panNumber': panNumber,
      'passportNumber': passportNumber,
      'drivingLicense': drivingLicense,
    };
  }
}

class Education {
  final String? degree;
  final String? institution;
  final String? university;
  final int? yearOfPassing;
  final double? percentage;

  Education({this.degree, this.institution, this.university, this.yearOfPassing, this.percentage});

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      degree: json['degree'],
      institution: json['institution'],
      university: json['university'],
      yearOfPassing: json['yearOfPassing'],
      percentage: json['percentage']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'institution': institution,
      'university': university,
      'yearOfPassing': yearOfPassing,
      'percentage': percentage,
    };
  }
}

class LeaveBalance {
  final double casual;
  final double sick;
  final double earned;
  final double maternity;
  final double paternity;
  final double compOff;

  LeaveBalance({
    this.casual = 12,
    this.sick = 12,
    this.earned = 15,
    this.maternity = 0,
    this.paternity = 0,
    this.compOff = 0,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      casual: (json['casual'] ?? 12).toDouble(),
      sick: (json['sick'] ?? 12).toDouble(),
      earned: (json['earned'] ?? 15).toDouble(),
      maternity: (json['maternity'] ?? 0).toDouble(),
      paternity: (json['paternity'] ?? 0).toDouble(),
      compOff: (json['compOff'] ?? 0).toDouble(),
    );
  }

  double get total => casual + sick + earned + maternity + paternity + compOff;
}
