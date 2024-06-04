import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'MLInterpreter/tf_lite_interpreter.dart';
import 'Style/styles.dart';

const _labelsFileName = 'assets/labels.txt';
const _modelFileName = 'model_unquant.tflite';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

enum _ResultStatus {
  notStarted,
  notFound,
  found,
}

class _MainScreenState extends State<MainScreen> {
  bool _isAnalyzing = false;
  final picker = ImagePicker();
  File? _selectedImageFile;

  // Result
  _ResultStatus _resultStatus = _ResultStatus.notStarted;
  String _plantLabel = ''; // Name of Error Message
  double _accuracy = 0.0;

  late TFLiteInterpreter _classifier;

  @override
  void initState() {
    super.initState();
    _loadClassifier();
  }

  Future<void> _loadClassifier() async {
    debugPrint(
      'Start loading of Classifier with '
          'labels at $_labelsFileName, '
          'model at $_modelFileName',
    );

    final classifier = await TFLiteInterpreter.loadWith(
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
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: _titleWidget(),
          ),
          const SizedBox(height: 20),
          _photoViewWidget(),
          const SizedBox(height: 10),
          _resultViewWidget(),
          const Spacer(flex: 5),
          _pickPhotoButtonWidget(
            title: 'Take a photo',
            source: ImageSource.camera,
          ),
          _pickPhotoButtonWidget(
            title: 'Pick from camera roll',
            source: ImageSource.gallery,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _titleWidget() {
    return const Text(
      'Who\'s That Superhero?',
      style: kTitleTextStyle,
      textAlign: TextAlign.center,
    );
  }

  Widget _photoViewWidget() {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        ImageView(file: _selectedImageFile),
        _analyzingTextWidget(),
      ],
    );
  }

  Widget _analyzingTextWidget() {
    if (!_isAnalyzing) {
      return const SizedBox.shrink();
    }
    return const Text('Analyzing...', style: kAnalyzingTextStyle);
  }

  Widget _pickPhotoButtonWidget({
    required ImageSource source,
    required String title,
  }) {
    return TextButton(
      onPressed: () => _onPickPhoto(source),
      child: Container(
        width: 300,
        height: 50,
        color: colorSuperheroRed,
        child: Center(
            child: Text(title,
                style: const TextStyle(
                  fontFamily: robotoFont,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: colorSuperheroYellow,
                ))),
      ),
    );
  }

  void _onPickPhoto(ImageSource source) async {
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

  Widget _resultViewWidget() {
    var title = '';

    if (_resultStatus == _ResultStatus.notFound) {
      title = 'Failed to recognise';
    } else if (_resultStatus == _ResultStatus.found) {
      title = _plantLabel;
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
          : Image.file(file!, fit: BoxFit.contain),
    );
  }

  Widget _pickAnImageWidget() {
    return const Center(
        child: Text(
          'Pick a Superhero image ...',
          textAlign: TextAlign.center,
          style: kAnalyzingTextStyle,
        ));
  }
}

