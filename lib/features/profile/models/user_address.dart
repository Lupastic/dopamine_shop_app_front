class UserAddress {
  final String id;
  final String? label;
  final String city;
  final String street;
  final String? house;
  final String? apartment;
  final String? entrance;
  final String? floor;
  final String? comment;
  final bool isDefault;

  UserAddress({
    required this.id,
    this.label,
    required this.city,
    required this.street,
    this.house,
    this.apartment,
    this.entrance,
    this.floor,
    this.comment,
    required this.isDefault,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) => UserAddress(
        id: json['id']?.toString() ?? '',
        label: json['label'],
        city: json['city'] ?? '',
        street: json['street'] ?? '',
        house: json['house'],
        apartment: json['apartment'],
        entrance: json['entrance'],
        floor: json['floor'],
        comment: json['comment'],
        isDefault: json['isDefault'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'city': city,
        'street': street,
        'house': house,
        'apartment': apartment,
        'entrance': entrance,
        'floor': floor,
        'comment': comment,
        'isDefault': isDefault,
      };
}
