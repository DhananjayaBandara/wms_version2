import 'package:flutter/material.dart';

enum DateTimeType { date, time, dateTime }

class CustomDateTimePicker extends StatelessWidget {
  final String label;
  final DateTimeType type;
  final String dateTimeString;
  final Function(String) onChanged;
  final IconData icon; // New
  final bool isRequired; // New

  const CustomDateTimePicker({
    super.key,
    required this.label,
    required this.type,
    required this.dateTimeString,
    required this.onChanged,
    this.icon = Icons.calendar_today, // default icon
    this.isRequired = false,
  });

  String _formatDateTime() {
    if (dateTimeString.isEmpty) return '';
    
    try {
      if (type == DateTimeType.date) {
        // For display, show in a more readable format
        final parts = dateTimeString.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}'; // Show as DD/MM/YYYY for display
        }
        return dateTimeString;
      } else if (type == DateTimeType.time) {
        // For display, show in 12-hour format with AM/PM
        final parts = dateTimeString.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = parts[1];
          final period = hour < 12 ? 'AM' : 'PM';
          final displayHour = hour % 12 == 0 ? 12 : hour % 12;
          return '$displayHour:$minute $period';
        }
        return dateTimeString;
      }
      return dateTimeString;
    } catch (e) {
      return dateTimeString;
    }
  }

  void _pick(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    TimeOfDay currentTime = TimeOfDay.now();
    
    // Try to parse existing date/time if available
    if (dateTimeString.isNotEmpty) {
      if (type == DateTimeType.date || type == DateTimeType.dateTime) {
        try {
          final parts = dateTimeString.split('-');
          if (parts.length == 3) {
            currentDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        } catch (e) {
          print('Error parsing date: $e');
        }
      } else if (type == DateTimeType.time) {
        try {
          // Handle both HH:mm and HH:mm:ss formats
          final parts = dateTimeString.split(':');
          if (parts.length >= 2) {
            // Parse hours and minutes, ignore seconds if present
            currentTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        } catch (e) {
          print('Error parsing time: $e');
          // Fallback to current time if parsing fails
          currentTime = TimeOfDay.now();
        }
      }
    }

    if (type == DateTimeType.date || type == DateTimeType.dateTime) {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: currentDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      
      if (pickedDate != null) {
        if (type == DateTimeType.date) {
          // Format as YYYY-MM-DD for the backend
          final formattedDate = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
          onChanged(formattedDate);
        } else {
          // For date+time, show time picker after date is selected
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: currentTime,
          );
          if (pickedTime != null) {
            // Format as YYYY-MM-DD HH:mm:ss
            final formattedDateTime = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00';
            onChanged(formattedDateTime);
          }
        }
      }
    } else if (type == DateTimeType.time) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: currentTime,
      );
      
      if (pickedTime != null) {
        // Format as HH:mm:ss for time (with seconds set to 00)
        final formattedTime = '${pickedTime.hour.toString().padLeft(2, '0')}:'
                            '${pickedTime.minute.toString().padLeft(2, '0')}:00';
        onChanged(formattedTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: _formatDateTime()),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      validator:
          isRequired
              ? (value) => dateTimeString.isEmpty ? '$label is required' : null
              : null,
      onTap: () => _pick(context),
    );
  }
}
