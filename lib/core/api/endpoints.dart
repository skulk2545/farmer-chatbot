class Endpoints {
  /// Centralized API endpoint paths relative to the base URL.
  
  static const String baseDefaultUrl = "http://10.0.2.2:8000"; // Android Emulator loopback
  
  static const String health = "/";
  static const String predict = "/predict";
  static const String chat = "/chat";
  static const String history = "/history";
  static const String stats = "/stats";
  
  // Versioned equivalents
  static const String healthV1 = "/api/v1/";
  static const String predictV1 = "/api/v1/predict";
  static const String chatV1 = "/api/v1/chat";
  static const String historyV1 = "/api/v1/history";
  static const String statsV1 = "/api/v1/stats";
}
