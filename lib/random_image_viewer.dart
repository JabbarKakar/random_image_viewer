/// A customizable Flutter widget for images from assets, files, network URLs, and memory.
library random_image_viewer;

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

/// Displays an image with optional zoom, rotation, borders, and loading or error widgets.
class RandomImageViewer extends StatefulWidget {
  /// Asset path, file path, or network URL of the image.
  final String? imagePath;

  /// Raw image bytes. Used instead of [imagePath] when set.
  final Uint8List? imageBytes;

  /// Height of the image.
  final double? height;

  /// Width of the image.
  final double? width;

  /// Largest zoom factor when [enableZoom] is true.
  final double? maxScale;

  /// Smallest zoom factor when [enableZoom] is true.
  final double? mimScale;

  /// Color blended over the image.
  final Color? color;

  /// Color of the default error icon.
  final Color? errorColor;

  /// Background color behind the image.
  final Color? backgroundColor;

  /// Color of the default loading indicator.
  final Color? progressIndicatorColor;

  /// How the image is inscribed into the given size.
  final BoxFit? fit;

  /// Alignment of the image inside its parent.
  final Alignment? alignment;

  /// Called when the image is tapped.
  final VoidCallback? onTap;

  /// Empty space around the image.
  final EdgeInsetsGeometry? margin;

  /// Corner radius applied to the image.
  final BorderRadius? radius;

  /// Border drawn around the image.
  final BoxBorder? border;

  /// Whether pinch-to-zoom is enabled.
  final bool enableZoom;

  /// Whether a double tap toggles zoom.
  final bool doubleTapZoom;

  /// Whether a drag gesture rotates the image.
  final bool enableRotation;

  /// Starting rotation in degrees.
  final double initialRotation;

  /// Stroke width of the default loading indicator.
  final double strokeWidth;

  /// Height of the default loading indicator.
  final double? loaderHeight;

  /// Width of the default loading indicator.
  final double? loaderWidth;

  /// Icon shown when the image fails to load and [errorWidget] is null.
  final IconData? errorIcon;

  /// Widget shown while a network or GIF image is loading.
  final Widget? placeholderWidget;

  /// Widget shown when the image cannot be loaded.
  final Widget? errorWidget;

  /// Called with the current rotation in degrees while the user rotates the image.
  final Function(double)? onRotationChanged;

  /// Creates an image viewer.
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

  /// Creates the mutable state for this widget.
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
      angle = (delta.dx / 150) *
          angleSign *
          math.pi /
          32; // Adjust sensitivity here
    }

    return angle;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(-position.dx * 1.5, -position.dy * 1.5, 0, 1)
        ..scaleByDouble(2, 2, 2, 1);
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
          colorFilter: widget.color == null
              ? null
              : ColorFilter.mode(widget.color!, BlendMode.srcIn),
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

/// Classifies an image path or URL by its source and file extension.
extension ImageTypeExtension on String? {
  /// The detected [ImageType] for this path.
  ImageType get imageType {
    if (this == null || this!.isEmpty) {
      return ImageType.unknown;
    }
    final value = this!;
    if (value.startsWith('http') || value.startsWith('https')) {
      return _imageTypeFromExtension(value, fallback: ImageType.network);
    } else if (value.startsWith('/data/user/0/')) {
      return ImageType.file;
    } else {
      return _imageTypeFromExtension(value, fallback: ImageType.unknown);
    }
  }
}

ImageType _imageTypeFromExtension(
  String value, {
  required ImageType fallback,
}) {
  if (value.endsWith('.svg')) {
    return ImageType.svg;
  }
  if (value.endsWith('.jpg') || value.endsWith('.jpeg')) {
    return ImageType.jpeg;
  }
  if (value.endsWith('.png')) {
    return ImageType.png;
  }
  if (value.endsWith('.gif')) {
    return ImageType.gif;
  }
  if (value.endsWith('.webp')) {
    return ImageType.webp;
  }
  if (value.endsWith('.bmp')) {
    return ImageType.bmp;
  }
  if (value.endsWith('.tiff') || value.endsWith('.tif')) {
    return ImageType.tiff;
  }
  if (value.endsWith('.ico')) {
    return ImageType.ico;
  }
  if (value.endsWith('.heic') || value.endsWith('.heif')) {
    return ImageType.heic;
  }
  return fallback;
}

/// How an image path is loaded.
enum ImageType {
  /// Image bytes already held in memory.
  bytes,

  /// An SVG asset or URL.
  svg,

  /// A PNG asset.
  png,

  /// A JPG asset.
  jpg,

  /// A JPEG asset or URL.
  jpeg,

  /// A GIF asset or URL.
  gif,

  /// A WebP asset or URL.
  webp,

  /// A BMP asset or URL.
  bmp,

  /// A TIFF asset or URL.
  tiff,

  /// An ICO asset or URL.
  ico,

  /// An HEIC or HEIF asset or URL.
  heic,

  /// A network URL whose format is not detected from the extension.
  network,

  /// A file on the local device.
  file,

  /// A path that could not be classified.
  unknown,
}
