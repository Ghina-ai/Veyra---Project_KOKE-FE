import 'package:fe/pages/keranjang.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fe/services/api.dart';

final ValueNotifier<int> favoriteChanged = ValueNotifier<int>(0);

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  int selectedCategory = 0;

  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';

  final List<String> categories = [
    'All',
    'Dresses',
    'Tops',
    'Bags',
    'Shoes',
    'Accessories',
    'Outerwear',
  ];

  List<Map<String, dynamic>> favorites = [];
  late Future<void> favoritesFuture;

  final Color black = const Color(0xFF222222);
  final Color grey = const Color(0xFF888888);

  TextStyle get textStyle => GoogleFonts.dmSans();

  @override
  void initState() {
    super.initState();

    favoritesFuture = fetchFavorites();
    favoriteChanged.addListener(onFavoriteChanged);
  }

  @override
  void dispose() {
    favoriteChanged.removeListener(onFavoriteChanged);
    searchController.dispose();
    super.dispose();
  }

  void onFavoriteChanged() {
    if (!mounted) return;

    setState(() {
      favoritesFuture = fetchFavorites();
    });
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

  // GET FAVORITES
  Future<void> fetchFavorites() async {
    final response = await ApiServices.get('/favorites');

    if (response['success'] == true) {
      final data = response['data'];
      final List items = data['favorites'] ?? [];

      favorites = items.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception(response['message'] ?? 'Gagal mengambil favorite');
    }
  }

  // FILTER CATEGORY + SEARCH
  List<Map<String, dynamic>> get filteredFavorites {
    return favorites.where((product) {
      final category = (product['kategori'] ?? '').toString().toLowerCase();

      final name = (product['nama'] ?? '').toString().toLowerCase();

      final description = (product['deskripsi'] ?? '').toString().toLowerCase();

      final query = searchQuery.toLowerCase().trim();

      // FILTER CATEGORY
      final matchesCategory =
          selectedCategory == 0 ||
          category == categories[selectedCategory].toLowerCase();

      // FILTER SEARCH
      final matchesSearch =
          query.isEmpty ||
          name.contains(query) ||
          category.contains(query) ||
          description.contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  // REMOVE FAVORITE
  Future<void> removeFavorite(int productId) async {
    try {
      await ApiServices.delete('/favorites/$productId');

      if (!mounted) return;

      setState(() {
        favorites.removeWhere(
          (product) => product['id'].toString() == productId.toString(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk dihapus dari Favorite', style: textStyle),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus favorite: $e')));
    }
  }

  // FORMAT PRICE
  String formatPrice(dynamic price) {
    final number = double.tryParse(price.toString()) ?? 0;
    final formatted = number.toStringAsFixed(0);

    final result = formatted.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $result';
  }

  // PRODUCT CARD
  Widget productCard(Map<String, dynamic> product) {
    final productId = int.tryParse(product['id'].toString());
    final image = product['gambar']?.toString();
    final name = product['nama']?.toString() ?? 'Produk';
    final brand = product['kategori']?.toString() ?? 'Fashion';
    final price = formatPrice(product['harga'] ?? 0);

    final hasImage = image != null && image.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F5F5),
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

              // FAVORITE BUTTON
              Positioned(
                top: 9,
                right: 9,
                child: Material(
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: productId == null
                        ? null
                        : () => removeFavorite(productId),
                      child: Icon(Icons.favorite, color: Colors.red, size: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // CATEGORY
        Text(
          brand,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle.copyWith(
            fontSize: 10,
            color: const Color(0xFF888888),
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
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textStyle.copyWith(
            fontSize: 12,
            color: black,
            fontWeight: FontWeight.w500,
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
        elevation: 0,
        centerTitle: false,
        title: Text(
          'My Favorites',
          style: textStyle.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: black,
          ),
        ),
      ),

      body: Column(
        children: [
          // SEARCH BAR
          Container(
            height: 43,
            margin: const EdgeInsets.fromLTRB(16, 5, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 21),
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

                // CLEAR SEARCH
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

          // CATEGORY FILTER
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final isSelected = selectedCategory == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? black : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? black : const Color(0xFFE5E5E5),
                      ),
                    ),
                    child: Text(
                      categories[index],
                      style: textStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // FAVORITE PRODUCTS
          Expanded(
            child: FutureBuilder<void>(
              future: favoritesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 40,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text('Gagal memuat Favorite', style: textStyle),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              favoritesFuture = fetchFavorites();
                            });
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final products = filteredFavorites;

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.favorite_border,
                          size: 55,
                          color: const Color(0xFFBBBBBB),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'Produk tidak ditemukan'
                              : 'No Favorites Yet',
                          style: textStyle.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: black,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'Coba kata kunci lainnya.'
                              : 'Produk yang kamu sukai akan muncul di sini.',
                          textAlign: TextAlign.center,
                          style: textStyle.copyWith(fontSize: 12, color: grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final future = fetchFavorites();
                    setState(() {
                      favoritesFuture = future;
                    });
                    await future;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 5, 16, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 22,
                          childAspectRatio: 0.58,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return productCard(products[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
