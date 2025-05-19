import 'package:flutter/foundation.dart'; 
import 'package:logging/logging.dart';

final Logger logger = Logger('AppLogger');

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
}
