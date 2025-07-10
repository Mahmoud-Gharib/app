import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Uploader',
      home: GitHubUploader(),
    );
  }
}

class GitHubUploader extends StatefulWidget {
  @override
  _GitHubUploaderState createState() => _GitHubUploaderState();
}

class _GitHubUploaderState extends State<GitHubUploader> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _message = '';

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      setState(() {
        _message = 'No image selected.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    File imageFile = File(pickedFile.path);

    final String token = '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';
    final String repoOwner = 'Mahmoud-Gharib';
    final String repoName = 'app_upload';
    final String branch = 'main'; // or 'master'
    final String filePathInRepo = 'image/${path.basename(imageFile.path)}';

    final bytes = await imageFile.readAsBytes();
    final base64Content = base64Encode(bytes);

    final url = 'https://api.github.com/repos/$repoOwner/$repoName/contents/$filePathInRepo';

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      },
      body: jsonEncode({
        "message": "Upload ${path.basename(imageFile.path)} from Flutter",
        "content": base64Content,
        "branch": branch,
      }),
    );

    setState(() {
      _isLoading = false;
      if (response.statusCode == 201) {
        _message = '✅ Image uploaded successfully!';
      } else {
        _message = '❌ Upload failed: ${response.statusCode}\n${response.body}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Image to GitHub')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: _isLoading
              ? CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _pickAndUploadImage,
                      child: Text('Pick and Upload Image'),
                    ),
                    SizedBox(height: 20),
                    Text(_message),
                  ],
                ),
        ),
      ),
    );
  }
}
