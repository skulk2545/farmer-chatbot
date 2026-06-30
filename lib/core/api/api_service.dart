import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:jowar_disease_detection/core/api/endpoints.dart';
import 'package:jowar_disease_detection/core/services/logging_service.dart';

// --- Custom Domain Exceptions ---

abstract class AppException implements Exception {
  final String message;
  final String? details;
  AppException(this.message, [this.details]);
  
  @override
  String toString() => message;
}

class TimeoutException extends AppException {
  TimeoutException([String? details]) : super("Request timed out. Please check your internet connection.", details);
}

class NetworkException extends AppException {
  NetworkException([String? details]) : super("Unable to connect to the server. Please check if the server is running.", details);
}

class ServerException extends AppException {
  ServerException([String? details]) : super("Internal server error occurred. Please try again later.", details);
}

class ValidationException extends AppException {
  ValidationException([String? details]) : super("Invalid request data format.", details);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String? details]) : super("Unauthorized access. Please check server credentials.", details);
}

class NotFoundException extends AppException {
  NotFoundException([String? details]) : super("Requested API endpoint not found.", details);
}

class UnknownException extends AppException {
  UnknownException([String? details]) : super("An unexpected error occurred. Please check network connection.", details);
}

// --- Exponential Backoff Retry Interceptor ---

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final int delayMultiplierMs;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.delayMultiplierMs = 1000,
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    
    // Check if error is transient (timeouts, connection issues, or socket exception)
    final bool isTransientError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.unknown && err.error is SocketException);

    int retryCount = requestOptions.extra['retry_count'] ?? 0;

    if (isTransientError && retryCount < maxRetries) {
      retryCount++;
      requestOptions.extra['retry_count'] = retryCount;
      
      // Calculate backoff delay: 1s, 4s, 9s...
      final int delayMs = retryCount * retryCount * delayMultiplierMs;
      LoggingService.warning(
        "Retrying request ${requestOptions.path} ($retryCount/$maxRetries) in ${delayMs}ms due to transient error: ${err.message}",
        tag: "RetryInterceptor"
      );
      
      await Future.delayed(Duration(milliseconds: delayMs));

      try {
        // Re-execute request
        final response = await dio.request(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          cancelToken: requestOptions.cancelToken,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
            contentType: requestOptions.contentType,
            extra: requestOptions.extra,
          ),
          onSendProgress: requestOptions.onSendProgress,
          onReceiveProgress: requestOptions.onReceiveProgress,
        );
        return handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          // If the retry also fails, continue the chain
          return super.onError(e, handler);
        }
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}

// --- Reusable Central ApiService ---

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ));

    // Add backoff retry interceptor
    _dio.interceptors.add(RetryInterceptor(dio: _dio));

    // Custom logger interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Resolve dynamic base URL from Hive on every request
        final box = Hive.box('settings');
        final String savedUrl = box.get('backend_url', defaultValue: Endpoints.baseDefaultUrl);
        options.baseUrl = savedUrl;
        
        LoggingService.info("Request [${options.method}] -> ${options.baseUrl}${options.path}", tag: "ApiService");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        LoggingService.info("Response [${response.statusCode}] <- ${response.requestOptions.path}", tag: "ApiService");
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        LoggingService.error("API Error [${e.response?.statusCode}] <- ${e.requestOptions.path}: ${e.message}", tag: "ApiService", error: e.error);
        return handler.next(e);
      }
    ));
  }

  /// Converts DioExceptions to custom AppExceptions
  AppException _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return TimeoutException(error.message);
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          final dynamic data = error.response?.data;
          final String details = data != null ? data.toString() : "";
          if (status == 401) {
            return UnauthorizedException(details);
          } else if (status == 404) {
            return NotFoundException(details);
          } else if (status == 422) {
            return ValidationException(details);
          } else if (status == 500) {
            return ServerException(details);
          }
          return ServerException("Server returned status: $status. $details");
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return NetworkException(error.message);
          }
          return UnknownException(error.message);
        default:
          return UnknownException(error.message);
      }
    }
    return UnknownException(error.toString());
  }

  // --- GET Request ---
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- POST Request ---
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- Multipart File Upload Request ---
  Future<Response> postMultipart(
    String path, {
    required Map<String, dynamic> fields,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap(fields);
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }
}
