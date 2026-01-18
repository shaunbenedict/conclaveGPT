import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../main.dart';
import 'create_event_page.dart';
import 'chat_screen.dart';
import 'webview_page.dart';
import 'event_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _randomAvatar;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _randomAvatar = _getRandomAvatar();
  }

  String _getRandomAvatar() {
    final avatars = [
      'assets/simply_pfps/1.jpeg',
      'assets/simply_pfps/2.jpg',
      'assets/simply_pfps/3.jpg',
      'assets/simply_pfps/4.jpg',
      'assets/simply_pfps/5.jpg',
      'assets/simply_pfps/6.jpg',
      'assets/simply_pfps/7.jpg',
      'assets/simply_pfps/8.jpg',
      'assets/simply_pfps/9.jpg',
      'assets/simply_pfps/10.jpg',
    ];
    final random = Random();
    return avatars[random.nextInt(avatars.length)];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Conclave GPT',
          style: TextStyle(color: Color(0xFF3BC1A8)),
        ),
        backgroundColor: const Color(0xFF061E29),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF3BC1A8)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildHomePage(user)
          : _selectedIndex == 1
          ? _buildSecondPage(user)
          : _buildProfilePage(user),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0C7779),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF3BC1A8), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3BC1A8).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .get(),
            builder: (context, snapshot) {
              final userType = snapshot.hasData
                  ? (snapshot.data!.get('userType') ?? '')
                  : '';

              return CupertinoTabBar(
                backgroundColor: Colors.transparent,
                activeColor: const Color(0xFF3BC1A8),
                inactiveColor: Colors.grey,
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      userType == 'organizer'
                          ? CupertinoIcons.calendar
                          : CupertinoIcons.chat_bubble_text,
                    ),
                    label: userType == 'organizer' ? 'Events' : 'Chat',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person),
                    label: 'Profile',
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 2
          ? null
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final userType = snapshot.data!.get('userType') ?? '';

                if (userType != 'organizer') return const SizedBox.shrink();

                return FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateEventPage(),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF3BC1A8),
                  icon: const Icon(Icons.add, color: Colors.black, size: 28),
                  label: const Text(
                    'Event',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHomePage(User? user) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: const Color(0xFF0C7779),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF3BC1A8), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(_randomAvatar),
                    backgroundColor: const Color(0xFF3BC1A8),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .get(),
                      builder: (context, snapshot) {
                        String userName = 'User';
                        String userType = '';
                        if (snapshot.hasData && snapshot.data!.exists) {
                          userName = snapshot.data!.get('name') ?? 'User';
                          userType = snapshot.data!.get('userType') ?? '';
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Color(0xFF3BC1A8),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'No email',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            if (userType.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF3BC1A8,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF3BC1A8),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  userType == 'organizer'
                                      ? 'Organizer'
                                      : 'Participant',
                                  style: const TextStyle(
                                    color: Color(0xFF3BC1A8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final userType = userSnapshot.data!.get('userType') ?? '';

                if (userType != 'organizer') {
                  // Participant view - show RSVP'd events
                  List<String> eventIds = [];
                  try {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData != null && userData.containsKey('events')) {
                      eventIds = List<String>.from(userData['events'] ?? []);
                    }
                  } catch (e) {
                    // Field doesn't exist, keep eventIds empty
                    eventIds = [];
                  }

                  if (eventIds.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.event_busy,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No RSVP\'d events yet',
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check the Events tab to find events!',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming RSVP\'d Events',
                        style: TextStyle(
                          color: Color(0xFF3BC1A8),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: eventIds.length,
                          itemBuilder: (context, index) {
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(eventIds[index])
                                  .get(),
                              builder: (context, eventSnapshot) {
                                if (eventSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Card(
                                    color: Color(0xFF0C7779),
                                    margin: EdgeInsets.only(bottom: 16),
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CupertinoActivityIndicator(
                                          color: Color(0xFF3BC1A8),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                if (!eventSnapshot.hasData ||
                                    !eventSnapshot.data!.exists) {
                                  return const SizedBox.shrink();
                                }

                                final eventData =
                                    eventSnapshot.data!.data()
                                        as Map<String, dynamic>;

                                return Card(
                                  color: const Color(0xFF0C7779),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                      color: Color(0xFF3BC1A8),
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          eventData['name'] ?? 'Untitled Event',
                                          style: const TextStyle(
                                            color: Color(0xFF3BC1A8),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildEventDetail(
                                          'What',
                                          eventData['what'] ?? 'N/A',
                                        ),
                                        _buildEventDetail(
                                          'Why',
                                          eventData['why'] ?? 'N/A',
                                        ),
                                        _buildEventDetail(
                                          'Who',
                                          eventData['who'] ?? 'N/A',
                                        ),
                                        _buildEventDetail(
                                          'When',
                                          eventData['when'] != null
                                              ? (eventData['when'] as Timestamp)
                                                    .toDate()
                                                    .toString()
                                                    .substring(0, 16)
                                              : 'N/A',
                                        ),
                                        _buildEventDetail(
                                          'Where',
                                          eventData['where'] ?? 'N/A',
                                        ),
                                        _buildEventDetail(
                                          'How much',
                                          eventData['howMuch'] ?? 'Free',
                                        ),
                                        if (eventData['registrationUrl'] !=
                                                null &&
                                            (eventData['registrationUrl']
                                                    as String)
                                                .isNotEmpty)
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                              ),
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF3BC1A8,
                                                  ),
                                                  foregroundColor: Colors.black,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  minimumSize: Size.zero,
                                                ),
                                                onPressed: () async {
                                                  final url =
                                                      eventData['registrationUrl'];
                                                  final eventName =
                                                      eventData['name'] ??
                                                      'Event Registration';
                                                  if (context.mounted) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            WebViewPage(
                                                              url: url,
                                                              title: eventName,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.link,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'Register',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Upcoming Events',
                      style: TextStyle(
                        color: Color(0xFF3BC1A8),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('events')
                            .where('organizerId', isEqualTo: user?.uid)
                            .where(
                              'when',
                              isGreaterThanOrEqualTo: Timestamp.fromDate(
                                DateTime.now(),
                              ),
                            )
                            .orderBy('when')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CupertinoActivityIndicator(
                                color: Color(0xFF3BC1A8),
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.event_busy,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No upcoming events',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tap the + button to create one!',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final event = snapshot.data!.docs[index];
                              final eventData =
                                  event.data() as Map<String, dynamic>;

                              return Card(
                                color: const Color(0xFF0C7779),
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                    color: Color(0xFF3BC1A8),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        eventData['name'] ?? 'Untitled Event',
                                        style: const TextStyle(
                                          color: Color(0xFF3BC1A8),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildEventDetail(
                                        'What',
                                        eventData['what'] ?? 'N/A',
                                      ),
                                      _buildEventDetail(
                                        'Why',
                                        eventData['why'] ?? 'N/A',
                                      ),
                                      _buildEventDetail(
                                        'Who',
                                        eventData['who'] ?? 'N/A',
                                      ),
                                      _buildEventDetail(
                                        'When',
                                        eventData['when'] != null
                                            ? (eventData['when'] as Timestamp)
                                                  .toDate()
                                                  .toString()
                                                  .substring(0, 16)
                                            : 'N/A',
                                      ),
                                      _buildEventDetail(
                                        'Where',
                                        eventData['where'] ?? 'N/A',
                                      ),
                                      _buildEventDetail(
                                        'How much',
                                        eventData['howMuch'] ?? 'Free',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondPage(User? user) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CupertinoActivityIndicator(color: Color(0xFF3BC1A8)),
          );
        }

        final userType = snapshot.data!.get('userType') ?? '';

        if (userType == 'organizer') {
          // Events page for organizers
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Events',
                  style: TextStyle(
                    color: Color(0xFF3BC1A8),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .where('organizerId', isEqualTo: user?.uid)
                        .where(
                          'when',
                          isGreaterThanOrEqualTo: Timestamp.fromDate(
                            DateTime.now(),
                          ),
                        )
                        .orderBy('when')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CupertinoActivityIndicator(
                            color: Color(0xFF3BC1A8),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.event_busy,
                                size: 80,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No upcoming events',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap the + button to create one!',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final eventDoc = snapshot.data!.docs[index];
                          final eventData =
                              eventDoc.data() as Map<String, dynamic>;

                          return Card(
                            color: const Color(0xFF0C7779),
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: Color(0xFF3BC1A8),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              title: Text(
                                eventData['name'] ?? 'Untitled Event',
                                style: const TextStyle(
                                  color: Color(0xFF3BC1A8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  eventData['when'] != null
                                      ? (eventData['when'] as Timestamp)
                                            .toDate()
                                            .toString()
                                            .substring(0, 16)
                                      : 'Unscheduled',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF3BC1A8),
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EventDetailsPage(eventId: eventDoc.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        } else {
          // Chat page for participants - show list of chats
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Chats',
                      style: TextStyle(
                        color: Color(0xFF3BC1A8),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(user: user, createNew: true),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF3BC1A8),
                      ),
                      label: const Text(
                        'New',
                        style: TextStyle(color: Color(0xFF3BC1A8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('chats')
                        .orderBy('lastMessageAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CupertinoActivityIndicator(
                            color: Color(0xFF3BC1A8),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.chat_bubble_text_fill,
                                size: 80,
                                color: Color(0xFF3BC1A8),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Start chatting with ConclaveGPT',
                                style: TextStyle(
                                  color: Color(0xFF3BC1A8),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3BC1A8),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        user: user,
                                        createNew: true,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'New Chat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final chatDoc = snapshot.data!.docs[index];
                          final chatId = chatDoc.id;

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user?.uid)
                                .collection('chats')
                                .doc(chatId)
                                .collection('messages')
                                .orderBy('createdAt', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, messagesSnapshot) {
                              String title = 'New Chat';
                              String subtitle = 'No messages yet';

                              if (messagesSnapshot.hasData &&
                                  messagesSnapshot.data!.docs.isNotEmpty) {
                                // Get last message
                                final lastMessage =
                                    messagesSnapshot.data!.docs.first;
                                final lastMessageData =
                                    lastMessage.data() as Map<String, dynamic>;
                                subtitle = lastMessageData['text'] ?? '';

                                // Look for event name in bot messages
                                for (var msg in messagesSnapshot.data!.docs) {
                                  final msgData =
                                      msg.data() as Map<String, dynamic>;
                                  if (msgData['sender'] == 'bot') {
                                    final text = msgData['text'] ?? '';
                                    // Extract event name from message
                                    final eventNameMatch = RegExp(
                                      r'\*\*([^*]+)\*\*',
                                    ).firstMatch(text);
                                    if (eventNameMatch != null) {
                                      title =
                                          '${eventNameMatch.group(1)} Event';
                                      break;
                                    }
                                  }
                                }
                              }

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
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFF3BC1A8),
                                    child: Icon(
                                      CupertinoIcons.chat_bubble_text,
                                      color: Colors.black,
                                    ),
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Color(0xFF3BC1A8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      subtitle,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Color(0xFF3BC1A8),
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ChatScreen(user: user),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildProfilePage(User? user) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CupertinoActivityIndicator(color: Color(0xFF3BC1A8)),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'Unable to load profile',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final name = userData['name'] ?? 'User';
            final email = user?.email ?? 'No email';
            final dob = userData['dob'] ?? 'Not provided';
            final userType = userData['userType'] ?? '';
            final userEvents = userData['events'] as List<dynamic>? ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: AssetImage(_randomAvatar),
                            backgroundColor: const Color(0xFF3BC1A8),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Color(0xFF3BC1A8),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (userType.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3BC1A8).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF3BC1A8),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                userType == 'organizer'
                                    ? 'Organizer'
                                    : 'Participant',
                                style: const TextStyle(
                                  color: Color(0xFF3BC1A8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Leaderboard badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF3BC1A8),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${userEvents.length} 🏆',
                        style: const TextStyle(
                          color: Color(0xFF3BC1A8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: Card(
                    color: const Color(0xFF0C7779),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Color(0xFF3BC1A8),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileField('Email', email),
                          const SizedBox(height: 16),
                          _buildProfileField('Date of Birth', dob),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    'Made with ❤️ by CodeBlooded',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Column(
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
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _buildEventDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFF3BC1A8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
