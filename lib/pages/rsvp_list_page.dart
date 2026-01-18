import 'package:flutter/material.dart';

class RSVPListPage extends StatelessWidget {
  final String eventId;
  final List<Map<String, dynamic>> rsvpUsers;

  const RSVPListPage({
    super.key,
    required this.eventId,
    required this.rsvpUsers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E29),
      appBar: AppBar(
        title: const Text(
          'All RSVPs',
          style: TextStyle(color: Color(0xFF3BC1A8)),
        ),
        backgroundColor: const Color(0xFF061E29),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3BC1A8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total RSVPs: ${rsvpUsers.length}',
              style: const TextStyle(
                color: Color(0xFF3BC1A8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: rsvpUsers.length,
                itemBuilder: (context, index) {
                  final user = rsvpUsers[index];
                  return Card(
                    color: const Color(0xFF0C7779),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFF3BC1A8),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF3BC1A8),
                                child: Text(
                                  (index + 1).toString(),
                                  style: const TextStyle(
                                    color: Colors.black,
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
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user['email'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
