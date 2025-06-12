import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'package:mime/mime.dart';

class UploadLostPetScreen extends StatefulWidget {
  @override
  _UploadLostPetScreenState createState() => _UploadLostPetScreenState();
}

class _UploadLostPetScreenState extends State<UploadLostPetScreen> {
  File? _image;
  Uint8List? _imageBytes;
  final picker = ImagePicker();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isUploading = false;
  String _statusMessage = "";
  bool? _catDetected;
  double? _confidence;
  String? _detectionUrl;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _image = File(pickedFile.path);
        _imageBytes = bytes;
        _catDetected = null; // Reset detection status
        _confidence = null;
        _detectionUrl = null;
      });
    }
  }

  Future<void> _uploadData() async {
    if (_image == null && _imageBytes == null) {
      setState(() {
        _statusMessage = "Por favor, selecione uma imagem.";
      });
      return;
    }

    if (_nameController.text.isEmpty) {
      setState(() {
        _statusMessage = "Por favor, informe o nome do gato.";
      });
      return;
    }

    if (_contactController.text.isEmpty) {
      setState(() {
        _statusMessage = "Por favor, informe um contato.";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = "";
    });

    try {
      // Update this URL to your backend server address
      final uri = Uri.parse('http://10.0.2.2:5000/upload'); // For Android Emulator
      // final uri = Uri.parse('http://localhost:5000/upload'); // For web testing
      final request = http.MultipartRequest('POST', uri);

      final mimeType = lookupMimeType(_image?.path ?? '') ?? 'image/jpeg';

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          _imageBytes!,
          filename: 'lost_pet.jpg',
          contentType: MediaType.parse(mimeType),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image!.path,
          contentType: MediaType.parse(mimeType),
          filename: basename(_image!.path),
        ));
      }

      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['type'] = 'lost'; // Tipo "perdido"
      request.fields['contact'] = _contactController.text;

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Parse JSON response
        final jsonResponse = jsonDecode(respStr);
        
        setState(() {
          _catDetected = jsonResponse['cat_detected'];
          _confidence = jsonResponse['confidence']?.toDouble();
          _detectionUrl = jsonResponse['detection_url'];
          
          // Update status message based on cat detection
          if (_catDetected == true) {
            _statusMessage = "Gato detectado com ${(_confidence! * 100).toStringAsFixed(1)}% de confiança!";
          } else {
            _statusMessage = "Nenhum gato detectado na imagem.";
          }
          
          // Clear form only if successful upload
          _image = null;
          _imageBytes = null;
          _nameController.clear();
          _descriptionController.clear();
          _contactController.clear();
        });
      } else {
        setState(() {
          _statusMessage = "Erro ao enviar: ${respStr}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Erro ao enviar: $e";
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reportar gato perdido")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _image != null || _imageBytes != null
                      ? kIsWeb
                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                          : Image.file(_image!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 60,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Toque para adicionar uma foto do seu gato",
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Nome do Gato", 
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Descrição",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: "Contato",
                  border: OutlineInputBorder(),
                  hintText: "Telefone, email ou outro meio de contato",
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadData,
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Enviar"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _catDetected == true
                          ? Colors.green
                          : _catDetected == false
                              ? Colors.orange
                              : _statusMessage.contains("Erro")
                                  ? Colors.red
                                  : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // Show detection image if available
              if (_detectionUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Detecção:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Image.network(
                        _detectionUrl!,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}