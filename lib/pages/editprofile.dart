import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fe/services/api.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfilePage({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController usernameController;
  late TextEditingController bioController;

  Uint8List? selectedImageBytes;
  String? selectedImageName;

  bool isLoading = false;

  final Color textDark = const Color(0xFF20242B);
  final Color inputColor = const Color(0xFFF5F6F8);

  @override
  void initState() {
    super.initState();

    usernameController = TextEditingController(
      text: widget.profile['username']?.toString() ?? '',
    );

    bioController = TextEditingController(
      text: widget.profile['bio']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        selectedImageBytes = bytes;
        selectedImageName = image.name;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: $e')),
      );
    }
  }

  Widget buildProfileImage() {
    final imageUrl = widget.profile['image']?.toString();

    ImageProvider? imageProvider;

    if (selectedImageBytes != null) {
      imageProvider = MemoryImage(selectedImageBytes!);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl);
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 82,
          backgroundColor: const Color(0xFFE5E7EB),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(
                  Icons.person,
                  size: 75,
                  color: Color(0xFF9CA3AF),
                )
              : null,
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: GestureDetector(
            onTap: isLoading ? null : pickImage,
            child: Container(
              width: 55,
              height: 55,
              decoration: const BoxDecoration(
                color: Color(0xFF20242B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 29,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 13),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: label == 'Bio' ? 150 : null,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            color: textDark,
          ),
          validator: (value) {
            if (label == 'Username' &&
                (value == null || value.trim().isEmpty)) {
              return 'Username tidak boleh kosong';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              color: const Color(0xFF777777),
              fontSize: 15,
            ),
            filled: true,
            fillColor: inputColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: Color(0xFF20242B),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiServices.updateImage(
        '/users/profile',
        {
          'username': usernameController.text.trim(),
          'bio': bioController.text.trim(),
        },
        imageBytes: selectedImageBytes,
        imageName: selectedImageName,
      );

      if (response is Map && response['success'] != true) {
        throw Exception(
          response['message'] ?? 'Gagal memperbarui profil',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile berhasil diperbarui!'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 21,
            color: Colors.black,
          ),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 45, 22, 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    buildProfileImage(),
                    const SizedBox(height: 22),
                    Text(
                      'Tap photo to change',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 65),

              buildInput(
                label: 'Username',
                hint: 'Masukkan username',
                controller: usernameController,
              ),

              const SizedBox(height: 30),

              buildInput(
                label: 'Bio',
                hint: 'Ceritakan tentang kamu...',
                controller: bioController,
                maxLines: 4,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20242B),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.dmSans(
                            fontSize: 17,
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
