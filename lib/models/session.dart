import 'response.dart';
import 'package:uuid/uuid.dart';

class Session {
  final String id = const Uuid().v4();
  final List<Response> responses = [];
}