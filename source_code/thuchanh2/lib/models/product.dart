class Product {
  final String id;
  final String name;
  final String des;
  final double price;
  final String imgURL;

  Product({
    required this.id,
    required this.name,
    required this.des,
    required this.price,
    required this.imgURL,
  });

  factory Product.fromJson(Map<String, dynamic> j) {
    return Product(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      des: j['des']?.toString() ?? '',
      price: (j['price'] is num)
          ? (j['price'] as num).toDouble()
          : double.tryParse(j['price']?.toString() ?? '0') ?? 0,
      imgURL: j['imgURL']?.toString() ?? '',
    );
  }
}
