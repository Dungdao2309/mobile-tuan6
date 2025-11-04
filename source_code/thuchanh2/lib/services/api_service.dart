import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String apiUrl =
      'https://mock.apidog.com/m1/890655-872447-default/v2/product';

  /// Hàm gọi API GET để lấy danh sách sản phẩm
  static Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      List items = [];
      if (body is List) {
        items = body;
      } else if (body is Map && body.containsKey('data') && body['data'] is List) {
        items = body['data'];
      } else if (body is Map && body.containsKey('product')) {
        items = [body['product']];
      } else {
        items = [body];
      }

      return items.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products (${response.statusCode})');
    }
  }
}
