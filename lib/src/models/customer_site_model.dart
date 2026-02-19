class CustomerSite {
  final int id;
  final String name;

  const CustomerSite({required this.id, required this.name});

  factory CustomerSite.fromJson(Map<String, dynamic> json) =>
      CustomerSite(id: json['id'] as int, name: json['name'] as String);
}
