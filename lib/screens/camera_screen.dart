import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/detection_result.dart';
import '../services/food_detector.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final FoodDetector _foodDetector = FoodDetector();
  List<DetectionResult> _detections = [];
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() => _errorMessage = 'No cameras found on this device.');
      return;
    }

    final cameraDescription = widget.cameras.first;
    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to initialise camera: $e');
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _controller = controller;
      _errorMessage = null;
    });
  }

  Future<void> _detectFood() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _detections = [];
    });

    try {
      final XFile image = await controller.takePicture();
      final results = await _foodDetector.detectFood(image.path);
      if (mounted) {
        setState(() => _detections = results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detection error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _foodDetector.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorScreen(_errorMessage!);
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CameraPreviewFitted(controller: controller),
            _buildTopBanner(),
            _buildDetectionOverlay(),
            _buildCaptureButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            'SeeFood 🍕',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionOverlay() {
    if (_detections.isEmpty && !_isProcessing) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Analysing…',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              )
            : _buildLabelsList(),
      ),
    );
  }

  Widget _buildLabelsList() {
    if (_detections.isEmpty) {
      return const Text(
        'No food detected. Try pointing at food! 🤔',
        style: TextStyle(color: Colors.white70, fontSize: 14),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Detected food:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._detections.map(
          (d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    d.label,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                _ConfidenceBadge(confidence: d.confidence),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _isProcessing ? null : _detectFood,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isProcessing ? Colors.grey.shade700 : Colors.white,
              border: Border.all(color: Colors.white38, width: 4),
              boxShadow: [
                if (!_isProcessing)
                  const BoxShadow(
                    color: Colors.white30,
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: _isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt,
                    size: 32,
                    color: Colors.black87,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Fills the available space with the camera preview, cropping the sides when
/// necessary to cover the full area (similar to CSS `object-fit: cover`).
class _CameraPreviewFitted extends StatelessWidget {
  final CameraController controller;

  const _CameraPreviewFitted({required this.controller});

  @override
  Widget build(BuildContext context) {
    // previewSize reports native dimensions; on many devices it is always in
    // landscape orientation, so we always use the larger value as width.
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    final isLandscape = previewSize.width > previewSize.height;
    final previewWidth = isLandscape ? previewSize.width : previewSize.height;
    final previewHeight = isLandscape ? previewSize.height : previewSize.width;

    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewWidth,
          height: previewHeight,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

/// Pill-shaped badge that shows the confidence value with colour coding.
class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final color = confidence >= 0.8
        ? Colors.green
        : confidence >= 0.6
            ? Colors.yellow.shade700
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '${(confidence * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
