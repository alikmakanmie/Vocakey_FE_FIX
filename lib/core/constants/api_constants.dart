class ApiConstants {
  // Base URL - sesuaikan dengan backend Anda
  static const String baseUrl = 'http://192.168.X.X:5000';
  
  // Endpoints
  static const String analyzeEndpoint = '/api/analyze';
  
  // Headers
  static const Map<String, String> headers = {
    'Accept': 'application/json',
  };
  
  // Recording settings
  static const int maxRecordDuration = 10; // seconds
  static const String audioFormat = 'wav';
}
