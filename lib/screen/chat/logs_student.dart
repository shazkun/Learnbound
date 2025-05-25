import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learnbound/screen/home_screen.dart';
import 'package:learnbound/screen/log_screen.dart';
import 'package:path_provider/path_provider.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  _LogViewerScreenState createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  final Set<String> _selectedLogFiles = {};
  bool _isSelectionMode = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _searchController.addListener(_filterLogs);
  }

  Future<void> _loadLogs() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir
          .listSync()
          .where((file) =>
              file.path.endsWith('.json') && file.path.contains('sessionchat_'))
          .toList();

      final logs = <Map<String, dynamic>>[];
      for (final file in files) {
        final content = await File(file.path).readAsString();
        final log = jsonDecode(content) as Map<String, dynamic>;
        log['filePath'] = file.path; // Store file path for deletion
        logs.add(log);
      }

      logs.sort((a, b) => DateTime.parse(b['session']['start_time'])
          .compareTo(DateTime.parse(a['session']['start_time'])));

      setState(() {
        _logs = logs;
        _filteredLogs = logs;
      });
    } catch (e) {
      debugPrint('Error loading logs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load logs: $e')),
      );
    }
  }

  void _filterLogs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLogs = _logs.where((log) {
        final session = log['session'] as Map<String, dynamic>;
        final startTime = session['start_time']?.toString().toLowerCase() ?? '';
        final mode = session['mode']?.toString().toLowerCase() ?? '';
        final participants = (log['participants'] as List<dynamic>)
            .map((p) => p['nickname']?.toString().toLowerCase() ?? '')
            .join(' ');

        return startTime.contains(query) ||
            mode.contains(query) ||
            participants.contains(query);
      }).toList();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedLogFiles.clear();
      }
    });
  }

  void _toggleLogSelection(String filePath) {
    setState(() {
      if (_selectedLogFiles.contains(filePath)) {
        _selectedLogFiles.remove(filePath);
      } else {
        _selectedLogFiles.add(filePath);
      }
    });
  }

  Future<void> _deleteSelectedLogs() async {
    if (_selectedLogFiles.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white, // Dark grey dialog background
        title: const Text(
          'Delete Logs?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedLogFiles.length} log(s)?',
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

    if (confirmed == true) {
      try {
        for (final filePath in _selectedLogFiles) {
          await File(filePath).delete();
        }
        await _loadLogs(); // Refresh the list
        setState(() {
          _selectedLogFiles.clear();
          _isSelectionMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected logs deleted')),
        );
      } catch (e) {
        debugPrint('Error deleting logs: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete logs: $e')),
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
      backgroundColor: Colors.grey[200], // Grey background
      appBar: AppBar(
        backgroundColor: Colors.white, // Dark grey AppBar
        foregroundColor: Colors.black, // White icons and text
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
        centerTitle: true,
        title: Tooltip(
          message: 'View Session Logs',
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SessionLogScreen()),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.change_circle, color: Colors.black),
                SizedBox(width: 8), // spacing between icon and text
                Text(
                  'Student Logs',
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
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteSelectedLogs,
            ),
          IconButton(
            tooltip: 'Select delete',
            icon: Icon(_isSelectionMode ? Icons.close : Icons.select_all),
            onPressed: _toggleSelectionMode,
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
                hintText: 'Search by time, mode, or participant',
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      final session = log['session'] as Map<String, dynamic>;
                      final participants = (log['participants']
                              as List<dynamic>)
                          .map((p) => p['nickname']?.toString() ?? 'Unknown')
                          .join(', ');
                      final startTime =
                          DateTime.parse(session['start_time']).toLocal();
                      final filePath = log['filePath'] as String;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading: _isSelectionMode
                              ? Checkbox(
                                  value: _selectedLogFiles.contains(filePath),
                                  onChanged: (value) =>
                                      _toggleLogSelection(filePath),
                                  activeColor: Colors.grey[800],
                                )
                              : Icon(Icons.description,
                                  color: Colors.grey[600]),
                          title: Text(
                            'Session: ${session['mode']} (${startTime.toString().split('.')[0]})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Participants: $participants',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          onTap: _isSelectionMode
                              ? () => _toggleLogSelection(filePath)
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LogDetailsScreen(log: log),
                                    ),
                                  );
                                },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedLogFiles.add(filePath);
                              });
                            }
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
}

class LogDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> log;

  const LogDetailsScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final session = log['session'] as Map<String, dynamic>;
    final messages = log['messages'] as List<dynamic>;
    final questions = log['questions'] as List<dynamic>;
    final multipleChoiceQuestions =
        log['multiple_choice_questions'] as Map<String, dynamic>;
    final selectedAnswers = log['selected_answers'] as Map<String, dynamic>;
    final confirmedAnswers = log['confirmed_answers'] as List<dynamic>;
    DateTime startTime = DateTime.parse(log['session']['start_time']);
    return DefaultTabController(
      length: 7, // One tab for each section
      child: Scaffold(
        backgroundColor: Colors.grey[200], // Grey background
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white, // Dark grey AppBar
          foregroundColor: Colors.black, // White icons and text
          title: Text(
            'Session on ${DateFormat('MMM dd, yyyy').format(startTime)}',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey[400],
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Session'),
              Tab(text: 'Participants'),
              Tab(text: 'Messages'),
              Tab(text: 'Questions'),
              Tab(text: 'MC Questions'),
              Tab(text: 'Selected'),
              Tab(text: 'Confirmed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSessionInfo(session),
            _buildParticipants(log['participants'] as List<dynamic>),
            _buildMessages(messages),
            _buildQuestions(questions),
            _buildMultipleChoiceQuestions(multipleChoiceQuestions),
            _buildSelectedAnswers(selectedAnswers),
            _buildConfirmedAnswers(confirmedAnswers),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo(Map<String, dynamic> session) {
    final startTime = DateTime.parse(session['start_time']).toLocal();
    final endTime = DateTime.parse(session['end_time']).toLocal();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mode: ${session['mode']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start Time: ${formatter.format(startTime)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'End Time: ${formatter.format(endTime)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipants(List<dynamic> participants) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final participant = participants[index] as Map<String, dynamic>;
          final nickname = participant['nickname']?.toString() ?? 'Unknown';
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: Icon(Icons.person, color: Colors.grey[600]),
              title: Text(
                nickname,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessages(List<dynamic> messages) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index] as Map<String, dynamic>;
        final isSystem = message['system'] == true;
        final isImage = message['isImage'] == true;
        final isDrawing = message['isDrawing'] == true;
        final text = message['text']?.toString() ?? 'No content';
        final imagePath = message['image'];

        Widget? imageWidget;

        if (isImage && imagePath != null && File(imagePath).existsSync()) {
          imageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePath),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Text('Failed to load image'),
            ),
          );
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isImage
                          ? (isDrawing ? Icons.brush : Icons.image)
                          : (isSystem ? Icons.info : Icons.message),
                      color: isImage ? Colors.blue : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isImage
                            ? (isDrawing
                                ? 'Drawing by ${message['nickname'] ?? 'Unknown'}'
                                : 'Image Message')
                            : (isSystem ? 'System: $text' : text),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                if (imageWidget != null) ...[
                  const SizedBox(height: 12),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageWidget,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestions(List<dynamic> questions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: Icon(Icons.question_answer, color: Colors.grey[600]),
              title: Text(
                questions[index].toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMultipleChoiceQuestions(Map<String, dynamic> mcQuestions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mcQuestions.length,
        itemBuilder: (context, index) {
          final question = mcQuestions.keys.elementAt(index);
          final options = mcQuestions[question] as List<dynamic>;
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Icon(Icons.list, color: Colors.grey[600]),
              title: Text(
                question,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              children: options
                  .asMap()
                  .entries
                  .map((entry) => ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 32.0),
                        title: Text(
                          '${entry.key + 1}. ${entry.value}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        dense: true,
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedAnswers(Map<String, dynamic> selectedAnswers) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: selectedAnswers.length,
        itemBuilder: (context, index) {
          final question = selectedAnswers.keys.elementAt(index);
          final answer = selectedAnswers[question];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: Icon(Icons.check_circle, color: Colors.grey[600]),
              title: Text(
                question,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              subtitle: Text(
                'Selected: ${answer ?? 'None'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmedAnswers(List<dynamic> confirmedAnswers) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: confirmedAnswers.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: Icon(Icons.verified, color: Colors.grey[600]),
              title: Text(
                confirmedAnswers[index].toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
