import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/search_bar.dart';
import 'participant_details_screen.dart';
import '../../utils/list_utils.dart';
import '../../widgets/app_footer.dart';

class ParticipantListScreen extends StatefulWidget {
  const ParticipantListScreen({super.key});

  @override
  _ParticipantListScreenState createState() => _ParticipantListScreenState();
}

class _ParticipantListScreenState extends State<ParticipantListScreen> {
  late Future<List<dynamic>> participants;
  List<dynamic> _participantTypes = [];
  String _selectedTypeId = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    participants = ApiService.getParticipants();
    _fetchParticipantTypes();
  }

  Future<void> _fetchParticipantTypes() async {
    final types = await ApiService.getParticipantTypes();
    setState(() {
      _participantTypes = types;
    });
  }

  List<dynamic> _filterParticipants(List<dynamic> all) {
    List<dynamic> filtered = all;
    if (_selectedTypeId.isNotEmpty) {
      filtered =
          filtered.where((p) {
            final type = p['participant_type'];
            final typeId =
                type != null && type['id'] != null ? type['id'].toString() : '';
            return typeId == _selectedTypeId;
          }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((p) {
            return (p['name'] ?? '').toLowerCase().contains(query) ||
                (p['email'] ?? '').toLowerCase().contains(query) ||
                (p['nic'] ?? '').toLowerCase().contains(query);
          }).toList();
    }
    return filtered;
  }

  Future<void> _confirmDelete(int participantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Participant'),
            content: Text('Are you sure you want to delete this participant?'),
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

    if (confirmed == true) {
      final success = await ApiService.deleteParticipant(participantId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Participant deleted successfully!')),
        );
        _refreshParticipants();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete participant!')),
        );
      }
    }
  }

  void _navigateToDetails(Map<String, dynamic> participant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ParticipantDetailsScreen(participant: participant),
      ),
    );
  }

  void _refreshParticipants() {
    setState(() {
      participants = ApiService.getParticipants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Participants')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Search bar takes 2/3 of the row
                Expanded(
                  flex: 2,
                  child: ReusableSearchBar(
                    hintText: 'Search participants',
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                // Dropdown takes 1/3 of the row
                Expanded(
                  flex: 1,
                  child:
                      _participantTypes.isEmpty
                          ? Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                            value: _selectedTypeId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: '',
                                child: Text('All Types'),
                              ),
                              ..._participantTypes
                                  .map<DropdownMenuItem<String>>((type) {
                                    return DropdownMenuItem(
                                      value: type['id'].toString(),
                                      child: Text(type['name']),
                                    );
                                  }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedTypeId = val ?? '';
                              });
                            },
                          ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: participants,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No participants available.'));
                } else {
                  final filtered = _filterParticipants(snapshot.data!);
                  final indexedParticipants = indexListElements(
                    filtered,
                    valueKey: 'participant',
                  );

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: indexedParticipants.length,
                    itemBuilder: (context, index) {
                      final participant =
                          indexedParticipants[index]['participant'];
                      final participantIndex =
                          indexedParticipants[index]['index'];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Text(
                              participantIndex.toString(),
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            participant['name'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Email: ${participant['email'] ?? 'N/A'}\nNIC: ${participant['nic'] ?? 'N/A'}',
                          ),
                          isThreeLine: true,
                          onTap: () => _navigateToDetails(participant),
                          trailing: SizedBox(
                            width: 80,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Delete Participant',
                                  onPressed:
                                      () => _confirmDelete(participant['id']),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
