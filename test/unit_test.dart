import 'package:flutter_test/flutter_test.dart';
import 'package:jowar_disease_detection/core/utils/image_utils.dart';

void main() {
  group('ImageUtils Unit Tests', () {
    test('validateExtension returns true for supported formats', () {
      expect(ImageUtils.validateExtension("leaf_spot.jpg"), isTrue);
      expect(ImageUtils.validateExtension("rust_leaves.jpeg"), isTrue);
      expect(ImageUtils.validateExtension("healthy_panicle.png"), isTrue);
    });

    test('validateExtension returns false for unsupported formats', () {
      expect(ImageUtils.validateExtension("dataset.zip"), isFalse);
      expect(ImageUtils.validateExtension("readme.md"), isFalse);
      expect(ImageUtils.validateExtension("crop_disease_model.h5"), isFalse);
      expect(ImageUtils.validateExtension("script.py"), isFalse);
    });
  });
}
