import 'package:flutter/material.dart';
import 'package:learnbound/screen/home_screen.dart';

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
    );
  }

  /// Builds the custom app bar with back button functionality.
  AppBarCustom _buildAppBar(BuildContext context) {
    return AppBarCustom(
      titleText: "Result",
      showBackButton: true,
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
          _buildTitle(context),
          const SizedBox(height: 8),
          _buildScoreCard(context, validatedScore, percentage),
          const SizedBox(height: 16),
          const SizedBox(height: 10),
          _buildActionButtons(context),
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

  /// Builds the score card displaying score and percentage.
  Widget _buildScoreCard(
      BuildContext context, int validatedScore, String percentage) {
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
              'Score: $validatedScore/$totalQuestions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
              semanticsLabel: 'Score: $validatedScore out of $totalQuestions',
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

  /// Builds the row of action buttons (Exit and Review).
  Widget _buildActionButtons(BuildContext context) {
    const buttonColor = Color.fromRGBO(211, 172, 112, 1.0);
    return Row(
      children: [
        _buildButton(
          context: context,
          text: 'Exit',
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          ),
          color: buttonColor,
        ),
        const SizedBox(width: 16),
        _buildButton(
          context: context,
          text: 'Review',
          onPressed: () => Navigator.pop(context),
          color: buttonColor,
        ),
      ],
    );
  }

  /// Builds a single elevated button with consistent styling.
  Widget _buildButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 20),
          textStyle: Theme.of(context).textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 6,
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
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
