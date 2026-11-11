import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fe/services/api.dart';

class AddProductPage extends StatefulWidget {
  final Future<void> Function()? onProductAdded;

  const AddProductPage({super.key, this.onProductAdded});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();
  final _deskripsiController = TextEditingController();

  XFile? _image;
  Uint8List? _imageBytes;

  int? _selectedCategoryId;
  String? _selectedCondition;
  bool _isLoading = false;

  final Map<int, String> _categories = {
    1: 'Dresses',
    2: 'Tops',
    3: 'Bags',
    4: 'Shoes',
    5: 'Accessories',
    6: 'Outerwear',
  };

  final List<String> _conditions = ['Like New', 'Good', 'Well Loved'];

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // PILIH SUMBER GAMBAR
  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pilih Foto Produk',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // PILIH GAMBAR
  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();

      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          _showMessage(
            'Izin kamera ditolak. Aktifkan melalui pengaturan aplikasi.',
          );
          await openAppSettings();
        } else {
          _showMessage('Izin kamera diperlukan.');
        }
        return;
      }
    }

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        if (!mounted) return;

        setState(() {
          _image = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal memilih gambar: $e');
    }
  }

  // INPUT DECORATION
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE98568)),
      ),
    );
  }

  // LABEL
  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (required) const Text(' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  // TEXT FIELD
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: _inputDecoration(hint),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label wajib diisi';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  // TAMBAH PRODUK
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_image == null || _imageBytes == null) {
      _showMessage('Silakan pilih foto produk terlebih dahulu.');
      return;
    }

    final harga = int.tryParse(_hargaController.text);
    final stok = int.tryParse(_stokController.text);

    if (harga == null || harga <= 0) {
      _showMessage('Harga harus lebih dari 0.');
      return;
    }

    if (stok == null || stok < 0) {
      _showMessage('Stok tidak boleh kurang dari 0.');
      return;
    }

    if (_selectedCategoryId == null || _selectedCondition == null) {
      _showMessage('Lengkapi kategori dan kondisi produk.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await ApiServices.getUserIdFromToken();

      await ApiServices.uploadImage(
        '/posts',
        {
          'userId': userId,
          'nama': _namaController.text.trim(),
          'categoryId': _selectedCategoryId,
          'harga': harga,
          'stok': stok,
          'deskripsi': _deskripsiController.text.trim(),
          'kondisi': _selectedCondition!,
        },
        _imageBytes!,
        _image!.name,
      );

      if (!mounted) return;

      // Kosongkan form
      setState(() {
        _namaController.clear();
        _hargaController.clear();
        _stokController.clear();
        _deskripsiController.clear();

        _selectedCategoryId = null;
        _selectedCondition = null;
        _image = null;
        _imageBytes = null;
      });

      // Kembali ke Home
      _showMessage('Produk berhasil ditambahkan!');
      await widget.onProductAdded?.call();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal menambahkan produk: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        title: Text(
          'Tambah Produk',
          style: GoogleFonts.dmSans(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Foto Produk', required: true),

              GestureDetector(
                onTap: _showImageOptions,
                child: Container(
                  width: double.infinity,
                  height: 190,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 38,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tambah Foto Produk',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Kamera atau galeri',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_imageBytes!, fit: BoxFit.cover),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _image = null;
                                      _imageBytes = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              _buildTextField(
                label: 'Nama Produk',
                hint: 'Contoh: Basic White Shirt',
                controller: _namaController,
              ),

              const SizedBox(height: 18),

              _buildLabel('Kategori', required: true),

              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: _inputDecoration('Pilih kategori'),
                validator: (value) {
                  if (value == null) {
                    return 'Silakan pilih kategori produk';
                  }
                  return null;
                },
                items: _categories.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: GoogleFonts.dmSans(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
              ),

              const SizedBox(height: 18),

              _buildTextField(
                label: 'Harga',
                hint: 'Masukkan harga produk',
                controller: _hargaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 18),

              _buildTextField(
                label: 'Stok',
                hint: 'Masukkan jumlah stok',
                controller: _stokController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 18),

              _buildLabel('Kondisi Produk', required: true),

              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: _inputDecoration('Pilih kondisi'),
                validator: (value) {
                  if (value == null) {
                    return 'Silakan pilih kondisi produk';
                  }
                  return null;
                },
                items: _conditions.map((condition) {
                  return DropdownMenuItem<String>(
                    value: condition,
                    child: Text(
                      condition,
                      style: GoogleFonts.dmSans(fontSize: 14),
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
                hint: 'Ceritakan detail produk...',
                controller: _deskripsiController,
                required: false,
                maxLines: 4,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    disabledBackgroundColor: Colors.grey.shade300,
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
                          'Tambah Produk',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
