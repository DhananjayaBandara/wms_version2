import 'package:frontend/models/trainer.dart';
import 'package:frontend/models/workshop.dart';

class Session {
  final int id;
  final String location;
  final String date;
  final String time;
  final String targetAudience;
  final String status;
  final Workshop workshop;
  final List<Trainer> trainers;

  Session({
    required this.id,
    required this.location,
    required this.date,
    required this.time,
    required this.targetAudience,
    required this.status,
    required this.workshop,
    required this.trainers,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      location: json['location'],
      date: json['date'],
      time: json['time'],
      targetAudience: json['target_audience'],
      status: json['status'],
      workshop: Workshop.fromJson(json['workshop']),
      trainers:
          (json['trainers'] as List)
              .map((trainer) => Trainer.fromJson(trainer))
              .toList(),
    );
  }
}
