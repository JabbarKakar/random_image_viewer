library random_image_viewer;

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class RandomImageViewer extends StatefulWidget {
  final String? imagePath;
  final Uint8List? imageBytes;
  final double? height;
  final double? width;
  final double? maxScale;
  final double? mimScale;
  final Color? color;
  final Color? errorColor;
  final Color? backgroundColor;
  final Color? progressIndicatorColor;
  final BoxFit? fit;
  final Alignment? alignment;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? radius;
  final BoxBorder? border;
  final bool enableZoom;
  final bool doubleTapZoom;
  final bool enableRotation; // New property to enable/disable rotation
  final double initialRotation; // New property for initial rotation angle
  final double strokeWidth;
  final double? loaderHeight;
  final double? loaderWidth;
  final IconData? errorIcon;
  final Widget? placeholderWidget;
  final Widget? errorWidget;
  final Function(double)?
  onRotationChanged; // New callback for rotation changes

  const RandomImageViewer({
    super.key,
    this.imagePath,
    this.imageBytes,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.margin,
    this.radius,
    this.border,
    this.maxScale,
    this.mimScale,
    this.enableZoom = false,
    this.doubleTapZoom = false,
    this.enableRotation = false, // Disabled by default
    this.initialRotation = 0.0, // No rotation by default
    this.strokeWidth = 4,
    this.loaderHeight,
    this.loaderWidth,
    this.errorColor,
    this.errorIcon,
    this.placeholderWidget,
    this.errorWidget,
    this.backgroundColor,
    this.onRotationChanged,
    this.progressIndicatorColor,
  });

  @override
  State<RandomImageViewer> createState() => _RandomImageViewerState();
}

