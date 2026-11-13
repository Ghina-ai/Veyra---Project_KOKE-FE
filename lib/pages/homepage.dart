import 'package:fe/pages/categorry.dart';
import 'package:fe/pages/detailProduk.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fe/pages/editProduct.dart';

import 'package:fe/services/api.dart';
import 'package:fe/pages/like.dart';
import 'package:fe/pages/keranjang.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<int> favoriteIds = {};
  int selectedGender = 0;
  int? currentUserId;

  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';

  final Color black = const Color(0xFF222222);
  final Color grey = const Color(0xFFF5F5F5);

  TextStyle get textStyle => GoogleFonts.dmSans();

  late Future<List<Map<String, dynamic>>> productsFuture;

  @override
  void initState() {
    super.initState();

    productsFuture = fetchProducts();
    fetchFavoriteIds();
    getCurrentUser();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // GET CURRENT USER
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

  // GET FAVORITES
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

  // TOGGLE FAVORITE
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah Favorite: $e')));
    }
  }

  // REFRESH PRODUCTS
  void refreshProducts() {
    setState(() {
      productsFuture = fetchProducts();
    });
  }

  // GET PRODUCTS
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await ApiServices.get('/posts');

    if (response is Map && response['success'] == true) {
      final data = response['data'];

      if (data is Map && data['posts'] is List) {
        return List<Map<String, dynamic>>.from(
          (data['posts'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
      }
    }

    throw Exception('Gagal mengambil data produk');
  }

  // OPEN PRODUCT DETAIL
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

          // EDIT PRODUK
          onEdit: () async {
            final updatedProduct = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (context) => EditProdukPage(product: product),
              ),
            );

            if (!mounted) return;

            if (updatedProduct != null) {
              product.addAll(updatedProduct);

              refreshProducts();

              // Tutup halaman detail
              Navigator.pop(context);
            }
          },

          // HAPUS PRODUK
          onDelete: () async {
            await ApiServices.delete('/posts/${product['id']}');

            refreshProducts();
          },
        ),
      ),
    );
  }

  // FILTER SEARCH
  List<Map<String, dynamic>> filterProducts(
    List<Map<String, dynamic>> products,
  ) {
    if (searchQuery.trim().isEmpty) {
      return products;
    }

    final query = searchQuery.toLowerCase().trim();

    return products.where((product) {
      final name = (product['nama'] ?? '').toString().toLowerCase();

      final category = (product['kategori'] ?? '').toString().toLowerCase();

      final description = (product['deskripsi'] ?? '').toString().toLowerCase();

      return name.contains(query) ||
          category.contains(query) ||
          description.contains(query);
    }).toList();
  }

  // FORMAT RUPIAH
  String formatRupiah(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final formatted = number.toStringAsFixed(0);

    return 'Rp ${formatted.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  // CATEGORY ITEM
  Widget categoryItem(String image, String title) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryPage(category: title),
          ),
        );
      },
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Icon(Icons.image_outlined, color: Colors.grey);
                  },
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // GENDER BUTTON
  Widget genderButton(String title, int index) {
    final selected = selectedGender == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = index;
        });
      },
      child: Container(
        height: 39,
        decoration: BoxDecoration(
          color: selected ? black : const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            title,
            style: textStyle.copyWith(
              color: selected ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // SECTION TITLE
  Widget sectionTitle(String title) {
    return Text(
      title,
      style: textStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: black,
      ),
    );
  }

  // ADD TO CART
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

  // TRENDING PRODUCTS
  Widget trendingProducts() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF222222)),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 150,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_outlined,
                    color: Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gagal memuat produk',
                    style: textStyle.copyWith(fontSize: 12, color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: refreshProducts,
                    child: Text(
                      'Coba Lagi',
                      style: textStyle.copyWith(color: black, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final allProducts = snapshot.data ?? [];
        final products = filterProducts(allProducts);

        if (products.isEmpty) {
          return SizedBox(
            height: 150,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 35, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    searchQuery.isEmpty
                        ? 'Belum ada produk tersedia'
                        : 'Produk tidak ditemukan',
                    style: textStyle.copyWith(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  Text(
                    'asos',
                    style: textStyle.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 14),

              // SEARCH BAR
              Container(
                height: 43,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        style: textStyle.copyWith(fontSize: 12, color: black),
                        decoration: InputDecoration(
                          hintText: 'Search for brands, styles...',
                          hintStyle: textStyle.copyWith(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          searchController.clear();

                          setState(() {
                            searchQuery = '';
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // PROMO BANNER
              Container(
                height: 165,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEAEA),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // BACKGROUND IMAGE
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 155,
                      child: Image.asset(
                        'assets/promosi.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),

                    // GRADIENT OVERLAY
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              const Color(0xFFEAEAEA),
                              const Color(0xFFEAEAEA).withOpacity(0.95),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.48, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // TEXT CONTENT
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: 165,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),

                              child: Text(
                                'NEW COLLECTION',
                                style: textStyle.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: black,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              'Find Your Style',
                              style: textStyle.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: black,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              'Discover pieces made for your everyday look.',
                              style: textStyle.copyWith(
                                fontSize: 9,
                                color: const Color(0xFF555555),
                              ),
                            ),

                            const SizedBox(height: 11),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // CATEGORY
              sectionTitle('Category'),
              const SizedBox(height: 12),

              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    categoryItem('assets/Dress.png', 'Dresses'),
                    const SizedBox(width: 15),

                    categoryItem('assets/Tops.png', 'Tops'),
                    const SizedBox(width: 15),

                    categoryItem('assets/Shoes.png', 'Shoes'),
                    const SizedBox(width: 15),

                    categoryItem('assets/accessories.png', 'Accessories'),
                    const SizedBox(width: 15),

                    categoryItem('assets/Bag.png', 'Bags'),
                    const SizedBox(width: 15),

                    categoryItem('assets/outerware.png', 'Outerware'),
                  ],
                ),
              ),

              const SizedBox(height: 23),

              // TRENDING NOW
              sectionTitle(
                searchQuery.isEmpty ? 'Trending Now' : 'Search Results',
              ),

              const SizedBox(height: 14),

              trendingProducts(),
            ],
          ),
        ),
      ),
    );
  }
}
