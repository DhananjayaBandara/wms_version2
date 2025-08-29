import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import '../../template/create_screen.dart';
import 'create_trainer_credential_screen.dart';

class CreateTrainerScreen extends StatelessWidget {
  const CreateTrainerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomFormScreen(
      title: 'Create Trainer',
      icon: Icons.person_add_alt_1,
      submitButtonText: 'Create Trainer',
      initialData: {
        'name': '',
        'designation': '',
        'email': '',
        'contact_number': '',
        'expertise': '',
      },
      fields: [
        FormFieldConfig(
          label: 'Name',
          icon: Icons.person,
          keyName: 'name',
          isRequired: true,
        ),
        FormFieldConfig(
          label: 'Designation',
          icon: Icons.work,
          keyName: 'designation',
        ),
        FormFieldConfig(
          label: 'Email',
          icon: Icons.email,
          keyName: 'email',
          isRequired: true,
        ),
        FormFieldConfig(
          label: 'Contact Number',
          icon: Icons.phone,
          keyName: 'contact_number',
          isRequired: true,
        ),
        FormFieldConfig(
          label: 'Expertise',
          icon: Icons.school,
          keyName: 'expertise',
        ),
      ],
      onSubmit: (formData) async {
        try {
          final trainerId = await ApiService.createTrainerAndReturnId(formData);
          if (trainerId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Trainer created successfully! Now create credentials.',
                ),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => CreateTrainerCredentialScreen(trainerId: trainerId),
              ),
            );
          } else {
            throw {
              'Error': ['Failed to create trainer.'],
            };
          }
        } catch (e) {
          throw {
            'Error': ['Failed to create trainer.'],
          };
        }
      },
    );
  }
}
