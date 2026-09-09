class ApiConfig {
  static const String baseUrl = 'https://dummyjson.com';

  static Uri login() => Uri.parse('$baseUrl/auth/login');
  static Uri me() => Uri.parse('$baseUrl/auth/me');
  static Uri user(int id) => Uri.parse('$baseUrl/users/$id');
}