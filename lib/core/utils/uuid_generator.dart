import 'package:uuid/uuid.dart';

class UuidGenerator {
  UuidGenerator._();

  static const Uuid _uuid = Uuid();

  /// Generates a unique version 4 UUID string.
  static String generate() {
    return _uuid.v4();
  }
}
