import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:jowar_disease_detection/core/api/api_service.dart';
import 'package:jowar_disease_detection/core/api/endpoints.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';
import 'package:jowar_disease_detection/features/prediction/data/models/prediction_model.dart';

class PredictionRepository {
  final ApiService _apiService = ApiService();

  /// Uploads a crop image to the FastAPI backend.
  /// Reports progress via [onProgress].
  /// On success, automatically caches the result in the local history Box.
  Future<PredictionModel> uploadAndDiagnose({
    required File imageFile,
    void Function(int sent, int total)? onProgress,
  }) async {
    LoggingService.info("Uploading image to backend...", tag: "PredictionRepository");
    
    // Parse filename without 'path' package to prevent import warning
    final String filename = imageFile.path.split(Platform.pathSeparator).last;

    try {
      // 1. Prepare multipart file payload
      final MultipartFile multipartFile = await MultipartFile.fromFile(
        imageFile.path,
        filename: filename,
      );

      final Map<String, dynamic> fields = {
        "image": multipartFile,
      };

      // 2. Perform POST request with progress callback
      final Response response = await _apiService.postMultipart(
        Endpoints.predict,
        fields: fields,
        onProgress: onProgress,
      );

      if (response.statusCode == 200 && response.data != null) {
        final PredictionModel result = PredictionModel.fromJson(response.data);
        
        // 3. Cache prediction locally in Hive history box
        await _cachePrediction(result, imageFile.path, filename);
        
        return result;
      } else {
        throw ServerException("Server returned status: ${response.statusCode}");
      }
    } catch (e) {
      LoggingService.error("Prediction upload failed", tag: "PredictionRepository", error: e);
      rethrow;
    }
  }

  /// Caches the prediction details locally in Hive box to support offline viewing.
  Future<void> _cachePrediction(PredictionModel result, String localPath, String filename) async {
    try {
      final historyBox = Hive.box('history');
      
      final String timestamp = DateTime.now().toIso8601String();
      final Map<String, dynamic> historyItem = {
        "id": DateTime.now().millisecondsSinceEpoch,
        "timestamp": timestamp,
        "filename": filename,
        "crop": result.crop,
        "disease": result.disease,
        "confidence": result.confidence,
        "image_path": localPath, // stores local file path for offline thumbnail rendering
        "details": result.toJson(),
      };
      
      await historyBox.add(historyItem);
      LoggingService.info("Prediction cached locally in history box.", tag: "PredictionRepository");
    } catch (e) {
      LoggingService.error("Failed to cache prediction locally", tag: "PredictionRepository", error: e);
    }
  }
}
