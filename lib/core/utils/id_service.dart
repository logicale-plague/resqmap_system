import 'package:uuid/uuid.dart';

class IdService {
  static const Uuid _uuid = Uuid();

  static String newId() => _uuid.v4();
}
