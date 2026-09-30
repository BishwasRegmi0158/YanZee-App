class ApiConfig {
  static const String baseUrl = 'https://yanzee.onrender.com/api/v1';

  static Uri register() => Uri.parse('$baseUrl/auth/register');
  static Uri login()    => Uri.parse('$baseUrl/auth/login');
  static Uri me()       => Uri.parse('$baseUrl/auth/me');
  static Uri logout()   => Uri.parse('$baseUrl/auth/logout');
  static Uri refresh()  => Uri.parse('$baseUrl/auth/refresh');
}