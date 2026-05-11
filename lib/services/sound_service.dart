import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // A pool of players to allow overlapping sounds
  final List<AudioPlayer> _playerPool = List.generate(8, (_) => AudioPlayer());
  int _currentPlayerIndex = 0;
  
  String? _splatPath;
  String? _squeakPath;
  String? _laserPath;
  String? _splashPath;

  Future<void> initialize() async {
    // 1. Optimize Global Audio Context
    await AudioPlayer.global.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        usageType: AndroidUsageType.game,
        contentType: AndroidContentType.sonification,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    ));

    // 2. Generate and Cache Synthetic Sounds as Local Files
    // This is MUCH faster than sending bytes over platform channels repeatedly
    final tempDir = Directory.systemTemp;
    
    _splatPath = await _saveSyntheticWav(tempDir, 'splat.wav', 100, 350, 40, WaveType.sine);
    _squeakPath = await _saveSyntheticWav(tempDir, 'squeak.wav', 60, 2500, 4500, WaveType.sine);
    _laserPath = await _saveSyntheticWav(tempDir, 'laser.wav', 120, 1800, 300, WaveType.sawtooth);
    _splashPath = await _saveSyntheticWav(tempDir, 'splash.wav', 200, 180, 80, WaveType.sine);

    // 3. Pre-warm players and set Low Latency mode
    for (var player in _playerPool) {
      await player.setReleaseMode(ReleaseMode.stop);
    }
  }

  Future<String> _saveSyntheticWav(Directory dir, String name, int durationMs, double freqStart, double freqEnd, WaveType type) async {
    final bytes = _createWavBuffer(durationMs: durationMs, frequencyStart: freqStart, frequencyEnd: freqEnd, type: type);
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  void _play(String? path, double volume) {
    if (path == null) return;
    
    try {
      final player = _playerPool[_currentPlayerIndex];
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _playerPool.length;
      
      // Fire and forget. We use standard mode to avoid native threading bugs on Windows.
      player.play(DeviceFileSource(path), volume: volume);
    } catch (_) {
      // Gracefully ignore audio engine hiccups on Windows
    }
  }

  void playSplat() {
    _play(_splatPath, 0.5);
    HapticFeedback.mediumImpact();
  }

  void playSqueak() {
    _play(_squeakPath, 0.4);
    HapticFeedback.lightImpact();
  }

  void playLaserBlast() {
    _play(_laserPath, 0.6);
    HapticFeedback.heavyImpact();
  }

  void playSplash() {
    _play(_splashPath, 0.3);
    HapticFeedback.selectionClick();
  }

  Uint8List _createWavBuffer({
    required int durationMs,
    required double frequencyStart,
    required double frequencyEnd,
    required WaveType type,
  }) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * (durationMs / 1000)).toInt();
    final Int16List samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / numSamples;
      final double freq = frequencyStart + (frequencyEnd - frequencyStart) * t;
      final double phase = (2 * math.pi * freq * (i / sampleRate));
      
      double sample = 0;
      switch (type) {
        case WaveType.sine:
          sample = math.sin(phase);
          break;
        case WaveType.sawtooth:
          sample = 2 * (phase / (2 * math.pi) - (phase / (2 * math.pi) + 0.5).floor());
          break;
        case WaveType.noise:
          sample = math.Random().nextDouble() * 2 - 1;
          break;
      }

      final double envelope = math.pow(1.0 - t, 2).toDouble();
      samples[i] = (sample * envelope * 28000).toInt();
    }

    return _createWavHeader(samples, sampleRate);
  }

  Uint8List _createWavHeader(Int16List samples, int sampleRate) {
    final int fileSize = 44 + samples.length * 2;
    final ByteData header = ByteData(44);

    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize - 8, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6d); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); //  
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // Mono
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, samples.length * 2, Endian.little);

    final Uint8List wav = Uint8List(fileSize);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, fileSize, samples.buffer.asUint8List());
    return wav;
  }
}

enum WaveType { sine, sawtooth, noise }
