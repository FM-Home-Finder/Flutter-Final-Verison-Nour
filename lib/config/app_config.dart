class AppConfig {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Pour Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // Pour iOS
  // static const String baseUrl = 'http://192.168.1.xxx:8000'; // Pour device physique
  
  static const String apiUrl = '$baseUrl/api';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}