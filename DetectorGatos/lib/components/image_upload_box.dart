import 'dart:io';
import 'package:flutter/material.dart';

class ImageUploadBox extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  final double height;
  final double width;

  const ImageUploadBox({
    Key? key,
    required this.image,
    required this.onTap,
    this.height = 200,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!, width: 1),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 50,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Toque para adicionar foto",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}