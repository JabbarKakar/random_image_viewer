# Random Image Viewer

Random Image Viewer is a powerful and highly customizable Flutter widget that allows developers to effortlessly display images from various sources, including local assets, files, and network URLs. This widget supports multiple image formats and provides built-in zooming, rotation, error handling, caching, borders, tap detection, and customization options, making it an all-in-one solution for managing images in Flutter apps.

## Features

### Supports Multiple Image Formats
Display images in various formats with full compatibility:

- Vector & Raster Images: SVG, PNG, JPG, JPEG
- Animated & Web Optimized: GIF, WebP
- High-Quality & Professional Formats: BMP, TIFF, ICO, HEIC
- Network & Local Image Handling

### Interactive Controls
- Enable zooming with InteractiveViewer for various image formats
- Control zoom levels using maxScale and minScale properties
- Enable image rotation with gestures or programmatic controls
- Set initial rotation angle and track rotation changes

### Custom Appearance
- Custom placeholder widget while images are loading
- Custom error widget when images fail to load
- Background color for image container
- Fully customizable loading indicators

### Gesture Support
- Add a tap gesture with the onTap callback
- Double-tap zoom functionality
- Rotation gesture support
- Detect various user interactions effortlessly

### Fully Customizable
Modify appearance with:
- Height & Width (responsive sizing)
- BoxFit Options (contain, cover, fill, etc.)
- Borders & Border Radius (for rounded images)
- Alignment & Margins (for positioning)

### Optimized Performance with Caching
- Uses CachedNetworkImage for efficient network image caching
- Reduces redundant loading and improves performance

## Installation

Add the package to your pubspec.yaml file:

```yaml
dependencies:
  random_image_viewer: latest_version
```

Then, run `flutter pub get` to install the package.

## Usage Examples

To use Random Image Viewer in your Flutter app, first import the package:

```dart
import 'package:random_image_viewer/random_image_viewer.dart';
```

Before we dive into the details, you should know that you can use Random Image Viewer in different ways:

### Displaying Local & Network Images

```dart
RandomImageViewer(
  imagePath: "assets/images/sample.png", // Local asset image
  height: 200,
  width: 200,
  fit: BoxFit.cover,
)
```

```dart
RandomImageViewer(
  imagePath: "https://www.example.com/sample.jpg", // Network image
  height: 200,
  width: 200,
  enableZoom: true, // Enable zooming
)
```

```dart
Uint8List? imageBytes = File.bytes;

RandomImageViewer(
  imageBytes: imageBytes, // load image from memory (Uint8List)
  height: 200,
  width: 200,
  enableRotation: true, // Enable image rotation
)
```

### Using Custom Placeholder and Error Widgets

```dart
RandomImageViewer(
  imagePath: "https://www.example.com/large_image.jpg",
  height: 300,
  width: 300,
  placeholderWidget: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 8),
        Text("Loading image..."),
      ],
    ),
  ),
  errorWidget: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image, size: 64, color: Colors.red),
        Text("Could not load image"),
      ],
    ),
  ),
)
```

### Adding Background Color

```dart
RandomImageViewer(
  imagePath: "assets/images/transparent_logo.png",
  height: 200,
  width: 200,
  backgroundColor: Colors.lightBlue.withOpacity(0.2),
)
```

### Enabling Image Rotation

```dart
RandomImageViewer(
  imagePath: "assets/images/sample.jpg",
  height: 300,
  width: 300,
  enableRotation: true,
  initialRotation: 0.0,
  onRotationChanged: (angle) {
    print('Current rotation: $angle degrees');
  },
)
```

### Displaying Various Image Formats

GIF

```dart
RandomImageViewer(
  enableZoom: true,
  maxScale: 2.0,
  height: 200,
  imagePath: "assets/images/animation.gif",
)
```

BMP (Local)

```dart
RandomImageViewer(
  imagePath: "assets/images/sample.bmp",
  height: 200,
  width: 200,
)
```

TIFF (Local)

```dart
RandomImageViewer(
  imagePath: "assets/images/sample.tiff",
  height: 200,
  width: 200,
)
```

Try the remaining by yourself with different properties/parameters

## Handling Errors Gracefully

```dart
RandomImageViewer(
  imagePath: "invalid/path/to/image.jpg", // Invalid path
  height: 200,
  width: 200,
  errorIcon: Icons.broken_image,
  errorColor: Colors.red,
)
```

## Customization Options

| Property           | Description |
|--------------------|-------------|
| `imagePath`        | Path to the image (asset, file, or network URL) |
| `imageBytes`       | Uint8List holding the image data |
| `height` & `width` | Define image dimensions |
| `fit`              | Control image fitting (`BoxFit.contain`, `BoxFit.cover`, etc.) |
| `enableZoom`       | Enable pinch-to-zoom (`true/false`) |
| `maxScale` & `minScale` | Define zoom levels for InteractiveViewer |
| `enableRotation`   | Enable image rotation (`true/false`) |
| `initialRotation`  | Set starting rotation angle in degrees |
| `onRotationChanged`| Callback that receives current rotation angle |
| `backgroundColor`  | Background color for the image container |
| `placeholderWidget`| Custom widget to display while loading |
| `errorWidget`      | Custom widget to display on error |
| `onTap`            | Callback when image is tapped |
| `margin`           | Adds padding around the image |
| `border`           | Adds a border around the image |
| `radius`           | Adds rounded corners |
| `errorIcon`        | Custom icon to show when the image fails to load |
| `errorColor`       | Custom color for the error icon |
| `loaderHeight` & `loaderWidth` | Customize loading indicator size |
| `strokeWidth`      | Adjusts the thickness of the loader |


## Related Packages

- `cached_network_image` - Used for caching network images
- `flutter_svg` - Used for displaying SVG images

## License
This package is open-source and available under the MIT License.

## Perfect for Any Flutter App!

Whether you're building an e-commerce app, a social media feed, or a document viewer, Random Image Viewer makes handling images simple and efficient.
