class HotelModel {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  String price;
  final double rating;
  final double lat;
  final double lng;

  HotelModel({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    this.price = 'Đang tải giá...',
    required this.rating,
    required this.lat,
    required this.lng,
  });
}