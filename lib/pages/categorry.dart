import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fe/services/api.dart';
import 'package:fe/pages/detailProduk.dart';
import 'package:fe/pages/keranjang.dart';

class CategoryPage extends StatefulWidget {
  final String category;

  const CategoryPage({super.key, required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  int? currentUserId;
  late Future<List<Map<String, dynamic>>> productsFuture;

  final Color black = const Color(0xFF222222);
  final Color grey = const Color(0xFFF5F5F5);

  TextStyle get textStyle => GoogleFonts.dmSans();

  @override
  void initState() {
    super.initState();
    productsFuture = fetchProducts();
    getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    try {
      final id = await ApiServices.getUserIdFromToken();

      if (!mounted) return;

      setState(() {
        currentUserId = id;
      });
    } catch (e) {
      debugPrint('Gagal mengambil user ID: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await ApiServices.get('/posts');

    if (response is Map && response['success'] == true) {
      final data = response['data'];

      if (data is Map && data['posts'] is List) {
        final products = List<Map<String, dynamic>>.from(
          (data['posts'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );

        return products.where((product) {
          final category = (product['kategori'] ?? '').toString().toLowerCase();

          return category == widget.category.toLowerCase();
        }).toList();
      }
    }

    throw Exception('Gagal mengambil data produk');
  }

  String formatRupiah(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final formatted = number.toStringAsFixed(0);

    return 'Rp ${formatted.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  void openProductDetail(Map<String, dynamic> product) {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data akun belum tersedia.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailProdukPage(
          product: product,
          currentUserId: currentUserId!,
          onEdit: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur edit produk belum disambungkan.'),
              ),
            );
          },
          onDelete: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur hapus produk belum disambungkan.'),
              ),
            );
          },
        ),
      ),
    );
  }

  void addToCart(Map<String, dynamic> product) {
    CartService.addProduct(product);

    final name = product['nama']?.toString() ?? 'Produk';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name berhasil ditambahkan ke keranjang!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // PRODUCT CARD - SAMA SEPERTI HOMEPAGE
  Widget productCard(Map<String, dynamic> product) {
    final image = product['gambar']?.toString();
    final name = product['nama']?.toString() ?? 'Produk';
    final brand = product['kategori']?.toString() ?? 'Fashion';
    final price = formatRupiah(product['harga'] ?? 0);

    final hasImage = image != null && image.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => openProductDetail(product),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    color: grey,
                    child: hasImage
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey,
                              size: 32,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        GestureDetector(
          onTap: () => openProductDetail(product),
          child: Text(
            brand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(
              fontSize: 10,
              color: const Color(0xFF888888),
            ),
          ),
        ),

        const SizedBox(height: 4),

        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFE8B94F), size: 14),
            const SizedBox(width: 3),
            Text(
              '4.8',
              style: textStyle.copyWith(
                fontSize: 10,
                color: const Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              '(120 ulasan)',
              style: textStyle.copyWith(
                fontSize: 9,
                color: const Color(0xFF999999),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        GestureDetector(
          onTap: () => openProductDetail(product),
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(
              fontSize: 12,
              color: black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 5),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                price,
                style: textStyle.copyWith(
                  fontSize: 13,
                  color: black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Material(
              color: const Color(0xFFFFEEE9),
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => addToCart(product),
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFFE98568),
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.category,
          style: textStyle.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: black,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF222222)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat produk',
                style: textStyle.copyWith(fontSize: 12, color: Colors.grey),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Text(
                'Belum ada produk di kategori ${widget.category}',
                style: textStyle.copyWith(fontSize: 12, color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 25),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 22,
              childAspectRatio: 0.58,
            ),
            itemBuilder: (context, index) {
              return productCard(products[index]);
            },
          );
        },
      ),
    );
  }
}
