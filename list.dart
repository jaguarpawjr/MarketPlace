import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'YOUR_API_KEY';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final models = data['models'] as List;
    for (var m in models) {
      print(m['name']);
    }
  } else {
    print('Failed: ${response.statusCode} ${response.body}');
  }
}
