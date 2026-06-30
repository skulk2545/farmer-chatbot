import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jowar_disease_detection/core/utils/image_utils.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';
import 'package:jowar_disease_detection/features/prediction/data/models/prediction_model.dart';
import 'package:jowar_disease_detection/features/prediction/data/repositories/prediction_repository.dart';

class PredictionProvider extends ChangeNotifier {
  final PredictionRepository _repository = PredictionRepository();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  PredictionModel? _predictionResult;
  String? _errorMessage;

  File? get selectedImage => _selectedImage;
  bool get isLoading => _isLoading;
  double get uploadProgress => _uploadProgress;
  PredictionModel? get predictionResult => _predictionResult;
  String? get errorMessage => _errorMessage;

  /// Picks an image from the source (camera or gallery),
  /// applies automatic Native compression & orientation adjustment,
  /// and runs custom size & format validation rules.
  Future<void> pickImage(ImageSource source) async {
    _errorMessage = null;
    _predictionResult = null;
    notifyListeners();

    try {
      // Pick image with native resolution limit (max 1024) and 80% JPEG compression
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        LoggingService.info("Image pick cancelled by user.", tag: "PredictionProvider");
        return;
      }

      final File file = File(pickedFile.path);

      // 1. Validate File Extension
      if (!ImageUtils.validateExtension(file.path)) {
        _errorMessage = "Unsupported file format. Please upload JPG, JPEG or PNG.";
        notifyListeners();
        return;
      }

      // 2. Validate File Size (<10 MB)
      final bool isSizeOk = await ImageUtils.validateSize(file);
      if (!isSizeOk) {
        _errorMessage = "File size exceeds 10MB limit. Please upload a smaller image.";
        notifyListeners();
        return;
      }

      // 3. Validate Integrity (check corruption)
      final bool isIntact = await ImageUtils.validateIntegrity(file);
      if (!isIntact) {
        _errorMessage = "The selected image is corrupted or unreadable.";
        notifyListeners();
        return;
      }

      _selectedImage = file;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Failed to pick image: ${e.toString()}";
      LoggingService.error("Pick image error", tag: "PredictionProvider", error: e);
      notifyListeners();
    }
  }

  /// Uploads the selected image to the backend and triggers crop diagnosis.
  Future<void> diagnoseCrop() async {
    if (_selectedImage == null) {
      _errorMessage = "Please select an image first.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _uploadProgress = 0.0;
    _errorMessage = null;
    _predictionResult = null;
    notifyListeners();

    try {
      final PredictionModel result = await _repository.uploadAndDiagnose(
        imageFile: _selectedImage!,
        onProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            notifyListeners();
          }
        },
      );
      
      _predictionResult = result;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Resets the current prediction state.
  void reset() {
    _selectedImage = null;
    _isLoading = false;
    _uploadProgress = 0.0;
    _predictionResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}
