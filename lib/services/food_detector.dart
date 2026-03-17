import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../models/detection_result.dart';

/// Keywords used to filter labels to food-related ones.
const List<String> _foodKeywords = [
  'food',
  'cuisine',
  'dish',
  'meal',
  'fruit',
  'vegetable',
  'meat',
  'bread',
  'cake',
  'pizza',
  'burger',
  'sushi',
  'salad',
  'soup',
  'dessert',
  'snack',
  'drink',
  'beverage',
  'rice',
  'pasta',
  'chicken',
  'beef',
  'fish',
  'seafood',
  'cheese',
  'egg',
  'milk',
  'coffee',
  'tea',
  'juice',
  'chocolate',
  'candy',
  'cookie',
  'potato',
  'tomato',
  'apple',
  'banana',
  'orange',
  'sandwich',
  'noodle',
  'tofu',
  'mushroom',
  'broccoli',
  'corn',
  'taco',
  'burrito',
  'waffle',
  'pancake',
  'donut',
  'muffin',
];

/// Service responsible for classifying food items in images using ML Kit.
class FoodDetector {
  final ImageLabeler _imageLabeler;

  FoodDetector()
      : _imageLabeler = ImageLabeler(
          options: ImageLabelerOptions(confidenceThreshold: 0.5),
        );

  /// Analyse the image at [imagePath] and return food-related detections,
  /// sorted by descending confidence.
  Future<List<DetectionResult>> detectFood(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final labels = await _imageLabeler.processImage(inputImage);

    final foodLabels = labels.where((label) {
      final lower = label.label.toLowerCase();
      return _foodKeywords.any((keyword) => lower.contains(keyword));
    }).toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    return foodLabels
        .map(
          (label) => DetectionResult(
            label: label.label,
            confidence: label.confidence,
          ),
        )
        .toList();
  }

  void dispose() {
    _imageLabeler.close();
  }
}
