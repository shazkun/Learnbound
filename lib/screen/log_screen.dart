import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learnbound/screen/chat/logs_student.dart';
import 'package:learnbound/screen/host/host_styles.dart';
import 'package:learnbound/util/design/colors.dart';
import 'package:learnbound/util/design/snackbar.dart';
import 'package:path_provider/path_provider.dart';

class SessionLogScreen extends StatefulWidget {
  const SessionLogScreen({super.key});

  @override
  _SessionLogScreenState createState() => _SessionLogScreenState();
}

class _SessionLogScreenState extends State<SessionLogScreen> {
  List<SessionLog> _logs = [];
  List<SessionLog> _filteredLogs = [];
  bool _isSelecting = false;
  final Set<String> _selectedLogIds = {};
  final _searchController = TextEditingController();
  final Map<String, String> _logFilePaths = {};

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
          .where((entity) =>
              entity is File &&
              entity.path.endsWith('.json') &&
              entity.path.contains('sessionhost'))
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

      logs.sort((a, b) => b.startTime.compareTo(a.startTime));
      setState(() {
        _logs = logs;
        _filteredLogs = logs;
        _selectedLogIds.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading logs: $e'),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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

  void _toggleSelectMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      if (!_isSelecting) {
        _selectedLogIds.clear();
      }
    });
  }

  void _toggleLogSelection(SessionLog log) {
    final logId = '${log.startTime.toIso8601String()}_${log.mode}';
    setState(() {
      if (_selectedLogIds.contains(logId)) {
        _selectedLogIds.remove(logId);
      } else {
        _selectedLogIds.add(logId);
      }
    });
  }

  Future<void> _deleteSelectedLogs() async {
    if (_selectedLogIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No logs selected'),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: const Text(
          'Delete Selected Logs',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedLogIds.length} selected session log(s)? This action cannot be undone.',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        for (var logId in _selectedLogIds.toList()) {
          final filePath = _logFilePaths[logId];
          if (filePath != null) {
            final file = File(filePath);
            await file.delete();
          }
        }
        await _loadLogs();
        setState(() {
          _isSelecting = false;
          _selectedLogIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedLogIds.length} session log(s) deleted'),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting logs: $e'),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: _isSelecting
            ? Text(
                '${_selectedLogIds.length} Selected',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )
            : Tooltip(
                message: 'Join (Students log)',
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LogViewerScreen()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.change_circle, color: Colors.black),
                      SizedBox(width: 8), // spacing between icon and text
                      Text(
                        'Session Logs',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          if (_isSelecting)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteSelectedLogs,
            ),
          IconButton(
            tooltip: 'Select delete',
            icon: const Icon(Icons.select_all),
            onPressed: () {
              if (_logs.isNotEmpty) {
                _toggleSelectMode();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Logs is empty'),
                    backgroundColor: Colors.grey[800],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by mode, participant, or question',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[500]!),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredLogs.isEmpty
                ? Center(
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No logs found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      final logId =
                          '${log.startTime.toIso8601String()}_${log.mode}';
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading: _isSelecting
                              ? Checkbox(
                                  value: _selectedLogIds.contains(logId),
                                  onChanged: (value) =>
                                      _toggleLogSelection(log),
                                  activeColor: Colors.grey[800],
                                )
                              : Icon(Icons.description,
                                  color: Colors.grey[600]),
                          title: Text(
                            'Session on ${DateFormat('MMM dd, yyyy HH:mm').format(log.startTime)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Mode: ${log.mode}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Participants: ${log.participants.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Duration: ${_formatDuration(log.startTime, log.endTime)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          onTap: _isSelecting
                              ? () => _toggleLogSelection(log)
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SessionDetailScreen(log: log),
                                    ),
                                  );
                                },
                        ),
                      );
                    },
                  ),
          ),
        ],
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
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          centerTitle: true,
          title: Text(
            'Session on ${DateFormat('MMM dd, yyyy').format(log.startTime)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey[400],
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Messages'),
              Tab(text: 'Questions'),
              Tab(text: 'MC Responses'),
              Tab(text: 'Participants'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMessagesTab(),
            _buildQuestionsTab(),
            _buildMultipleChoiceTab(),
            _buildParticipantsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: log.messages.length,
      itemBuilder: (context, index) {
        final message = log.messages[index];
        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      message.isImage ? Icons.image : Icons.message,
                      color: message.isImage ? Colors.blue : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${message.nickname} (${DateFormat('HH:mm:ss').format(message.timestamp)})',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (message.isImage && message.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(message.image!),
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.low,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Text(
                        'Error loading image',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    message.text ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: log.stickyQuestions.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: Icon(Icons.question_answer, color: Colors.grey[600]),
            title: Text(
              log.stickyQuestions[index],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMultipleChoiceTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: log.multipleChoiceResponses.length,
      itemBuilder: (context, index) {
        final question = log.multipleChoiceResponses.keys.elementAt(index);
        final responses = log.multipleChoiceResponses[question]!;
        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                ...responses.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '${entry.key}: ${entry.value} votes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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
  }

  Widget _buildParticipantsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: log.participants.length,
      itemBuilder: (context, index) {
        final participant = log.participants[index];
        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: Icon(Icons.person, color: Colors.grey[600]),
            title: Text(
              participant.nickname,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            subtitle: Text(
              'Connected for ${participant.connectionDurationSeconds} seconds',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
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
      isImage: json['isImage'] as bool? ?? false,
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
