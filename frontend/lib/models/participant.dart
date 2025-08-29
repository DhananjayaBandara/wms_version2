class Participant {
  int? id;
  String name;
  String email;
  String contactNumber;
  String nic;
  String district;
  String gender;
  int participantTypeId;
  Map<String, dynamic> properties;

  Participant({
    this.id,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.nic,
    required this.district,
    required this.gender,
    required this.participantTypeId,
    required this.properties,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      contactNumber: json['contact_number'],
      nic: json['nic'],
      district: json['district'],
      gender: json['gender'],
      participantTypeId:
          json['participant_type_id'] ?? json['participant_type']?['id'],
      properties: json['properties'] ?? {},
    );
  }

  Map<String, dynamic> toJson({String? password}) {
    final data = {
      'name': name,
      'email': email,
      'contact_number': contactNumber,
      'nic': nic,
      'district': district,
      'gender': gender,
      'participant_type_id': participantTypeId,
      'properties': properties,
    };
    if (password != null) {
      data['password'] = password;
    }
    return data;
  }
}
