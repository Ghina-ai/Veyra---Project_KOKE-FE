import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fe/services/api.dart';

class EditProdukPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final Future<void> Function()? onProductUpdated;

  const EditProdukPage({
    super.key,
    required this.product,
    this.onProductUpdated,
  });

  @override
  State<EditProdukPage> createState() => _EditProdukPageState();
}

class _EditProdukPageState extends State<EditProdukPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();
  final _deskripsiController = TextEditingController();

  XFile? _image;
  Uint8List? _imageBytes;

  int? _selectedCategoryId;
  String? _selectedCondition;

  bool _isLoading = false;

  final Color primaryColor = const Color.fromARGB(255, 0, 0, 0);
  final Color textColor = const Color.fromARGB(255, 0, 0, 0);

  final Map<int, String> categories = {
    1: 'Dresses',
    2: 'Tops',
    3: 'Bags',
    4: 'Shoes',
    5: 'Accessories',
    6: 'Outerwear',
  };

  final List<String> conditions = ['Like New', 'Good', 'Well Loved'];

  String get oldImage {
    return widget.product['gambar']?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _namaController.text = product['nama']?.toString() ?? '';

    _hargaController.text =
        product['harga']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';

    _stokController.text = product['stok']?.toString() ?? '';

    _deskripsiController.text = product['deskripsi']?.toString() ?? '';

    _selectedCategoryId = int.tryParse(product['categoryId']?.toString() ?? '');

    // Jika categoryId tidak tersedia, cocokkan dari nama kategori.
    if (_selectedCategoryId == null) {
      final kategori = product['kategori']?.toString();

      for (final entry in categories.entries) {
        if (entry.value == kategori) {
          _selectedCategoryId = entry.key;
          break;
        }
      }
    }

    final kondisi = product['kondisi']?.toString();

    if (conditions.contains(kondisi)) {
      _selectedCondition = kondisi;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : primaryColor,
      ),
    );
  }

  // PILIH GAMBAR
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();

      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          _showMessage(
            'Izin kamera ditolak. Silakan aktifkan melalui pengaturan.',
            error: true,
          );
          await openAppSettings();
        } else {
          _showMessage('Izin kamera diperlukan.', error: true);
        }
        return;
      }
    }

    try {
      final pickedImage = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedImage != null) {
        final bytes = await pickedImage.readAsBytes();

        setState(() {
          _image = pickedImage;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      _showMessage('Gagal memilih gambar: $e', error: true);
    }
  }

  // INPUT DECORATION
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor),
      ),
    );
  }

  // LABEL
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // TEXT FIELD
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 13, color: textColor),
          decoration: _inputDecoration(hint),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label tidak boleh kosong';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  // SIMPAN PERUBAHAN
  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      _showMessage('Silakan pilih kategori produk.', error: true);
      return;
    }

    if (_selectedCondition == null) {
      _showMessage('Silakan pilih kondisi produk.', error: true);
      return;
    }

    final productId = int.tryParse(widget.product['id']?.toString() ?? '');

    if (productId == null) {
      _showMessage('ID produk tidak valid.', error: true);
      return;
    }

    final harga = int.tryParse(
      _hargaController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );

    final stok = int.tryParse(_stokController.text);

    if (harga == null || stok == null) {
      _showMessage('Harga dan stok harus berupa angka.', error: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiServices.updateImage(
        '/posts/$productId',
        {
          'nama': _namaController.text.trim(),
          'categoryId': _selectedCategoryId,
          'harga': harga,
          'stok': stok,
          'deskripsi': _deskripsiController.text.trim(),
          'kondisi': _selectedCondition,
        },
        imageBytes: _imageBytes,
        imageName: _image?.name,
      );

      Map<String, dynamic>? updatedPost;

      if (response is Map) {
        final data = response['data'];

        if (data is Map && data['post'] is Map) {
          updatedPost = Map<String, dynamic>.from(data['post']);
        }
      }

      if (widget.onProductUpdated != null) {
        await widget.onProductUpdated!();
      }

      if (!mounted) return;

      _showMessage('Produk berhasil diperbarui!');

      Navigator.pop(context, updatedPost);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal memperbarui produk: ${e.toString()}', error: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Produk',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FOTO PRODUK
              _buildLabel('Foto Produk'),
              GestureDetector(
                onTap: _showImageOptions,
                child: Container(
                  width: double.infinity,
                  height: 190,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _imageBytes != null
                        ? Image.memory(
                            _imageBytes!,
                            width: double.infinity,
                            height: 190,
                            fit: BoxFit.cover,
                          )
                        : oldImage.isNotEmpty
                        ? Image.network(
                            oldImage,
                            width: double.infinity,
                            height: 190,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _imagePlaceholder();
                            },
                          )
                        : _imagePlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              _buildTextField(
                label: 'Nama Produk',
                hint: 'Masukkan nama produk',
                controller: _namaController,
              ),

              _buildTextField(
                label: 'Harga',
                hint: 'Masukkan harga produk',
                controller: _hargaController,
                keyboardType: TextInputType.number,
              ),

              _buildTextField(
                label: 'Stok',
                hint: 'Masukkan jumlah stok',
                controller: _stokController,
                keyboardType: TextInputType.number,
              ),

              // KATEGORI
              _buildLabel('Kategori'),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: _inputDecoration('Pilih kategori'),
                items: categories.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: 18),

              // KONDISI
              _buildLabel('Kondisi Produk'),
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: _inputDecoration('Pilih kondisi'),
                items: conditions.map((condition) {
                  return DropdownMenuItem<String>(
                    value: condition,
                    child: Text(
                      condition,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value;
                  });
                },
              ),
              const SizedBox(height: 18),

              _buildTextField(
                label: 'Deskripsi',
                hint: 'Masukkan deskripsi produk',
                controller: _deskripsiController,
                maxLines: 4,
              ),

              const SizedBox(height: 10),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, size: 35, color: primaryColor),
        const SizedBox(height: 8),
        Text(
          'Ketuk untuk mengganti foto',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
