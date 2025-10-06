import 'package:flutter_test/flutter_test.dart';
import 'package:music_practice_app/services/audio_analysis/models/note_event.dart';
import 'package:music_practice_app/services/audio_analysis/models/spectrogram.dart';
import 'package:music_practice_app/services/audio_analysis/note_verification_service_impl.dart';

void main() {
  group('NoteEvent 測試', () {
    test('MIDI 60 應該是 C4, 261.63 Hz', () {
      final note = NoteEvent(
        midiNote: 60,
        startTime: 0,
        endTime: 1,
      );

      expect(note.noteName, 'C4');
      expect(note.frequency, closeTo(261.63, 0.01));
      expect(note.duration, 1.0);
    });

    test('MIDI 69 應該是 A4, 440 Hz', () {
      final note = NoteEvent(
        midiNote: 69,
        startTime: 0,
        endTime: 1,
      );

      expect(note.noteName, 'A4');
      expect(note.frequency, closeTo(440.0, 0.01));
    });

    test('諧波計算', () {
      final note = NoteEvent(midiNote: 60, startTime: 0, endTime: 1);

      expect(note.getHarmonic(1), closeTo(261.63, 0.01)); // 基頻
      expect(note.getHarmonic(2), closeTo(523.25, 0.01)); // 第一泛音
      expect(note.getHarmonic(3), closeTo(784.88, 0.01)); // 第二泛音
    });

    test('音符名稱轉換', () {
      expect(NoteEvent(midiNote: 48, startTime: 0, endTime: 1).noteName, 'C3');
      expect(NoteEvent(midiNote: 61, startTime: 0, endTime: 1).noteName, 'C#4');
      expect(NoteEvent(midiNote: 62, startTime: 0, endTime: 1).noteName, 'D4');
      expect(NoteEvent(midiNote: 72, startTime: 0, endTime: 1).noteName, 'C5');
    });
  });

  group('MidiTimeline 測試', () {
    test('創建時間軸並查詢音符', () {
      final events = [
        NoteEvent(midiNote: 60, startTime: 0.0, endTime: 1.0),
        NoteEvent(midiNote: 62, startTime: 1.0, endTime: 2.0),
        NoteEvent(midiNote: 64, startTime: 2.0, endTime: 3.0),
      ];

      final timeline = MidiTimeline(events: events, duration: 3.0);

      expect(timeline.events.length, 3);
      expect(timeline.duration, 3.0);

      // 查詢時間範圍內的音符
      final notesInRange = timeline.getNotesInRange(0.5, 1.5);
      expect(notesInRange.length, 2);
    });

    test('諧波緩存', () {
      final events = [
        NoteEvent(midiNote: 60, startTime: 0.0, endTime: 1.0),
      ];

      final timeline = MidiTimeline(events: events, duration: 1.0);
      final harmonics = timeline.getHarmonics(60);

      expect(harmonics.length, 3);
      expect(harmonics[0], closeTo(261.63, 0.01)); // f0
      expect(harmonics[1], closeTo(523.25, 0.01)); // 2f0
      expect(harmonics[2], closeTo(784.88, 0.01)); // 3f0
    });
  });

  group('Spectrogram 測試', () {
    test('時間和頻率轉換', () {
      // 模擬頻譜圖
      final spec = Spectrogram(
        timeFrames: 100,
        freqBins: 1025,
        data: List.generate(100, (_) => List.filled(1025, 0.0)),
        sampleRate: 44100,
        fftSize: 2048,
        hopSize: 512,
      );

      // 測試頻率解析度
      expect(spec.frequencyResolution, closeTo(21.53, 0.01));

      // 測試時間解析度
      expect(spec.timeResolution, closeTo(0.0116, 0.001));

      // 測試轉換
      final freqBin = spec.freqToBin(440.0);
      expect(freqBin, greaterThan(0));
      expect(freqBin, lessThan(1025));

      final frame = spec.timeToFrame(0.5);
      expect(frame, greaterThan(0));
      expect(frame, lessThan(100));
    });

    test('能量查詢', () {
      final testData = List.generate(10, (t) {
        return List.generate(100, (f) {
          // 在特定頻率處設置能量峰值
          if (f == 50) return 0.8;
          return 0.1;
        });
      });

      final spec = Spectrogram(
        timeFrames: 10,
        freqBins: 100,
        data: testData,
        sampleRate: 44100,
        fftSize: 2048,
        hopSize: 512,
      );

      // 查詢特定頻率的能量
      final targetFreq = spec.frequencyResolution * 50;
      final energy = spec.getEnergy(0.0, targetFreq);
      expect(energy, closeTo(0.8, 0.01));
    });
  });

  group('NoteVerificationService 測試', () {
    test('諧波計算', () {
      final verifier = NoteVerificationServiceImpl();
      
      // 測試內部方法需要使用反射或將方法公開
      // 這裡我們通過創建模擬頻譜來測試完整流程
      
      // 創建模擬頻譜: 在 440Hz (A4, MIDI 69) 處有強能量
      final testData = List.generate(100, (t) {
        return List.generate(1025, (f) {
          final freq = 44100 / 2048 * f;
          // 在 440Hz 及其諧波處設置能量
          if ((freq - 440).abs() < 10 ||
              (freq - 880).abs() < 10 ||
              (freq - 1320).abs() < 10) {
            return 0.9;
          }
          return 0.05;
        });
      });

      final spec = Spectrogram(
        timeFrames: 100,
        freqBins: 1025,
        data: testData,
        sampleRate: 44100,
        fftSize: 2048,
        hopSize: 512,
      );

      // 驗證 A4 (MIDI 69) 在時間 0.5秒
      final result = verifier.verifyNote(69, 0.5, spec);
      
      // 由於是異步方法,在單元測試中需要等待
      expect(result, completion(isTrue));
    });
  });
}
