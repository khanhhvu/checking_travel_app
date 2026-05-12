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
  List<HotelModel> _hotels = []; // Danh sách hiển thị trên màn hình
  List<HotelModel> _originalHotels = []; // Danh sách gốc
  String _errorMessage = '';

  String _selectedSort = 'Gần nhất'; // Trạng thái bộ lọc mặc định

  int _parsePrice(String priceString) {
    String cleaned = priceString.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return int.parse(cleaned);
  }

  // --- HÀM ÁP DỤNG BỘ LỌC ---
  void _applySorting() {
    if (_hotels.isEmpty) return;

    setState(() {
      if (_selectedSort == 'Giá: Thấp - Cao') {
        _hotels.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
      } else if (_selectedSort == 'Giá: Cao - Thấp') {
        _hotels.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
      } else {
        // Nếu chọn "Gần nhất", reset lại bằng danh sách gốc
        _hotels = List.from(_originalHotels);
      }
    });
  }

  // --- HÀM TÌM KIẾM ---
  void _searchHotels(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _apiService.fetchCompleteHotels(query);
      setState(() {
        _originalHotels = List.from(results); // Lưu bản gốc an toàn
        _hotels = List.from(results); // Gán cho bản hiển thị

        if (_hotels.isEmpty) {
          _errorMessage = 'Không tìm thấy khách sạn nào ở đây.';
        } else {
          _applySorting(); // Áp dụng ngay bộ lọc đang chọn nếu có
        }
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
          // --- THANH TÌM KIẾM ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập tên thành phố ',
                prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: () => _searchHotels(_searchController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onSubmitted: _searchHotels,
            ),
          ),

          // --- THANH BỘ LỌC (Chỉ hiện khi đã có dữ liệu để nhìn cho gọn) ---
          if (_hotels.isNotEmpty || _isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sắp xếp theo:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      icon: const Icon(Icons.sort, color: Colors.blue, size: 20),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.w600),
                      items: ['Gần nhất', 'Giá: Thấp - Cao', 'Giá: Cao - Thấp'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          _selectedSort = newValue;
                          _applySorting();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

          // --- KHU VỰC HIỂN THỊ KẾT QUẢ ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                : _hotels.isEmpty
                ? const Center(child: Text('Hãy nhập thành phố bạn muốn đến ', style: TextStyle(color: Colors.grey, fontSize: 16)))
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

  // --- GIAO DIỆN MỘT THẺ KHÁCH SẠN ---
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