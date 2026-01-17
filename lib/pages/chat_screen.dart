import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.user, this.createNew = false});

  final User? user;
  final bool createNew;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  late final GenerativeModel _model;
  String _currentChatId = 'default';

  // Build a short context string of upcoming events for Gemini
  Future<String> _buildEventsContext() async {
    if (widget.user == null) return 'There are no upcoming events.';

    try {
      // Get user's RSVP'd events
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .get();

      final userEvents = userDoc.data()?['events'] as List<dynamic>? ?? [];
      final rsvpdEventIds = Set<String>.from(
        userEvents.map((e) => e.toString()),
      );

      final snap = await FirebaseFirestore.instance
          .collection('events')
          .where(
            'when',
            isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
          )
          .orderBy('when')
          .limit(20)
          .get();

      if (snap.docs.isEmpty) return 'There are no upcoming events.';

      final parts = <String>[];
      for (final doc in snap.docs) {
        // Skip events user has already RSVP'd to
        if (rsvpdEventIds.contains(doc.id)) continue;

        final data = doc.data();
        final name = data['name'] ?? 'Untitled Event';
        final what = data['what'] ?? '';
        final whenTs = data['when'];
        final whenStr = whenTs is Timestamp
            ? whenTs.toDate().toIso8601String()
            : 'unscheduled';
        final whereStr = data['where'] ?? '';
        // Keep ID hidden from user but include it for internal extraction
        parts.add(
          '[INTERNAL_ID:${doc.id}] Name: $name; What: $what; When: $whenStr; Where: $whereStr',
        );
      }

      if (parts.isEmpty)
        return 'All upcoming events have been RSVP\'d to already.';
      return parts.join(' \n ');
    } catch (_) {
      return 'Events could not be loaded right now.';
    }
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats')
        .doc(_currentChatId)
        .collection('messages');
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3-flash-preview',
    );
    _loadOrCreateChat();
  }

  Future<void> _loadOrCreateChat() async {
    if (widget.user == null) return;

    // If createNew is true, always create a new chat
    if (widget.createNew) {
      await _createNewChat();
      return;
    }

    // Get the most recent chat
    try {
      final chatSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .collection('chats')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (chatSnap.docs.isNotEmpty) {
        setState(() {
          _currentChatId = chatSnap.docs.first.id;
        });
      } else {
        // Create first chat
        await _createNewChat();
      }
    } catch (_) {
      // If error, use default
    }
  }

  Future<void> _createNewChat() async {
    if (widget.user == null) return;

    try {
      final newChatRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .collection('chats')
          .add({
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessageAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _currentChatId = newChatRef.id;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New chat created'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create new chat')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (widget.user == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Clear the text field immediately
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    final messagesRef = _messagesRef(widget.user!.uid);

    try {
      await messagesRef.add({
        'text': text,
        'sender': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Generate response with Firebase AI (Gemini)
      String botText = '...';
      try {
        final eventsContext = await _buildEventsContext();
        final response = await _model.generateContent([
          Content.text('''
You are ConclaveGPT — a friendly, local-events companion.

Your goal is to help users discover nearby events they'll genuinely enjoy,
not to push random recommendations.

Conversation style:
- Talk casually and naturally, like a helpful friend.
- Be warm, short, and clear.
- Avoid sounding robotic or promotional.
- Do not overwhelm the user with long lists.
- Limit sentences to 2-5 per response.

Before recommending any event:
- Ask about the user's preferences if they are not clear.
- Examples: interests, budget, date, location, group size, language, or vibe.
- Ask only 1-2 simple questions at a time.

When recommending events:
- Recommend only events that clearly match the user's preferences.
- Mention the event name (include the [INTERNAL_ID:xxx] tag exactly as shown for each event).
- Briefly explain *why* it matches them.
- Suggest at most 3 events.
- DO NOT show the INTERNAL_ID to the user in your response text.

If no preference is known yet:
- Ask what kind of experience they're looking for before suggesting anything.

Available events:
$eventsContext

User message:
"$text"
'''),
        ]);
        botText = response.text?.trim().isNotEmpty == true
            ? response.text!.trim()
            : 'Sorry, I do not have a response right now.';
      } catch (e) {
        botText = 'Sorry, I had trouble generating a response.';
      }

      await messagesRef.add({
        'text': botText,
        'sender': 'bot',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1B1B1B),
        body: const Center(
          child: Text(
            'Please sign in to chat.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final messagesStream = _messagesRef(
      widget.user!.uid,
    ).orderBy('createdAt', descending: true).snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      appBar: AppBar(
        title: const Text('Chat', style: TextStyle(color: Color(0xFF00C853))),
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00C853)),
        actions: [
          TextButton(
            onPressed: _createNewChat,
            child: const Text(
              'New Chat',
              style: TextStyle(color: Color(0xFF00C853), fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Messages list
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CupertinoActivityIndicator(
                          color: Color(0xFF00C853),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet. Say hello!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      reverse: true,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final sender = data['sender'] as String? ?? 'bot';
                        final text = data['text'] as String? ?? '';
                        final eventId = sender == 'bot'
                            ? _extractEventId(text)
                            : null;
                        return _buildMessageBubble(
                          text: text,
                          isUser: sender == 'user',
                          eventId: eventId,
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Floating input
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2B2B),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF00C853),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const CupertinoActivityIndicator(
                                color: Color(0xFF00C853),
                              )
                            : const Icon(Icons.send, color: Color(0xFF00C853)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isUser,
    String? eventId,
  }) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF00C853) : const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(16),
        border: isUser
            ? null
            : Border.all(color: const Color(0xFF00C853), width: 1),
      ),
      child: _buildStyledText(text, isUser),
    );

    final rsvpButton = (eventId != null && eventId.isNotEmpty && !isUser)
        ? Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00C853),
                  side: const BorderSide(color: Color(0xFF00C853)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: () => _showEventDetailSheet(eventId),
                icon: const Icon(Icons.event_available, size: 18),
                label: const Text('RSVP'),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [bubble, rsvpButton],
      ),
    );
  }

  String? _extractEventId(String text) {
    // Looks for "[INTERNAL_ID:<alphanumeric>]" pattern provided in Gemini prompt context
    final match = RegExp(r'\[INTERNAL_ID:([A-Za-z0-9_-]+)\]').firstMatch(text);
    return match != null ? match.group(1) : null;
  }

  Future<void> _showEventDetailSheet(String eventId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      if (!snap.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Event not found.')));
        }
        return;
      }

      final data = snap.data() as Map<String, dynamic>;

      // Fetch organizer name
      String organizerName = 'Unknown';
      final organizerId = data['organizerId'];
      if (organizerId != null) {
        try {
          final organizerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(organizerId)
              .get();
          if (organizerDoc.exists) {
            organizerName = organizerDoc.data()?['name'] ?? 'Unknown';
          }
        } catch (_) {
          // Keep default name
        }
      }

      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Untitled Event',
                  style: const TextStyle(
                    color: Color(0xFF00C853),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _detailRow('Organizer', organizerName),
                _detailRow('What', data['what']),
                _detailRow('Why', data['why']),
                _detailRow('Who', data['who']),
                _detailRow('When', _formatWhen(data['when'])),
                _detailRow('Where', data['where']),
                _detailRow('How much', data['howMuch'] ?? 'Free'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[200],
                          side: const BorderSide(color: Color(0xFF00C853)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          await _rsvpToEvent(eventId);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: const Text('RSVP'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load event details.')),
        );
      }
    }
  }

  Future<void> _rsvpToEvent(String eventId) async {
    if (widget.user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .update({
            'events': FieldValue.arrayUnion([eventId]),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RSVPed to event $eventId'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to RSVP. Please try again.')),
        );
      }
    }
  }

  Widget _detailRow(String label, dynamic value) {
    final text = (value == null || (value is String && value.isEmpty))
        ? 'N/A'
        : value.toString();
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
                color: Color(0xFF00C853),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatWhen(dynamic when) {
    if (when is Timestamp) {
      return when.toDate().toString().substring(0, 16);
    }
    return 'N/A';
  }

  Widget _buildStyledText(String text, bool isUser) {
    final baseStyle = TextStyle(
      color: isUser ? Colors.black : Colors.white,
      fontSize: 15,
    );

    final spans = <TextSpan>[];
    // Supports *bold* and **bold** without rendering the asterisks
    final regex = RegExp(r'(\*\*|\*)(.+?)\1');
    int start = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}
