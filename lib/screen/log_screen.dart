import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learnbound/screen/host/host_styles.dart';
import 'package:path_provider/path_provider.dart';

class SessionLogScreen extends StatefulWidget {
  const SessionLogScreen({super.key});

  @override
  _SessionLogScreenState createState() => _SessionLogScreenState();
}

class _SessionLogScreenState extends State<SessionLogScreen> {
  List<SessionLog> _logs = [];
  List<SessionLog> _filteredLogs = [];
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final Map<String, String> _logFilePaths = {}; // Map log ID to file path

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _searchController.addListener(_filterLogs);
  }

  Future<void> _loadLogs() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = await tempDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .toList();

      final logs = <SessionLog>[];
      _logFilePaths.clear();
      for (var file in files) {
        final content = await (file as File).readAsString();
        final json = jsonDecode(content);
        final log = SessionLog.fromJson(json);
        logs.add(log);
        _logFilePaths['${log.startTime.toIso8601String()}_${log.mode}'] =
            file.path;
      }

      logs.sort((a, b) => b.startTime.compareTo(a.startTime)); // Newest first
      setState(() {
        _logs = logs;
        _filteredLogs = logs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading logs: $e')),
      );
    }
  }

  void _filterLogs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLogs = _logs.where((log) {
        return log.mode.toLowerCase().contains(query) ||
            log.participants
                .any((p) => p.nickname.toLowerCase().contains(query)) ||
            log.stickyQuestions.any((q) => q.toLowerCase().contains(query));
      }).toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredLogs = _logs;
      }
    });
  }

  Future<void> _deleteLog(SessionLog log) async {
    final logId = '${log.startTime.toIso8601String()}_${log.mode}';
    final filePath = _logFilePaths[logId];
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Log file not found')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Session Log'),
        content: const Text(
            'Are you sure you want to delete this session log? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final file = File(filePath);
        await file.delete();
        await _loadLogs(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session log deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting log: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by mode, participant, or question',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : const Text('Session Logs'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppStyles.scaffoldGradient),
        child: _filteredLogs.isEmpty
            ? const Center(child: Text('No logs found'))
            : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _filteredLogs.length,
                itemBuilder: (context, index) {
                  final log = _filteredLogs[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        'Session on ${DateFormat('MMM dd, yyyy HH:mm').format(log.startTime)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text('Mode: ${log.mode}'),
                          Text('Participants: ${log.participants.length}'),
                          Text(
                              'Duration: ${_formatDuration(log.startTime, log.endTime)}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteLog(log),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SessionDetailScreen(log: log),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return hours > 0 ? '$hours h $minutes min' : '$minutes min';
  }
}

class SessionDetailScreen extends StatelessWidget {
  final SessionLog log;

  const SessionDetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              'Session on ${DateFormat('MMM dd, yyyy').format(log.startTime)}'),
          backgroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Messages'),
              Tab(text: 'Questions'),
              Tab(text: 'MC Responses'),
              Tab(text: 'Participants'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppStyles.scaffoldGradient),
          child: TabBarView(
            children: [
              _buildMessagesTab(),
              _buildQuestionsTab(),
              _buildMultipleChoiceTab(),
              _buildParticipantsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: log.messages.length,
      itemBuilder: (context, index) {
        final message = log.messages[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(
                '${message.nickname} (${DateFormat('HH:mm:ss').format(message.timestamp)})'),
            subtitle: message.isImage
                ? const Text('Image content (display not supported)')
                : Text(message.text ?? ""),
          ),
        );
      },
    );
  }

  Widget _buildQuestionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: log.stickyQuestions.length,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(log.stickyQuestions[index]),
          ),
        );
      },
    );
  }

  Widget _buildMultipleChoiceTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: log.multipleChoiceResponses.length,
      itemBuilder: (context, index) {
        final question = log.multipleChoiceResponses.keys.elementAt(index);
        final responses = log.multipleChoiceResponses[question]!;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...responses.entries.map(
                  (entry) => Text('${entry.key}: ${entry.value} votes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticipantsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: log.participants.length,
      itemBuilder: (context, index) {
        final participant = log.participants[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(participant.nickname),
            subtitle: Text(
                'Connected for ${participant.connectionDurationSeconds} seconds'),
          ),
        );
      },
    );
  }
}

class SessionLog {
  final DateTime startTime;
  final DateTime endTime;
  final String mode;
  final List<Message> messages;
  final List<String> stickyQuestions;
  final Map<String, Map<String, int>> multipleChoiceResponses;
  final List<Participant> participants;

  SessionLog({
    required this.startTime,
    required this.endTime,
    required this.mode,
    required this.messages,
    required this.stickyQuestions,
    required this.multipleChoiceResponses,
    required this.participants,
  });

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    final session = json['session'] as Map<String, dynamic>;
    return SessionLog(
      startTime: DateTime.parse(session['start_time']).toLocal(),
      endTime: DateTime.parse(session['end_time']).toLocal(),
      mode: session['mode'] as String,
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
      stickyQuestions: (json['sticky_questions'] as List).cast<String>(),
      multipleChoiceResponses: (json['multiple_choice_responses'] as Map).map(
          (key, value) => MapEntry(key, Map<String, int>.from(value as Map))),
      participants: (json['participants'] as List)
          .map((p) => Participant.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Message {
  final String nickname;
  final String? text;
  final String? image;
  final bool isImage;
  final DateTime timestamp;

  Message({
    required this.nickname,
    this.text,
    this.image,
    required this.isImage,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      nickname: json['nickname'] as String,
      text: json['text'] as String?,
      image: json['image'] as String?,
      isImage: json['is_image'] as bool,
      timestamp: DateTime.parse(json['timestamp']).toLocal(),
    );
  }
}

class Participant {
  final String nickname;
  final int connectionDurationSeconds;

  Participant({
    required this.nickname,
    required this.connectionDurationSeconds,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      nickname: json['nickname'] as String,
      connectionDurationSeconds: json['connection_duration_seconds'] as int,
    );
  }
}
