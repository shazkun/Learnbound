import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io' show Platform;

class AudioService with WidgetsBindingObserver {
  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool isSoundEnabled = true;
  bool isSoundPlaying = false;

  AudioService() {
    WidgetsBinding.instance.addObserver(this);
    _bgMusicPlayer
        .setLoopMode(LoopMode.one); // Set loop mode for background music
  }

  Future<void> playBackgroundMusic() async {
    try {
      final path = 'assets/audio/quiz-bg.mp3';

      if (isSoundEnabled) {
        await _bgMusicPlayer.setAsset(
          path,
          preload: !Platform
              .isWindows, // Disable preload on Windows to avoid buffering issues
        );
        await _bgMusicPlayer.play();
        isSoundPlaying = true;
      }
    } catch (e) {
      debugPrint('Error playing background music: $e');
      isSoundPlaying = false;
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _bgMusicPlayer.stop();
      isSoundPlaying = false;
    } catch (e) {
      debugPrint('Error stopping background music: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await _bgMusicPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing background music: $e');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    try {
      if (isSoundEnabled && isSoundPlaying) {
        await _bgMusicPlayer.play();
      }
    } catch (e) {
      debugPrint('Error resuming background music: $e');
    }
  }

  Future<void> playSfx(String fileName) async {
    try {
      if (isSoundEnabled) {
        await _sfxPlayer.setAsset(
          fileName,
          preload: !Platform.isWindows, // Disable preload on Windows
        );
        await _sfxPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing SFX: $e');
    }
  }

  void toggleSound() {
    isSoundEnabled = !isSoundEnabled;
    if (!isSoundEnabled) {
      pauseBackgroundMusic();
      _sfxPlayer.stop();
    } else {
      resumeBackgroundMusic();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.detached) {
        pauseBackgroundMusic();
      } else if (state == AppLifecycleState.resumed) {
        resumeBackgroundMusic();
      }
    } catch (e) {
      debugPrint('Error handling lifecycle state $state: $e');
    }
  }

  void dispose() {
    try {
      _bgMusicPlayer.dispose();
      _sfxPlayer.dispose();
      WidgetsBinding.instance.removeObserver(this);
    } catch (e) {
      debugPrint('Error disposing audio service: $e');
    }
  }
}
