import 'package:flutter/material.dart';
import 'package:learnbound/screen/home_screen.dart';

class StatisticsScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final String timeTaken;

  const StatisticsScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.timeTaken,
  });

  @override
  Widget build(BuildContext context) {
    // Validate inputs
    final validatedScore = score.clamp(0, totalQuestions);
    final percentage = totalQuestions > 0
        ? (validatedScore / totalQuestions * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Statistics'),
        backgroundColor: Color(0xFFD7C19C),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white],
          ),
        ),
        // Use theme-based padding for adaptability
        padding: EdgeInsets.all(Theme.of(context).padding.primary),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Congratulations!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8), // Minimal spacing

            // Score Card
            _buildScoreCard(
              context,
              validatedScore,
              totalQuestions,
              percentage,
              timeTaken,
            ),
            const SizedBox(height: 16), // Moderate spacing

            // Back to Quiz Button

            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    ), // Assuming Exit should go back
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: Theme.of(context).textTheme.labelLarge,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 6,
                    ),
                    child: const Text(
                      'Exit',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 16), // spacing between buttons
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: Theme.of(context).textTheme.labelLarge,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 6,
                    ),
                    child: const Text(
                      'Review',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(
    BuildContext context,
    int score,
    int totalQuestions,
    String percentage,
    String timeTaken,
  ) {
    return Card(
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(Theme.of(context).padding.primary),
        child: Column(
          children: [
            Text(
              'Score: $score/$totalQuestions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
              semanticsLabel: 'Score: $score out of $totalQuestions',
            ),
            const SizedBox(height: 8),
            Text(
              'Percentage: $percentage%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
              semanticsLabel: 'Percentage: $percentage percent',
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to provide theme-based padding
extension ThemePadding on ThemeData {
  _Padding get padding => _Padding();
}

class _Padding {
  double get primary => 16.0; // Standard padding
  double get small => 8.0; // Small padding
}
