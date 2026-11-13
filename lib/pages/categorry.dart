import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fe/services/api.dart';
import 'package:fe/pages/detailProduk.dart';
import 'package:fe/pages/keranjang.dart';
import 'package:fe/pages/like.dart';
import 'package:fe/pages/keranjang.dart';

class CategoryPage extends StatefulWidget {
  final String category;

  const CategoryPage({super.key, required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  Set<int> favoriteIds = {};
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
    fetchFavoriteIds();

  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await ApiServices.get('/posts');

    if (response['success'] == true) {
      final data = response['data'];
      final posts = data['posts'] as List;

      return posts
          .map((item) => Map<String, dynamic>.from(item))
          .where((product) {
            return product['kategori']
                    ?.toString()
                    .toLowerCase() ==
                widget.category.toLowerCase();
          })
          .toList();
    }

    throw Exception('Gagal mengambil produk');
  }

  void openProductDetail(Map<String, dynamic> product) {
    if (currentUserId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailProdukPage(
          product: product,
          currentUserId: currentUserId!,
        ),
      ),
    );
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

  Future<void> fetchFavoriteIds() async {
    try {
      final response = await ApiServices.get('/favorites');

      if (response['success'] == true) {
        final items = response['data']['favorites'] as List;

        if (!mounted) return;

        setState(() {
          favoriteIds = items.map<int>((item) {
            return int.parse(item['id'].toString());
          }).toSet();
        });
      }
    } catch (e) {
      debugPrint('Gagal mengambil favorite: $e');
    }
  }

  Future<void> toggleFavorite(int productId) async {
    final isFavorite = favoriteIds.contains(productId);

    try {
      if (isFavorite) {
        await ApiServices.delete('/favorites/$productId');
      } else {
        await ApiServices.post('/favorites/$productId', {});
      }

      if (!mounted) return;

      setState(() {
        if (isFavorite) {
          favoriteIds.remove(productId);
        } else {
          favoriteIds.add(productId);
        }
      });

      favoriteChanged.value++;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah Favorite: $e')),
      );
    }
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

  String formatRupiah(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final formatted = number.toStringAsFixed(0);

    return 'Rp ${formatted.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )}';
  }

   // PRODUCT CARD
  Widget productCard(Map<String, dynamic> product) {
    final image = product['gambar']?.toString();
    final name = product['nama']?.toString() ?? 'Produk';
    final brand = product['kategori']?.toString() ?? 'Fashion';
    final price = formatRupiah(product['harga'] ?? 0);

    final hasImage = image != null && image.trim().isNotEmpty;

    final productId = int.tryParse(product['id'].toString());

    final isFavorite = productId != null && favoriteIds.contains(productId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PRODUCT IMAGE
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

              // FAVORITE BUTTON
              Positioned(
                top: 9,
                right: 9,
                child: Material(
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      if (productId != null) {
                        toggleFavorite(productId);
                      }
                    },
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? Colors.red
                            : const Color(0xFF888888),
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // CATEGORY
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

        // RATING
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

        // PRODUCT NAME
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

        // PRICE + CART
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
              child: InkWell(
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
