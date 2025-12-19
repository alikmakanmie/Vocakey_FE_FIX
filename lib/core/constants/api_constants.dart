class ApiConstants {
  // Base URL - sesuaikan dengan backend Anda
  static const String baseUrl = 'https://pound-essex-clinical-thumbnails.trycloudflare.com/';
  
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
