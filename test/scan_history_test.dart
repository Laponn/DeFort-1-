import 'package:flutter_test/flutter_test.dart';
import 'package:defort/core/scan_history.dart';

void main() {
  group('ScanRecord', () {
    test('creates from constructor', () {
      final record = ScanRecord(
        type: 'quick',
        timestamp: DateTime(2026, 9, 30, 10, 0),
        filesScanned: 1000,
        malwareCount: 0,
        malwareList: [],
        isRealSdk: true,
      );

      expect(record.type, 'quick');
      expect(record.filesScanned, 1000);
      expect(record.malwareCount, 0);
      expect(record.isSafe, true);
      expect(record.typeDisplay, 'Pindai Cepat');
    });

    test('serializes to and from JSON', () {
      final original = ScanRecord(
        type: 'full',
        timestamp: DateTime(2026, 9, 30, 10, 30),
        filesScanned: 5000,
        malwareCount: 2,
        malwareList: ['Trojan.Android', 'Adware.Banner'],
        isRealSdk: true,
        folderPath: '/storage/emulated/0/Download',
      );

      final json = original.toJson();
      final restored = ScanRecord.fromJson(json);

      expect(restored.type, original.type);
      expect(restored.filesScanned, original.filesScanned);
      expect(restored.malwareCount, original.malwareCount);
      expect(restored.malwareList, original.malwareList);
      expect(restored.isRealSdk, original.isRealSdk);
      expect(restored.folderPath, original.folderPath);
      expect(restored.isSafe, false);
    });

    test('typeDisplay returns correct labels', () {
      expect(
        ScanRecord(type: 'quick', timestamp: DateTime.now(), filesScanned: 0, malwareCount: 0, malwareList: [], isRealSdk: false).typeDisplay,
        'Pindai Cepat',
      );
      expect(
        ScanRecord(type: 'full', timestamp: DateTime.now(), filesScanned: 0, malwareCount: 0, malwareList: [], isRealSdk: false).typeDisplay,
        'Pindai Menyeluruh',
      );
      expect(
        ScanRecord(type: 'folder', timestamp: DateTime.now(), filesScanned: 0, malwareCount: 0, malwareList: [], isRealSdk: false).typeDisplay,
        'Pindai Folder',
      );
    });

    test('isSafe returns correct values', () {
      final safe = ScanRecord(type: 'quick', timestamp: DateTime.now(), filesScanned: 100, malwareCount: 0, malwareList: [], isRealSdk: true);
      final unsafe = ScanRecord(type: 'quick', timestamp: DateTime.now(), filesScanned: 100, malwareCount: 3, malwareList: ['A', 'B', 'C'], isRealSdk: true);
      
      expect(safe.isSafe, true);
      expect(unsafe.isSafe, false);
    });
  });
}
