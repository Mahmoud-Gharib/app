import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Image Uploader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: UploadImageScreen(),
    );
  }
}

class UploadImageScreen extends StatefulWidget {
  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _image;
  bool _uploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _uploadToGitHub() async {
    if (_image == null) return;

    setState(() => _uploading = true);

    final token = "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";
    final repo = "Mahmoud-Gharib/app_upload";
    final branch = "main"; // or master
    final fileName = basename(_image!.path);
    final imageBytes = await _image!.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final url = "https://api.github.com/repos/$repo/contents/$fileName";

    final response = await http.put(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/vnd.github+json",
      },
      body: jsonEncode({
        "message": "Add image $fileName",
        "branch": branch,
        "content": base64Image,
      }),
    );

    setState(() => _uploading = false);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Image uploaded to GitHub")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Image to GitHub')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (_image != null) Image.file(_image!, height: 200),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text("📁 Pick Image"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploading ? null : _uploadToGitHub,
                child: _uploading ? CircularProgressIndicator() : Text("⬆️ Upload to GitHub"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