class _RandomImageViewerState extends State<RandomImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  double _rotation = 0.0; // Current rotation angle in radians

  @override
  void initState() {
    super.initState();
    _rotation =
        widget.initialRotation * (math.pi / 180); // Convert degrees to radians
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = _buildImageBasedOnType();

    // Apply rotation if enabled
    if (widget.enableRotation) {
      imageWidget = GestureDetector(
        onPanUpdate: (details) {
          if (details.delta.dx != 0 || details.delta.dy != 0) {
            // Calculate angle from center to touch point
            final Offset centerOffset = Offset(
              (widget.width ?? 200) / 2,
              (widget.height ?? 200) / 2,
            );
            final double angle = _calculateRotationAngle(
              details.localPosition,
              centerOffset,
              details.delta,
            );

            setState(() {
              _rotation += angle;
              // Notify callback if provided
              if (widget.onRotationChanged != null) {
                widget.onRotationChanged!(
                  _rotation * (180 / math.pi),
                ); // Convert to degrees for callback
              }
            });
          }
        },
        child: Transform.rotate(angle: _rotation, child: imageWidget),
      );
    }

    if (widget.enableZoom) {
      imageWidget = InteractiveViewer(
        transformationController: _transformationController,
        maxScale: widget.maxScale ?? 2.0,
        minScale: widget.mimScale ?? 0.8,
        child: imageWidget,
      );
    }

    Widget tappableImage = GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: widget.doubleTapZoom
          ? (details) => _doubleTapDetails = details
          : null,
      onDoubleTap: widget.doubleTapZoom ? _handleDoubleTap : null,
      child: Container(
        height: widget.height,
        width: widget.width,
        color: widget.backgroundColor,
        child: imageWidget,
      ),
    );

    Widget paddedImage = Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: tappableImage,
    );

    return widget.alignment != null
        ? Align(
            alignment: widget.alignment!,
            child: _buildCircleImage(context, paddedImage),
          )
        : _buildCircleImage(context, paddedImage);
  }

  // Calculate rotation angle based on gesture
  double _calculateRotationAngle(Offset position, Offset center, Offset delta) {
    // Get the vector from center to touch point
    final Offset vector = position - center;

    // Calculate angle change based on movement direction and distance from center
    double angle = 0;
    if (vector.distance > 0) {
      // Clockwise or counterclockwise rotation based on screen position
      final double angleSign = vector.dy > 0 ? 1 : -1;
      angle =
          (delta.dx / 150) *
          angleSign *
          math.pi /
          32; // Adjust sensitivity here
    }

    return angle;
  }

  // Method to programmatically rotate the image
  void rotateImage(double degrees) {
    setState(() {
      _rotation = degrees * (math.pi / 180); // Convert to radians
      if (widget.onRotationChanged != null) {
        widget.onRotationChanged!(degrees);
      }
    });
  }

  // Method to rotate by 90 degrees clockwise
  void rotateClockwise() {
    rotateImage((_rotation * (180 / math.pi) + 90) % 360);
  }

  // Method to rotate by 90 degrees counterclockwise
  void rotateCounterclockwise() {
    rotateImage((_rotation * (180 / math.pi) - 90) % 360);
  }

  // Reset rotation to initial state
  void resetRotation() {
    rotateImage(widget.initialRotation);
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.0);
    }
  }

  Widget _buildImageBasedOnType() {
    // If imageBytes is provided, use it regardless of path
    if (widget.imageBytes != null) {
      return Image.memory(
        widget.imageBytes!,
        height: widget.height,
        width: widget.width,
        fit: widget.fit ?? BoxFit.contain,
        color: widget.color,
        colorBlendMode: widget.color != null ? BlendMode.modulate : null,
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorWidget(context),
      );
    }

    // Fallback to path-based handling
    switch (widget.imagePath?.imageType) {
      case ImageType.svg:
        return SvgPicture.asset(
          widget.imagePath!,
          height: widget.height,
          width: widget.width,
          color: widget.color,
          fit: widget.fit ?? BoxFit.contain,
        );
      case ImageType.file:
        return Image.file(
          File(widget.imagePath!),
          height: widget.height,
          width: widget.width,
          fit: widget.fit ?? BoxFit.contain,
          color: widget.color,
          colorBlendMode: widget.color != null ? BlendMode.modulate : null,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorWidget(context),
        );
      case ImageType.network:
        return CachedNetworkImage(
          imageUrl: widget.imagePath!,
          height: widget.height,
          width: widget.width,
          fit: widget.fit ?? BoxFit.contain,
          color: widget.color,
          colorBlendMode: widget.color != null ? BlendMode.modulate : null,
          placeholder: (context, url) => _buildPlaceholderWidget(),
          errorWidget: (context, url, error) => _buildErrorWidget(context),
        );
      case ImageType.gif:
        return widget.imagePath!.startsWith('http')
            ? Image.network(
                widget.imagePath!,
                height: widget.height,
                width: widget.width,
                fit: widget.fit ?? BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholderWidget();
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildErrorWidget(context),
              )
            : Image.asset(
                widget.imagePath!,
                height: widget.height,
                width: widget.width,
                fit: widget.fit ?? BoxFit.contain,
              );
      case ImageType.webp:
      case ImageType.bmp:
      case ImageType.tiff:
      case ImageType.ico:
      case ImageType.heic:
      case ImageType.jpg:
      case ImageType.jpeg:
      case ImageType.png:
      default:
        return Image.asset(
          widget.imagePath!,
          height: widget.height,
          width: widget.width,
          fit: widget.fit ?? BoxFit.contain,
          color: widget.color,
          colorBlendMode: widget.color != null ? BlendMode.modulate : null,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorWidget(context),
        );
    }
  }

  Widget _buildPlaceholderWidget() {
    return widget.placeholderWidget ??
        SizedBox(
          height: widget.loaderHeight,
          width: widget.loaderWidth,
          child: Center(
            child: CircularProgressIndicator(
              color: widget.progressIndicatorColor ?? Colors.blue,
              strokeWidth: widget.strokeWidth,
              strokeCap: StrokeCap.round,
            ),
          ),
        );
  }

  Widget _buildCircleImage(BuildContext context, Widget imageWidget) {
    return widget.radius != null
        ? ClipRRect(
            borderRadius: widget.radius!,
            child: _buildImageWithBorder(context, imageWidget),
          )
        : _buildImageWithBorder(context, imageWidget);
  }

  Widget _buildImageWithBorder(BuildContext context, Widget imageWidget) {
    if ((widget.imagePath == null || widget.imagePath!.isEmpty) &&
        widget.imageBytes == null) {
      return _buildErrorWidget(context); // Only show error if BOTH are null
    }

    return widget.border != null
        ? Container(
            decoration: BoxDecoration(
              border: widget.border,
              borderRadius: widget.radius,
              color: widget.backgroundColor,
            ),
            child: imageWidget,
          )
        : imageWidget;
  }

  Widget _buildErrorWidget(BuildContext context) {
    return widget.errorWidget ??
        Container(
          alignment: Alignment.center,
          color: widget.backgroundColor,
          child: Center(
            child: Icon(
              widget.errorIcon ?? Icons.error,
              color: widget.errorColor ?? Colors.red,
              size: 48,
            ),
          ),
        );
  }
}

