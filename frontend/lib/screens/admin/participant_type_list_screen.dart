import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/search_bar.dart';
import '../../template/create_screen.dart';
import '../../utils/list_utils.dart';
import '../../widgets/app_footer.dart';

class ParticipantTypeListScreen extends StatefulWidget {
  const ParticipantTypeListScreen({super.key});

  @override
  _ParticipantTypeListScreenState createState() =>
      _ParticipantTypeListScreenState();
}

class _ParticipantTypeListScreenState extends State<ParticipantTypeListScreen> {
  late Future<List<dynamic>> participantTypes;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    participantTypes = ApiService.getParticipantTypes();
  }

  void _refreshTypes() {
    setState(() {
      participantTypes = ApiService.getParticipantTypes();
    });
  }

  Future<void> _confirmDelete(int typeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Confirm Delete'),
            content: Text(
              'Are you sure you want to delete this participant type?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteParticipantType(typeId);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted successfully')));
        _refreshTypes();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete')));
      }
    }
  }

  void _navigateToEdit(Map<String, dynamic> participantType) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => EditParticipantTypeScreen(participantType: participantType),
      ),
    );
    if (updated != null) _refreshTypes();
  }

  void _navigateToAdd() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditParticipantTypeScreen(participantType: null),
      ),
    );
    if (added != null) _refreshTypes();
  }

  List<dynamic> _filterTypes(List<dynamic> types) {
    if (_searchQuery.isEmpty) return types;
    final query = _searchQuery.toLowerCase();
    return types
        .where(
          (t) =>
              (t['name'] ?? '').toLowerCase().contains(query) ||
              (t['description'] ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Participant Types'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _navigateToAdd,
            tooltip: 'Add Participant Type',
          ),
        ],
      ),
      body: Column(
        children: [
          ReusableSearchBar(
            hintText: 'Search participant types',
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: participantTypes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No participant types available.'));
                }

                final filtered = _filterTypes(snapshot.data!);
                final indexedTypes = indexListElements(
                  filtered,
                  valueKey: 'type',
                );

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: indexedTypes.length,
                  itemBuilder: (context, index) {
                    final type = indexedTypes[index]['type'];
                    final typeIndex = indexedTypes[index]['index'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ParticipantTypeDetailsScreen(
                                    participantType: type,
                                  ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.indigo.shade100,
                                child: Text(
                                  typeIndex.toString(),
                                  style: const TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _navigateToEdit(type),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _confirmDelete(type['id']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}

class EditParticipantTypeScreen extends StatelessWidget {
  final Map<String, dynamic>? participantType;

  const EditParticipantTypeScreen({super.key, this.participantType});

  @override
  Widget build(BuildContext context) {
    final bool isEdit = participantType != null;

    return CustomFormScreen(
      title: isEdit ? 'Edit Participant Type' : 'Add Participant Type',
      icon: Icons.groups_3,
      initialData: {
        'name': participantType?['name'] ?? '',
        'description': participantType?['description'] ?? '',
        'properties': participantType?['properties'] is Map
            ? (participantType?['properties'] as Map<String, dynamic>)
                .values
                .map((e) => e.toString())
                .toList()
            : (participantType?['properties'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      },
      submitButtonText: isEdit ? 'Update' : 'Create',
      fields: [
        FormFieldConfig(
          label: 'Name',
          icon: Icons.title,
          keyName: 'name',
          isRequired: true,
        ),
        FormFieldConfig(
          label: 'Description',
          icon: Icons.description,
          keyName: 'description',
        ),
        FormFieldConfig(
          label: 'Properties',
          icon: Icons.list,
          keyName: 'properties',
          fieldType: FieldType.custom,
          customBuilder: (context, formData, onChanged) {
            List<String> properties = [];
            if (formData['properties'] is List) {
              properties = List<String>.from(formData['properties'].map((x) => x?.toString() ?? ''));
            } else if (formData['properties'] is Map) {
              properties = List<String>.from(formData['properties'].values.map((x) => x?.toString() ?? ''));
            }

            void addProperty() {
              final updated = List<String>.from(properties)..add('');
              onChanged(updated);
            }

            void removeProperty(int index) {
              final updated = List<String>.from(properties)..removeAt(index);
              onChanged(updated);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Properties',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ...properties.asMap().entries.map((entry) {
                  int index = entry.key;
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: entry.value,
                          decoration: const InputDecoration(
                            labelText: 'Property',
                          ),
                          onChanged: (value) {
                            properties[index] = value;
                            onChanged(List.from(properties));
                          },
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Property cannot be empty'
                                      : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeProperty(index),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: addProperty,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Property'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade100,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            );
          },
        ),
      ],
      onSubmit: (formData) async {
        bool success;
        if (isEdit) {
          success = await ApiService.updateParticipantType(
            participantType!['id'],
            formData,
          );
        } else {
          success = await ApiService.createParticipantType(formData);
        }

        if (!success) {
          throw {
            'Error': ['Failed to save participant type.'],
          };
        }
      },
    );
  }
}

class ParticipantTypeDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> participantType;

  const ParticipantTypeDetailsScreen({
    super.key,
    required this.participantType,
  });

  @override
  State<ParticipantTypeDetailsScreen> createState() =>
      _ParticipantTypeDetailsScreenState();
}

class _ParticipantTypeDetailsScreenState
    extends State<ParticipantTypeDetailsScreen> {
  late Future<int> _participantCountFuture;

  @override
  void initState() {
    super.initState();
    _participantCountFuture = _getParticipantCount();
  }

  Future<int> _getParticipantCount() async {
    final allParticipants = await ApiService.getParticipants();
    final typeId = widget.participantType['id'];
    return allParticipants
        .where(
          (p) =>
              p['participant_type'] != null &&
              p['participant_type']['id'] == typeId,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final participantType = widget.participantType;
    final properties = participantType['properties'] is Map
        ? (participantType['properties'] as Map<String, dynamic>).values.toList()
        : List<dynamic>.from(participantType['properties'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(participantType['name'] ?? 'Participant Type Details'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Participant Type Info Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participantType['name'],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        participantType['description'],
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      // Show participant count using FutureBuilder
                      FutureBuilder<int>(
                        future: _participantCountFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text('Number of Users: ...');
                          } else if (snapshot.hasError) {
                            return Text('Number of Users: N/A');
                          } else {
                            return Text(
                              'Number of Users: ${snapshot.data}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade700,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Required Fields Section
              Text(
                'Required Fields',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade700,
                ),
              ),
              SizedBox(height: 10),
              properties.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'No properties available.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                  : Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: properties.length,
                        separatorBuilder: (context, index) => Divider(),
                        itemBuilder: (context, index) {
                          final property = properties[index];
                          String displayText = '';
                          
                          // Handle different property formats
                          if (property is String) {
                            displayText = property;
                          } else if (property is Map) {
                            // If property is a map, get the first value
                            displayText = property.values.first?.toString() ?? '';
                          } else {
                            // For any other type, try to convert to string
                            displayText = property?.toString() ?? '';
                          }
                          
                          return Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.blue.shade900,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  displayText.isNotEmpty 
                                    ? displayText.toUpperCase().replaceAll('_', ' ')
                                    : 'Empty property',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
