import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../classifier.dart';
import '../styles.dart';
import 'image_view.dart';

const _labelsFileName = 'assets/labels.txt';
const _modelFileName = 'model_unquant.tflite';

class ImageRecognizer extends StatefulWidget {
  const ImageRecognizer({super.key});

  @override
  State<ImageRecognizer> createState() => _ImageRecognizerState();
}

enum _ResultStatus {
  notStarted,
  notFound,
  found,
}

class _ImageRecognizerState extends State<ImageRecognizer> {
  bool _isAnalyzing = false;
  final picker = ImagePicker();
  File? _selectedImageFile;

  // Result
  _ResultStatus _resultStatus = _ResultStatus.notStarted;
  String _plantLabel = ''; // Name of Error Message
  double _accuracy = 0.0;

  late Classifier _classifier;

  @override
  void initState() {
    super.initState();
    _loadImageClassifier();
  }

  Future<void> _loadImageClassifier() async {
    debugPrint(
      'Start loading of image classifier with '
      'labels at $_labelsFileName, '
      'model at $_modelFileName',
    );

    final classifier = await Classifier.loadWith(
      labelsFileName: _labelsFileName,
      modelFileName: _modelFileName,
    );
    _classifier = classifier!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBgColor,
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Text(
              'Plant Recogniser',
              style: kTitleTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          _imageWidget(),
          const SizedBox(height: 10),
          _recognizeImageResultWidget(),
          const Spacer(flex: 5),
          _selectImageButtonWidget(
            title: 'Take a photo.',
            source: ImageSource.camera,
          ),
          _selectImageButtonWidget(
            title: 'Select from Camera Roll.',
            source: ImageSource.gallery,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _imageWidget() {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        ImageView(file: _selectedImageFile),
        _analyzingMessageWidget(),
      ],
    );
  }

  Widget _analyzingMessageWidget() {
    if (!_isAnalyzing) {
      return const SizedBox.shrink();
    }
    return const Text('Analyzing...', style: kAnalyzingTextStyle);
  }

  Widget _selectImageButtonWidget({
    required ImageSource source,
    required String title,
  }) {
    return TextButton(
      onPressed: () => _onSelectImage(source),
      child: Container(
        width: 300,
        height: 50,
        color: kColorBrown,
        child: Center(
            child: Text(title,
                style: const TextStyle(
                  fontFamily: kButtonFont,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: kColorLightYellow,
                ))),
      ),
    );
  }

  void _onSelectImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) {
      return;
    }

    final imageFile = File(pickedFile.path);

    setState(() {
      _selectedImageFile = imageFile;
    });

    _analyzeImage(imageFile);
  }

  void _analyzeImage(File image) {
    setState(() {
      _isAnalyzing = true;
    });

    final imageInput = img.decodeImage(image.readAsBytesSync())!;
    final resultCategory = _classifier.predict(imageInput);

    final result = resultCategory.score >= 0.8
        ? _ResultStatus.found
        : _ResultStatus.notFound;
    final plantLabel = resultCategory.label;
    final accuracy = resultCategory.score;

    setState(() {
      _isAnalyzing = false;
    });

    setState(() {
      _resultStatus = result;
      _plantLabel = plantLabel;
      _accuracy = accuracy;
    });
  }

  Widget _recognizeImageResultWidget() {
    var title = '';

    if (_resultStatus == _ResultStatus.notFound) {
      title = 'Fail to recognise';
    } else if (_resultStatus == _ResultStatus.found) {
      title = _plantLabel;
    } else {
      title = '';
    }

    var accuracyLabel = '';

    if (_resultStatus == _ResultStatus.found) {
      accuracyLabel = 'Accuracy: ${(_accuracy * 100).toStringAsFixed(2)}%';
    }

    return Column(
      children: [
        Text(title, style: kResultTextStyle),
        const SizedBox(height: 10),
        Text(accuracyLabel, style: kResultRatingTextStyle)
      ],
    );
  }
}