// Example of a rotation control widget that can be used alongside RandomImageViewer
class RotationControls extends StatelessWidget {
  final _RandomImageViewerState viewerState;

  const RotationControls({Key? key, required this.viewerState})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.rotate_left),
          onPressed: viewerState.rotateCounterclockwise,
          tooltip: 'Rotate Left',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: viewerState.resetRotation,
          tooltip: 'Reset Rotation',
        ),
        IconButton(
          icon: const Icon(Icons.rotate_right),
          onPressed: viewerState.rotateClockwise,
          tooltip: 'Rotate Right',
        ),
      ],
    );
  }
}

extension ImageTypeExtension on String? {
  ImageType get imageType {
    if (this == null || this!.isEmpty) return ImageType.unknown;
    if (this!.startsWith('http') || this!.startsWith('https')) {
      if (this!.endsWith('.svg')) return ImageType.svg;
      if (this!.endsWith('.jpg') || this!.endsWith('.jpeg'))
        return ImageType.jpeg;
      if (this!.endsWith('.png')) return ImageType.png;
      if (this!.endsWith('.gif')) return ImageType.gif;
      if (this!.endsWith('.webp')) return ImageType.webp;
      if (this!.endsWith('.bmp')) return ImageType.bmp;
      if (this!.endsWith('.tiff') || this!.endsWith('.tif'))
        return ImageType.tiff;
      if (this!.endsWith('.ico')) return ImageType.ico;
      if (this!.endsWith('.heic') || this!.endsWith('.heif'))
        return ImageType.heic;
      return ImageType.network;
    } else if (this!.startsWith('/data/user/0/')) {
      return ImageType.file;
    } else {
      if (this!.endsWith('.svg')) return ImageType.svg;
      if (this!.endsWith('.jpg') || this!.endsWith('.jpeg'))
        return ImageType.jpeg;
      if (this!.endsWith('.png')) return ImageType.png;
      if (this!.endsWith('.gif')) return ImageType.gif;
      if (this!.endsWith('.webp')) return ImageType.webp;
      if (this!.endsWith('.bmp')) return ImageType.bmp;
      if (this!.endsWith('.tiff') || this!.endsWith('.tif'))
        return ImageType.tiff;
      if (this!.endsWith('.ico')) return ImageType.ico;
      if (this!.endsWith('.heic') || this!.endsWith('.heif'))
        return ImageType.heic;
      return ImageType.unknown;
    }
  }
}

enum ImageType {
  bytes,
  svg,
  png,
  jpg,
  jpeg,
  gif,
  webp,
  bmp,
  tiff,
  ico,
  heic,
  network,
  file,
  unknown,
}
