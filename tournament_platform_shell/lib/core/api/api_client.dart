import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiClient {
  final String baseUrl;
  String? _accessToken;

  ApiClient({required this.baseUrl});

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        uri,
        headers: _headers,
        body: body != null ? _encodeBody(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        uri,
        headers: _headers,
        body: body != null ? _encodeBody(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return _decodeBody(response.body);
    } else {
      String message = 'Request failed';
      try {
        final body = _decodeBody(response.body);
        if (body is Map && body.containsKey('detail')) {
          message = body['detail'];
        }
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
  }

  String _encodeBody(dynamic body) {
    if (body is Map) {
      return body.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value?.toString() ?? '')}')
          .join('&');
    }
    return body.toString();
  }

  dynamic _decodeBody(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  // Use environment variable or default to localhost
  const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api');
  return ApiClient(baseUrl: baseUrl);
});

// JSON helper
dynamic jsonDecode(String source) {
  return json.decode(source);
}

final json = _JsonHelper();
class _JsonHelper {
  dynamic decode(String source) {
    // Simple JSON parsing
    if (source.startsWith('{')) {
      return _parseJsonObject(source);
    } else if (source.startsWith('[')) {
      return _parseJsonArray(source);
    }
    return source;
  }
  
  Map<String, dynamic> _parseJsonObject(String source) {
    final result = <String, dynamic>{};
    final content = source.substring(1, source.length - 1).trim();
    if (content.isEmpty) return result;
    
    var i = 0;
    while (i < content.length) {
      // Skip whitespace
      while (i < content.length && content[i] == ' ') i++;
      if (i >= content.length) break;
      
      // Parse key
      if (content[i] != '"') {
        i++;
        continue;
      }
      i++; // skip opening quote
      final keyEnd = content.indexOf('"', i);
      if (keyEnd == -1) break;
      final key = content.substring(i, keyEnd);
      i = keyEnd + 1;
      
      // Skip to colon
      while (i < content.length && content[i] != ':') i++;
      i++; // skip colon
      
      // Skip whitespace
      while (i < content.length && content[i] == ' ') i++;
      
      // Parse value
      if (i < content.length) {
        if (content[i] == '"') {
          i++; // skip opening quote
          final valueEnd = content.indexOf('"', i);
          if (valueEnd != -1) {
            result[key] = content.substring(i, valueEnd);
            i = valueEnd + 1;
          }
        } else if (content[i] == '{') {
          // Find matching brace
          var depth = 1;
          var j = i + 1;
          while (j < content.length && depth > 0) {
            if (content[j] == '{') depth++;
            else if (content[j] == '}') depth--;
            j++;
          }
          result[key] = _parseJsonObject(content.substring(i, j));
          i = j;
        } else if (content[i] == '[') {
          var depth = 1;
          var j = i + 1;
          while (j < content.length && depth > 0) {
            if (content[j] == '[') depth++;
            else if (content[j] == ']') depth--;
            j++;
          }
          result[key] = _parseJsonArray(content.substring(i, j));
          i = j;
        } else {
          // Number or boolean or null
          final valueEnd = content.indexOf(',', i);
          var valueStr = valueEnd != -1 && valueEnd < content.indexOf('}', i)
              ? content.substring(i, valueEnd).trim()
              : content.substring(i, content.indexOf('}', i)).trim();
          if (valueStr.endsWith(',')) valueStr = valueStr.substring(0, valueStr.length - 1).trim();
          
          if (valueStr == 'null') {
            result[key] = null;
          } else if (valueStr == 'true') {
            result[key] = true;
          } else if (valueStr == 'false') {
            result[key] = false;
          } else {
            final num = num.tryParse(valueStr);
            if (num != null) {
              result[key] = num is int ? num : num.toInt();
            } else {
              result[key] = valueStr;
            }
          }
          i = valueEnd != -1 && valueEnd < content.indexOf('}', i) ? valueEnd : content.length;
        }
      }
      
      // Skip comma
      while (i < content.length && (content[i] == ',' || content[i] == ' ')) i++;
    }
    return result;
  }
  
  List<dynamic> _parseJsonArray(String source) {
    final result = <dynamic>[];
    final content = source.substring(1, source.length - 1).trim();
    if (content.isEmpty) return result;
    
    // Simple split by comma (doesn't handle nested structures well, but works for simple arrays)
    var depth = 0;
    var start = 0;
    for (var i = 0; i < content.length; i++) {
      if (content[i] == '[' || content[i] == '{') depth++;
      else if (content[i] == ']' || content[i] == '}') depth--;
      else if (content[i] == ',' && depth == 0) {
        result.add(_parseValue(content.substring(start, i).trim()));
        start = i + 1;
      }
    }
    if (start < content.length) {
      result.add(_parseValue(content.substring(start).trim()));
    }
    return result;
  }
  
  dynamic _parseValue(String value) {
    value = value.trim();
    if (value.isEmpty) return null;
    if (value == 'null') return null;
    if (value == 'true') return true;
    if (value == 'false') return false;
    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }
    if (value.startsWith('{')) {
      return _parseJsonObject(value);
    }
    if (value.startsWith('[')) {
      return _parseJsonArray(value);
    }
    final num = num.tryParse(value);
    if (num != null) {
      return num is int ? num : num.toInt();
    }
    return value;
  }
}
