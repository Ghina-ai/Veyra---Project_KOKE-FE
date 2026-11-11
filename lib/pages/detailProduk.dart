import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fe/pages/keranjang.dart';

class DetailProdukPage extends StatelessWidget {
  final Map<String, dynamic> product;
  final int currentUserId;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

  const DetailProdukPage({
    super.key,
    required this.product,
    required this.currentUserId,
    this.onEdit,
    this.onDelete,
  });

  final Color black = const Color(0xFF222222);
  final Color coral = const Color(0xFFE98568);

  TextStyle get textStyle => GoogleFonts.dmSans();

  String formatRupiah(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final formatted = number.toStringAsFixed(0);

    return 'Rp ${formatted.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  void addToBag(BuildContext context) {
    CartService.addProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produk berhasil ditambahkan ke bag!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void buyNow(BuildContext context) {
    CartService.addProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produk ditambahkan ke bag. Silakan lanjutkan checkout.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Hapus Produk?',
            style: textStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah kamu yakin ingin menghapus produk ini?',
            style: textStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Batal',
                style: textStyle.copyWith(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Hapus',
                style: textStyle.copyWith(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && onDelete != null) {
      await onDelete!();

      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nama = product['nama']?.toString() ?? 'Produk';
    final String kategori = product['kategori']?.toString() ?? 'Fashion';
    final String kondisi = product['kondisi']?.toString() ?? 'Like New';
    final String deskripsi =
        product['deskripsi']?.toString() ?? 'Tidak ada deskripsi';
    final String gambar = product['gambar']?.toString() ?? '';
    final String harga = formatRupiah(product['harga'] ?? 0);
    final String stok = product['stok']?.toString() ?? '0';

    final int productUserId = int.tryParse(product['userId'].toString()) ?? -1;

    final bool isOwner = productUserId == currentUserId;

    return Scaffold(
      backgroundColor: Colors.white,

      // APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 19,
            color: Color(0xFF222222),
          ),
        ),
        title: Text(
          'Detail Product',
          style: textStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: black,
          ),
        ),
      ),

      // BOTTOM BUTTONS
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 13, 18, 15),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => addToBag(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Add to Bag',
                        style: textStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => buyNow(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Buy Now',
                        style: textStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PRODUCT IMAGE FULL WIDTH
            SizedBox(
              width: double.infinity,
              height: 340,
              child: gambar.isNotEmpty
                  ? Image.network(
                      gambar,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: const Color(0xFFF5F5F5),
                          child: const Icon(
                            Icons.image_outlined,
                            size: 55,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFFF5F5F5),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 55,
                        color: Colors.grey,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 19, 20, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CATEGORY + MENU TITIK TIGA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        kategori,
                        style: textStyle.copyWith(
                          fontSize: 11,
                          color: coral,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (isOwner)
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Color(0xFF555555),
                          ),
                          color: Colors.white,
                          elevation: 4,
                          onSelected: (value) async {
                            if (value == 'edit') {
                              if (onEdit != null) {
                                await onEdit!();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Fitur edit belum dihubungkan.',
                                    ),
                                  ),
                                );
                              }
                            } else if (value == 'delete') {
                              if (onDelete != null) {
                                await confirmDelete(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Fitur hapus belum dihubungkan.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Color(0xFF555555),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('Edit', style: textStyle),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Hapus',
                                    style: textStyle.copyWith(
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // CONDITION
                  Row(
                    children: [
                      const SizedBox(width: 5),
                      Text(
                        kondisi,
                        style: textStyle.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF7CA58B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  // PRODUCT NAME + RATING
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          nama,
                          style: textStyle.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFE8B94F),
                        size: 19,
                      ),
                      Text(
                        '4.8',
                        style: textStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  // PRICE
                  Text(
                    harga,
                    style: textStyle.copyWith(
                      fontSize: 20,
                      color: coral,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 19),

                  // STOCK CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF777F8A),
                          size: 19,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Stock',
                          style: textStyle.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF777F8A),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$stok Items',
                          style: textStyle.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 21),

                  // DESCRIPTION
                  Text(
                    'Description',
                    style: textStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: black,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    deskripsi,
                    style: textStyle.copyWith(
                      fontSize: 12,
                      height: 1.7,
                      color: const Color(0xFF858585),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
