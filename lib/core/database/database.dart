import 'package:mysql_dart/mysql_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  MySQLConnection? _conn;

  final host = dotenv.get('DB_HOST');
  final port = dotenv.getInt('DB_PORT');
  final user = dotenv.get('DB_USER');
  final password = dotenv.get('DB_PASSWORD');
  final name = dotenv.get('DB_NAME');

  Future<MySQLConnection> get connection async {
    if (_conn == null || !_conn!.connected) {
      _conn = await MySQLConnection.createConnection(
        host: host,
        port: port,
        userName: user,
        password: password,
        databaseName: name,
      );
      await _conn!.connect();
    }
    return _conn!;
  }

  Future<void> close() async {
    if (_conn != null && _conn!.connected) {
      await _conn!.close();
    }
  }
}