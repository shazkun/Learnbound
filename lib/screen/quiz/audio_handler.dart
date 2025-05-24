import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io' show Platform;

class AudioService with WidgetsBindingObserver {
  AudioPlayer bgMusicPlayer = AudioPlayer();
  AudioPlayer sfxPlayer = AudioPlayer();
  bool isSoundEnabled = true;
  bool isSoundPlaying = false;

  AudioService() {
    WidgetsBinding.instance.addObserver(this);
    bgMusicPlayer
        .setLoopMode(LoopMode.one); // Set loop mode for background music
  }

  Future<void> playBackgroundMusic() async {
    try {
      final path = 'assets/audio/quiz-bg.mp3';

      if (isSoundEnabled) {
        await bgMusicPlayer.setAsset(
          path,
          preload: !Platform
              .isWindows, // Disable preload on Windows to avoid buffering issues
        );
        await bgMusicPlayer.play();
        isSoundPlaying = true;
      }
    } catch (e) {
      debugPrint('Error playing background music: $e');
      isSoundPlaying = false;
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await bgMusicPlayer.stop();
      isSoundPlaying = false;
    } catch (e) {
      debugPrint('Error stopping background music: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await bgMusicPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing background music: $e');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    try {
      if (isSoundEnabled && isSoundPlaying) {
        await bgMusicPlayer.play();
      }
    } catch (e) {
      debugPrint('Error resuming background music: $e');
    }
  }

  Future<void> playSfx(String fileName) async {
    try {
      if (isSoundEnabled) {
        await sfxPlayer.setAsset(
          fileName,
          preload: !Platform.isWindows, // Disable preload on Windows
        );
        await sfxPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing SFX: $e');
    }
  }

  void toggleSound() {
    isSoundEnabled = !isSoundEnabled;
    if (!isSoundEnabled) {
      pauseBackgroundMusic();
      sfxPlayer.stop();
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
      bgMusicPlayer.dispose();
      sfxPlayer.dispose();
      WidgetsBinding.instance.removeObserver(this);
    } catch (e) {
      debugPrint('Error disposing audio service: $e');
    }
  }
}
