import 'package:checking_travel_app/data/datasources/hotel_api_service.dart';
import 'package:checking_travel_app/data/models/hotel_model.dart';
import 'package:checking_travel_app/feature/pages/hotel_detail_screen.dart';
import 'package:flutter/material.dart';


class HotelSearchScreen extends StatefulWidget {
  const HotelSearchScreen({super.key});

  @override
  State<HotelSearchScreen> createState() => _HotelSearchScreenState();
}

class _HotelSearchScreenState extends State<HotelSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final HotelApiService _apiService = HotelApiService();

  bool _isLoading = false;
  List<HotelModel> _hotels = [];
  String _errorMessage = '';

  // Hàm gọi API khi người dùng bấm tìm kiếm
  void _searchHotels(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _apiService.fetchCompleteHotels(query);
      setState(() {
        _hotels = results;
        if (_hotels.isEmpty) _errorMessage = 'Không tìm thấy khách sạn nào ở đây.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Tìm khách sạn', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // THANH TÌM KIẾM
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập tên thành phố (Vd: Đà Nẵng)...',
                prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: () => _searchHotels(_searchController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onSubmitted: _searchHotels, // Tìm khi ấn Enter trên bàn phím
            ),
          ),

          // KHU VỰC HIỂN THỊ KẾT QUẢ
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                : _hotels.isEmpty
                ? const Center(child: Text('Hãy nhập thành phố bạn muốn đến 🌴', style: TextStyle(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _hotels.length,
              itemBuilder: (context, index) {
                final hotel = _hotels[index];
                return _buildHotelCard(hotel);
              },
            ),
          ),
        ],
      ),
    );
  }

  // GIAO DIỆN MỘT THẺ KHÁCH SẠN
  Widget _buildHotelCard(HotelModel hotel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HotelDetailScreen(hotel: hotel),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh khách sạn
            Image.network(
              hotel.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(height: 180, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(hotel.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(' ${hotel.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(hotel.address, style: TextStyle(color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(hotel.price, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}