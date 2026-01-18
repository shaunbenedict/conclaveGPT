import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rsvp_list_page.dart';
import 'webview_page.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;

  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E29),
      appBar: AppBar(
        title: const Text(
          'Event Details',
          style: TextStyle(color: Color(0xFF3BC1A8)),
        ),
        backgroundColor: const Color(0xFF061E29),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3BC1A8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .get(),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CupertinoActivityIndicator(color: Color(0xFF3BC1A8)),
            );
          }

          if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
            return const Center(
              child: Text(
                'Event not found',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final eventData = eventSnapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventData['name'] ?? 'Untitled Event',
                  style: const TextStyle(
                    color: Color(0xFF3BC1A8),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildEventDetailsCard(eventData),
                const SizedBox(height: 32),
                _buildRSVPCard(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(String label, dynamic value) {
    final text = value == null || (value is String && value.isEmpty)
        ? 'N/A'
        : value.toString();
    return Card(
      color: const Color(0xFF0C7779),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF3BC1A8), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF3BC1A8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailsCard(Map<String, dynamic> eventData) {
    return Card(
      color: const Color(0xFF0C7779),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF3BC1A8), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('What', eventData['what']),
            const Divider(color: Color(0xFF444444), height: 16),
            _buildDetailRow('Why', eventData['why']),
            const Divider(color: Color(0xFF444444), height: 16),
            _buildDetailRow('Who', eventData['who']),
            const Divider(color: Color(0xFF444444), height: 16),
            _buildDetailRow(
              'When',
              eventData['when'] != null
                  ? (eventData['when'] as Timestamp)
                        .toDate()
                        .toString()
                        .substring(0, 16)
                  : 'N/A',
            ),
            const Divider(color: Color(0xFF444444), height: 16),
            _buildDetailRow('Where', eventData['where']),
            const Divider(color: Color(0xFF444444), height: 16),
            _buildDetailRow('How much', eventData['howMuch'] ?? 'Free'),
            if (eventData['registrationUrl'] != null &&
                (eventData['registrationUrl'] as String).isNotEmpty) ...[
              const Divider(color: Color(0xFF444444), height: 16),
              _buildRegistrationRow(context, eventData['registrationUrl']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    final text = value == null || (value is String && value.isEmpty)
        ? 'N/A'
        : value.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF3BC1A8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildRegistrationRow(BuildContext context, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registration URL',
          style: TextStyle(
            color: Color(0xFF3BC1A8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                url,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WebViewPage(url: url, title: 'Registration URL'),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: const Text('View'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3BC1A8),
                foregroundColor: const Color(0xFF061E29),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRSVPSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CupertinoActivityIndicator(color: Color(0xFF3BC1A8)),
          );
        }

        if (!snapshot.hasData) {
          return const Text(
            'No RSVPs yet',
            style: TextStyle(color: Colors.grey),
          );
        }

        // Get list of users who have RSVP'd to this event
        final rsvpUsers = <Map<String, dynamic>>[];
        for (var userDoc in snapshot.data!.docs) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final events = userData['events'] as List<dynamic>? ?? [];
          if (events.contains(widget.eventId)) {
            // Get user auth info for email
            rsvpUsers.add({
              'id': userDoc.id,
              'name': userData['name'] ?? 'Unknown',
              'email':
                  userData['email'] ??
                  'No email', // Try to get from user doc first
            });
          }
        }

        if (rsvpUsers.isEmpty) {
          return const Text(
            'No RSVPs yet',
            style: TextStyle(color: Colors.grey),
          );
        }

        return _buildRSVPCard(context, rsvpUsers);
      },
    );
  }

  Widget _buildRSVPCard(
    BuildContext context, [
    List<Map<String, dynamic>>? rsvpUsers,
  ]) {
    if (rsvpUsers == null) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Card(
              color: const Color(0xFF0C7779),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF3BC1A8), width: 1),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CupertinoActivityIndicator(color: Color(0xFF3BC1A8)),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Card(
              color: const Color(0xFF0C7779),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF3BC1A8), width: 1),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No RSVPs yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          // Get list of users who have RSVP'd to this event
          final rsvpList = <Map<String, dynamic>>[];
          for (var userDoc in snapshot.data!.docs) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final events = userData['events'] as List<dynamic>? ?? [];
            if (events.contains(widget.eventId)) {
              rsvpList.add({
                'id': userDoc.id,
                'name': userData['name'] ?? 'Unknown',
                'email': userData['email'] ?? 'No email',
              });
            }
          }

          return _buildRSVPCardContent(context, rsvpList);
        },
      );
    }

    return _buildRSVPCardContent(context, rsvpUsers);
  }

  Widget _buildRSVPCardContent(
    BuildContext context,
    List<Map<String, dynamic>> rsvpUsers,
  ) {
    if (rsvpUsers.isEmpty) {
      return Card(
        color: const Color(0xFF0C7779),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF3BC1A8), width: 1),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No RSVPs yet', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Card(
      color: const Color(0xFF0C7779),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF3BC1A8), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total RSVPs',
                  style: TextStyle(
                    color: Color(0xFF3BC1A8),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${rsvpUsers.length}',
                  style: const TextStyle(
                    color: Color(0xFF3BC1A8),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF444444)),
            const SizedBox(height: 16),
            const Text(
              'Attendees',
              style: TextStyle(
                color: Color(0xFF3BC1A8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rsvpUsers.length > 3 ? 4 : rsvpUsers.length,
              itemBuilder: (context, index) {
                if (index == 3 && rsvpUsers.length > 3) {
                  // Show "View All" button
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RSVPListPage(
                            eventId: widget.eventId,
                            rsvpUsers: rsvpUsers,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          'View All (${rsvpUsers.length})',
                          style: const TextStyle(
                            color: Color(0xFF3BC1A8),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final user = rsvpUsers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF3BC1A8),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Color(0xFF061E29),
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
                              user['name'],
                              style: const TextStyle(
                                color: Color(0xFF3BC1A8),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user['email'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
