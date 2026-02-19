class City {
  final String name;
  final String country;
  final String code;

  City({
    required this.name,
    required this.country,
    required this.code,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] as String? ?? '',
      country: json['country'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }

  String get displayName => '$name, $country';

  String get searchText => '${name.toLowerCase()} ${country.toLowerCase()}';

  @override
  String toString() => 'City(name: $name, country: $country, code: $code)';
}