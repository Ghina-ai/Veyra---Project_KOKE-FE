import 'package:fe/pages/detailProduk.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fe/services/api.dart';

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

  bool isLoading = true;
  String? errorMessage;
  int? userId;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final id = await ApiServices.getUserIdFromToken();

      userId = id;

      // Ambil profil dan produk user
      final response = await ApiServices.getProfile(id);
      final data = response['data'];

      if (data is! Map) {
        throw Exception('Format data profil tidak sesuai.');
      }

      final userData = data['user'];
      final postsData = data['posts'];

      if (userData is Map) {
        profile = Map<String, dynamic>.from(userData);
      } else {
        throw Exception('Data pengguna tidak ditemukan.');
      }

      products = postsData is List ? postsData : [];

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

  Widget buildProductCard(dynamic item) {
    final product = Map<String, dynamic>.from(item);

    final image = productValue(product, [
      'gambar',
      'imageUrl',
      'image',
      'foto',
    ]);

    final name = productValue(product, ['nama', 'name', 'title']);
    final brand = product['kategori']?.toString() ?? 'Fashion';
    final price = productValue(product, ['harga', 'price']);

    final formattedPrice = price == '-'
        ? '-'
        : 'Rp ${price.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';

    return InkWell(
      onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DetailProdukPage(product: product, currentUserId: userId!),
        ),
      );
    },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PRODUCT IMAGE
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF5F5F5),
                child: image != '-'
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

          const SizedBox(height: 8),

          // CATEGORY
          Text(
            brand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: const Color(0xFF888888),
            ),
          ),

          const SizedBox(height: 4),

          // RATING
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFE8B94F),
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                '4.8',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: const Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '(120 ulasan)',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: const Color(0xFF999999),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          // PRODUCT NAME
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: textDark,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 5),

          // PRICE
          Text(
            formattedPrice,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = getValue(['username']);
    final email = getValue(['email']);

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
                              child: const CircleAvatar(
                                radius: 74,
                                backgroundColor: Colors.white,
                                backgroundImage: AssetImage(
                                  'assets/humster.jpg',
                                ),
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
                                    onPressed: () {},
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
                              child: Text(
                                email,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: textGrey,
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

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
                                  return buildProductCard(products[index]);
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
