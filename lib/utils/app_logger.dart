import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Logger i = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
}
