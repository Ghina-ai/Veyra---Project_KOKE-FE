import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CartService {
  static final ValueNotifier<List<Map<String, dynamic>>> cartItems =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static void addProduct(Map<String, dynamic> product) {
    final items = List<Map<String, dynamic>>.from(cartItems.value);

    final productId = product['id'];

    final index = items.indexWhere((item) => item['id'] == productId);

    if (index != -1) {
      final oldQuantity = int.tryParse('${items[index]['quantity'] ?? 1}') ?? 1;

      items[index] = {...items[index], 'quantity': oldQuantity + 1};
    } else {
      items.add({...product, 'quantity': 1});
    }

    cartItems.value = items;
  }

  static void removeProduct(int index) {
    final items = List<Map<String, dynamic>>.from(cartItems.value);

    if (index < 0 || index >= items.length) return;

    items.removeAt(index);
    cartItems.value = items;
  }

  static void changeQuantity(int index, int amount) {
    final items = List<Map<String, dynamic>>.from(cartItems.value);

    if (index < 0 || index >= items.length) return;

    final oldQuantity = int.tryParse('${items[index]['quantity'] ?? 1}') ?? 1;

    final newQuantity = oldQuantity + amount;

    if (newQuantity < 1) return;

    items[index] = {...items[index], 'quantity': newQuantity};

    cartItems.value = items;
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Color coral = const Color.fromARGB(255, 0, 0, 0);

  final Set<int> selectedProducts = {};

  String formatRupiah(dynamic value) {
    final price = double.tryParse('$value') ?? 0;

    final formatted = price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }

  bool isSelected(int index) {
    return selectedProducts.contains(index);
  }

  bool get isAllSelected {
    final items = CartService.cartItems.value;

    return items.isNotEmpty && selectedProducts.length == items.length;
  }

  int get totalItems {
    final items = CartService.cartItems.value;
    int total = 0;

    for (final index in selectedProducts) {
      if (index >= 0 && index < items.length) {
        final quantity = int.tryParse('${items[index]['quantity'] ?? 1}') ?? 1;

        total += quantity;
      }
    }

    return total;
  }

  double get totalPrice {
    final items = CartService.cartItems.value;
    double total = 0;

    for (final index in selectedProducts) {
      if (index >= 0 && index < items.length) {
        final item = items[index];

        final price = double.tryParse('${item['harga'] ?? 0}') ?? 0;

        final quantity = int.tryParse('${item['quantity'] ?? 1}') ?? 1;

        total += price * quantity;
      }
    }

    return total;
  }

  void removeCartItem(int index) {
    setState(() {
      selectedProducts.remove(index);

      final updated = selectedProducts
          .map((i) => i > index ? i - 1 : i)
          .toSet();

      selectedProducts
        ..clear()
        ..addAll(updated);
    });

    CartService.removeProduct(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),

      // HEADER
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Keranjang',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: CartService.cartItems,
        builder: (context, items, child) {
          if (items.isEmpty) {
            selectedProducts.clear();
          } else {
            selectedProducts.removeWhere(
              (index) => index < 0 || index >= items.length,
            );
          }

          return Column(
            children: [
              // DAFTAR PRODUK
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // PILIH SEMUA PRODUK
                    Row(
                      children: [
                        Checkbox(
                          value: isAllSelected,
                          activeColor: coral,
                          onChanged: items.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedProducts.addAll(
                                        List.generate(
                                          items.length,
                                          (index) => index,
                                        ),
                                      );
                                    } else {
                                      selectedProducts.clear();
                                    }
                                  });
                                },
                        ),

                        Text(
                          'Pilih semua produk',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const Spacer(),

                        Text(
                          '${items.length} Produk',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // CARD PRODUK
                    if (items.isNotEmpty)
                      ...List.generate(items.length, (index) {
                        final item = items[index];

                        final imageUrl = item['gambar']?.toString() ?? '';

                        final quantity =
                            int.tryParse('${item['quantity'] ?? 1}') ?? 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.025),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),

                          child: Row(
                            children: [
                              // CHECKBOX PRODUK
                              Checkbox(
                                value: isSelected(index),
                                activeColor: coral,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedProducts.add(index);
                                    } else {
                                      selectedProducts.remove(index);
                                    }
                                  });
                                },
                              ),

                              // GAMBAR PRODUK
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 75,
                                  height: 85,
                                  color: const Color(0xFFF4F4F4),

                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) {
                                            return const Icon(
                                              Icons.image_outlined,
                                              color: Colors.grey,
                                            );
                                          },
                                        )
                                      : const Icon(
                                          Icons.checkroom_outlined,
                                          size: 35,
                                          color: Colors.grey,
                                        ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // DETAIL PRODUK
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nama']?.toString() ?? 'Produk',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 3),

                                    Text(
                                      item['kategori']?.toString() ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(height: 7),

                                    Text(
                                      formatRupiah(item['harga'] ?? 0),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // QUANTITY + DELETE
                                    Row(
                                      children: [
                                        _quantityButton(Icons.remove, () {
                                          CartService.changeQuantity(index, -1);
                                        }),

                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            '$quantity',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),

                                        _quantityButton(Icons.add, () {
                                          CartService.changeQuantity(index, 1);
                                        }),

                                        const Spacer(),

                                        GestureDetector(
                                          onTap: () {
                                            removeCartItem(index);
                                          },
                                          child: const Icon(
                                            Icons.delete_outline,
                                            size: 19,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),

              // TOTAL HARGA + CHECKOUT
              Container(
                padding: const EdgeInsets.fromLTRB(18, 15, 18, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),

                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Harga ($totalItems produk)',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),

                        Text(
                          formatRupiah(totalPrice),
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 13),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: totalItems == 0
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Fitur checkout belum dihubungkan.',
                                    ),
                                  ),
                                );
                              },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: coral,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        child: Text(
                          'Checkout',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 14, color: Colors.black87),
      ),
    );
  }
}
