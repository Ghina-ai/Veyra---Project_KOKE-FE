import 'package:fe/pages/detailProduk.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fe/services/api.dart';
import 'package:fe/pages/editprofile.dart';
import 'package:fe/pages/like.dart';
import 'package:fe/pages/keranjang.dart';
import 'package:fe/pages/detailProduk.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color textDark = const Color(0xFF20242B);
  final Color textGrey = const Color(0xFF8A919B);
  final Color accent = const Color(0xFFE98568);

  Map<String, dynamic> profile = {};
  List<dynamic> products = [];
  Set<int> favoriteIds = {};
  TextStyle get textStyle => GoogleFonts.dmSans();
  bool isLoading = true;
  String? errorMessage;
  int? userId;

  @override
  void initState() {
    super.initState();
    loadProfile();
    fetchFavoriteIds();
  }

  
  Future<void> loadProfile() async {
    try {
      final id = await ApiServices.getUserIdFromToken();

      userId = id;

      // 1. Ambil data profil pengguna
      final response = await ApiServices.getProfile(id);
      final data = response['data'];

      if (data is! Map) {
        throw Exception('Format data profil tidak sesuai.');
      }

      final userData = data['user'];

      if (userData is Map) {
        profile = Map<String, dynamic>.from(userData);
      } else {
        throw Exception('Data pengguna tidak ditemukan.');
      }

      // 2. Ambil semua produk dari endpoint Home
      final postsResponse = await ApiServices.get('/posts');
      final postsData = postsResponse['data']['posts'] as List;

      // 3. Filter produk berdasarkan pemiliknya
      products = postsData.where((item) {
        return int.tryParse(item['userId'].toString()) == id;
      }).map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();

      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
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

  Future<void> openProductDetail(Map<String, dynamic> product) async {
  final id = await ApiServices.getUserIdFromToken();

  if (!mounted || id == null) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DetailProdukPage(
        product: product,
        currentUserId: id,
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

  String formatRupiah(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final formatted = number.toStringAsFixed(0);

    return 'Rp ${formatted.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )}';
  }

  String getValue(List<String> keys) {
    for (final key in keys) {
      final value = profile[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '-';
  }

  String productValue(Map<String, dynamic> product, List<String> keys) {
    for (final key in keys) {
      final value = product[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '-';
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
                    child: hasImage
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Center(
                                child: Icon(
                                  Icons.image_outlined,
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
              color: Colors.black,
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
                  color: Colors.black,
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
    final username = getValue(['username']);
    final email = getValue(['email']);
    final bio = getValue(['bio']);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 45,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          loadProfile();
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // COVER
                      SizedBox(
                        width: double.infinity,
                        height: 230,
                        child: Image.asset(
                          'assets/london.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: const Color(0xFFE8E8E8),
                              child: const Icon(
                                Icons.image_outlined,
                                size: 45,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // PROFILE IMAGE
                            Transform.translate(
                              offset: const Offset(0, -60),
                              child: CircleAvatar(
                                radius: 74,
                                backgroundColor: Colors.white,
                                backgroundImage: profile['image'] != null &&
                                        profile['image'].toString().isNotEmpty
                                    ? NetworkImage(profile['image'].toString())
                                    : const AssetImage('assets/humster.jpg') as ImageProvider,
                              ),
                            ),
                            // USERNAME + EDIT PROFILE
                            Transform.translate(
                              offset: const Offset(0, -40),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      username,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: textDark,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProfilePage(
                                            profile: profile,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        await loadProfile();
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textDark,
                                      side: const BorderSide(
                                        color: Color(0xFFD8DCE2),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      'Edit Profile',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                           // EMAIL
                            Transform.translate(
                              offset: const Offset(0, -30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: textGrey,
                                    ),
                                  ),

                                  // BIO
                                  if (bio != '-' && bio.trim().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      bio,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // JUMLAH PRODUK
                            Row(
                              children: [
                                Text(
                                  '${products.length}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Produk',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: textGrey,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // PRODUK SAYA
                            Text(
                              'Produk Saya',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Container(
                              width: 70,
                              height: 2,
                              decoration: BoxDecoration(
                                color: textDark,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // PRODUCT GRID
                            if (products.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 40,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Belum ada produk.',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: products.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 13,
                                      mainAxisSpacing: 15,
                                      childAspectRatio: 0.58,
                                    ),
                                itemBuilder: (context, index) {
                                  return productCard(products[index]);
                                },
                              ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
