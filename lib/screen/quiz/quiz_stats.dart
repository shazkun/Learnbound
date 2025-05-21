import 'package:flutter/material.dart';
import 'package:learnbound/screen/home_screen.dart';
import 'package:learnbound/util/design/colors.dart';

import '../../util/back_dialog.dart';
import '../../util/design/appbar.dart';

/// Displays quiz results with score, percentage, and time taken.
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
    final validatedScore = score.clamp(0, totalQuestions);
    final percentage = totalQuestions > 0
        ? (validatedScore / totalQuestions * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, validatedScore, percentage),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left bottom FAB
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: FloatingActionButton(
              backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
              onPressed: () => Navigator.pop(context),
              heroTag: 'review-Button',
              tooltip: 'Review',
              child: Icon(Icons.reviews, color: Colors.black),
            ),
          ),

          // Right bottom FAB
          Padding(
            padding: const EdgeInsets.only(right: 30.0),
            child: FloatingActionButton(
                backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
                tooltip: 'Finish',
                heroTag: 'finish-Button',
                onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    ),
                child: Icon(
                  Icons.done,
                  color: Colors.black,
                )),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Builds the custom app bar with back button functionality.
  AppBarCustom _buildAppBar(BuildContext context) {
    return AppBarCustom(
      titleText: "Result",
      showBackButton: false,
      onBackPressed: () async => CustomExitDialog.show(context,
          usePushReplacement: true, targetPage: HomeScreen()),
    );
  }

  /// Builds the main body with gradient background and centered content.
  Widget _buildBody(
      BuildContext context, int validatedScore, String percentage) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white],
        ),
      ),
      padding: EdgeInsets.all(Theme.of(context).padding.primary),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // _buildTitle(context),
          // const SizedBox(height: 8),
          _buildScoreCard(context, validatedScore, percentage),
          const SizedBox(height: 16),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// Builds the congratulatory title text.
  Widget _buildTitle(BuildContext context) {
    return Text(
      'Congratulations!',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildScoreCard(
      BuildContext context, int validatedScore, String percentage) {
    // Convert percentage string to double for CircularProgressIndicator
    double progressValue = double.tryParse(percentage) ?? 0.0;
    progressValue = progressValue / 100; // Convert to 0.0–1.0 range

    return Card(
      elevation: 12, // Increased elevation for deeper shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: Colors.grey.shade200, width: 1), // Subtle border
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgGrey200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(Theme.of(context).padding.primary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Score badge with icon
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Score: $validatedScore/$totalQuestions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 20,
                          ),
                      semanticsLabel:
                          'Score: $validatedScore out of $totalQuestions',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Percentage circle with animation
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: progressValue),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                          semanticsLabel: 'Percentage: $percentage percent',
                        );
                      },
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 24,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Motivational text based on percentage
              Text(
                _getMotivationalText(progressValue),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper method for motivational text
  String _getMotivationalText(double progressValue) {
    if (progressValue >= 0.9) {
      return 'Outstanding performance!';
    } else if (progressValue >= 0.7) {
      return 'Great job, keep it up!';
    } else if (progressValue >= 0.5) {
      return 'Solid effort, you can do even better!';
    } else {
      return 'Keep practicing, you’ve got this!';
    }
  }
}

/// Theme extension for consistent padding values.
extension ThemePadding on ThemeData {
  _Padding get padding => _Padding();
}

class _Padding {
  double get primary => 16.0;
  double get small => 8.0;
}
