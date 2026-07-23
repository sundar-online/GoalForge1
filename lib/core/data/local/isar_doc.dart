import 'package:isar/isar.dart';

part 'isar_doc.g.dart';

@collection
class IsarDoc {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String docId;

  @Index()
  late String collectionName;

  late String dataJson;
}
