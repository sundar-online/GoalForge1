import 'package:flutter_test/flutter_test.dart';
import 'package:goalforge/core/services/local_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalDatabaseService Tests', () {
    test('box constants are defined correctly', () {
      expect(LocalDatabaseService.boxGoals, equals('gf_goals'));
      expect(LocalDatabaseService.boxTasks, equals('gf_tasks'));
      expect(LocalDatabaseService.boxHabits, equals('gf_habits'));
      expect(LocalDatabaseService.boxNotes, equals('gf_notes'));
      expect(LocalDatabaseService.boxSyncQueue, equals('gf_sync_queue'));
    });
  });
}
