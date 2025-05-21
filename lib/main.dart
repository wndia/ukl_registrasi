import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RegisterPage(),
  ));
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final namaController = TextEditingController();
  final alamatController = TextEditingController();
  final teleponController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String gender = "Laki-laki";

  Uint8List? _imageBytes;
  XFile? _pickedFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _pickedFile = pickedFile;
        });
      } else {
        setState(() {
          _pickedFile = pickedFile;
          _imageBytes = null;
        });
      }
    }
  }

  Future<void> _register() async {
    final uri = Uri.parse('https://learn.smktelkom-mlg.sch.id/ukl1/api/register');
    var request = http.MultipartRequest('POST', uri);

    request.fields['nama_nasabah'] = namaController.text;
    request.fields['gender'] = gender;
    request.fields['alamat'] = alamatController.text;
    request.fields['telepon'] = teleponController.text;
    request.fields['username'] = usernameController.text;
    request.fields['password'] = passwordController.text;

    if (_pickedFile != null) {
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'foto',
          await _pickedFile!.readAsBytes(),
          filename: _pickedFile!.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('foto', _pickedFile!.path));
      }
    }

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var data = jsonDecode(respStr);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Berhasil Register')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal Register: $respStr')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6A1B9A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 50, color: primaryColor),
                  const SizedBox(height: 12),
                  const Text(
                    "Registrasi Pengguna",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  _buildField(namaController, "Nama", Icons.person, color: primaryColor),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: gender,
                    items: const [
                      DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                      DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                    ],
                    onChanged: (value) => setState(() => gender = value!),
                    decoration: _inputDecoration("Gender", Icons.wc, color: primaryColor),
                  ),
                  const SizedBox(height: 12),
                  _buildField(alamatController, "Alamat", Icons.home, color: primaryColor),
                  const SizedBox(height: 12),
                  _buildField(teleponController, "Telepon", Icons.phone, keyboardType: TextInputType.phone, color: primaryColor),
                  const SizedBox(height: 12),
                  _buildField(usernameController, "Username", Icons.account_circle, color: primaryColor),
                  const SizedBox(height: 12),
                  _buildField(passwordController, "Password", Icons.lock, obscureText: true, color: primaryColor),
                  const SizedBox(height: 16),
                  if (_imageBytes != null || _pickedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _imageBytes != null
                          ? Image.memory(_imageBytes!, height: 100)
                          : Image.file(File(_pickedFile!.path), height: 100),
                    ),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text("Pilih Foto"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) _register();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("REGISTER", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Color color = Colors.deepPurple,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon, color: color),
      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Color color = Colors.deepPurple}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color),
      labelStyle: TextStyle(color: Colors.grey[800]),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1.8),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
