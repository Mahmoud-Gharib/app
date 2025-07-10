import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 👈 مهم جدًا
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Image Uploader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: UploadImagePage(),
    );
  }
}

class UploadImagePage extends StatefulWidget {
  @override
  _UploadImagePageState createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  File? _image;
  bool _uploading = false;
  String _status = '';

  final String repoOwner = 'mahmoud-gharib';
  final String repoName = 'app_upload';
  final String repoFolder = 'image';

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _status = '';
      });
    }
  }

  Future<void> uploadImageToGitHub(File imageFile) async {
    setState(() {
      _uploading = true;
      _status = 'Uploading...';
    });

    try {
      final githubToken = dotenv.env['GITHUB_TOKEN'];
      if (githubToken == null) {
        setState(() => _status = '❌ Token not found!');
        return;
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${basename(imageFile.path)}';
      final imageBytes = await imageFile.readAsBytes();
      final contentBase64 = base64Encode(imageBytes);

      final url = Uri.parse(
          'https://api.github.com/repos/$repoOwner/$repoName/contents/$repoFolder/$fileName');

      final body = jsonEncode({
        'message': 'Upload image from Flutter app',
        'content': contentBase64,
      });

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github.v3+json',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        setState(() => _status = '✅ Uploaded successfully!');
      } else {
        setState(() => _status = '❌ Failed: ${response.body}');
      }
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Image to GitHub')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_image != null)
                Image.file(_image!, width: 200, height: 200, fit: BoxFit.cover),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.image),
                label: Text('Pick Image'),
                onPressed: pickImage,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.cloud_upload),
                label:
                    Text(_uploading ? 'Uploading...' : 'Upload to GitHub'),
                onPressed: _image != null && !_uploading
                    ? () => uploadImageToGitHub(_image!)
                    : null,
              ),
              SizedBox(height: 20),
              Text(_status),
            ],
          ),
        ),
      ),
    );
  }
}
