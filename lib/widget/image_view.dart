import 'dart:io';
import 'package:flutter/material.dart';
import '../styles.dart';

class ImageView extends StatelessWidget {
  final File? file;

  const ImageView({super.key, this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      color: Colors.blueGrey,
      child: (file == null)
          ? _pickAnImageWidget()
          : Image.file(file!, fit: BoxFit.cover),
    );
  }

  Widget _pickAnImageWidget() {
    return const Center(
        child: Text(
      'Pick an image.',
      style: kAnalyzingTextStyle,
    ));
  }
}
