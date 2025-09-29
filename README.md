# Custom Page Flip with Pinch Zoom

A Flutter package for creating smooth page flip animations with integrated pinch-to-zoom functionality. Perfect for creating digital magazines, photo albums, PDF viewers, and interactive books.

## Features

- ✨ **Smooth flip page transition** with customizable animation curves
- 🔍 **Integrated pinch-to-zoom** with no gesture conflicts
- 📱 **Smart gesture detection** - distinguishes between swipe and zoom gestures
- 🎯 **Multi-touch support** - handles multiple simultaneous touch points correctly
- 📄 **Multiple pages support** with last page customization
- ⚙️ **Highly configurable** - animation duration, swipe direction, and thresholds
- 🎨 **Custom transformation controllers** for per-page zoom management
- 🔊 **Event callbacks** for page changes and flip events
- 🎮 **Optional navigation buttons** for manual page control
- 🪶 **Lightweight and easy to integrate**

## Getting Started

Add this package as a dependency in your `pubspec.yaml`:

```yaml
dependencies:
  flip_curl_animation_widget: <latest_version>
```

Import the package:

```dart
import 'package:custom_page_flip/custom_page_flip.dart';
```

## Basic Usage

### Simple Implementation

```dart
CustomPageFlip(
  children: List.generate(
    10,
    (index) => Container(
      color: Colors.primaries[index % Colors.primaries.length],
      child: Center(
        child: Text(
          'Page ${index + 1}',
          style: TextStyle(fontSize: 48, color: Colors.white),
        ),
      ),
    ),
  ),
  onPageChanged: (index) {
    print('Current page: ${index + 1}');
  },
)
```

### Advanced Implementation with PDF and Zoom

```dart
class MagazineViewer extends StatefulWidget {
  @override
  _MagazineViewerState createState() => _MagazineViewerState();
}

class _MagazineViewerState extends State<MagazineViewer> {
  final PdfController pdfController = Get.put(PdfController());
  final GlobalKey<CustomPageFlipState> pageFlipKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPageFlip(
        key: pageFlipKey,
        showControllerButton: true,
        transformationControllerBuilder: (index) =>
            pdfController.getTransformationController(index),
        children: List.generate(
          pdfController.pagesBytes.length,
          (index) {
            final pageData = pdfController.pagesBytes[index];
            return Container(
              color: Colors.grey[300],
              child: pageData != null
                  ? Image.memory(
                      pageData,
                      fit: BoxFit.contain,
                    )
                  : Center(
                      child: CircularProgressIndicator(),
                    ),
            );
          },
        ),
        onPageChanged: (index) {
          pdfController.playFlipSound();
          pdfController.updateCurrentPage(index);
        },
        onFlipStart: () {
          print('Flip animation started');
        },
        onPageFlipped: (pageNumber) {
          print('Flipped to page: $pageNumber');
        },
      ),
    );
  }
}
```

### PdfController Example (GetX)

```dart
class PdfController extends GetxController {
  var pagesBytes = <Uint8List>[].obs;
  var currentPage = 1.obs;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Store TransformationController for each page
  final Map<int, TransformationController> transformationControllers = {};

  @override
  void onInit() {
    super.onInit();
    _audioPlayer.setAsset('assets/flip.mp3');
  }

  TransformationController getTransformationController(int pageIndex) {
    if (!transformationControllers.containsKey(pageIndex)) {
      transformationControllers[pageIndex] = TransformationController();
    }
    return transformationControllers[pageIndex]!;
  }

  void resetZoom(int pageIndex) {
    if (transformationControllers.containsKey(pageIndex)) {
      transformationControllers[pageIndex]!.value = Matrix4.identity();
    }
  }

  void playFlipSound() {
    _audioPlayer.seek(Duration.zero);
    _audioPlayer.play();
  }

  void updateCurrentPage(int index) {
    currentPage.value = index + 1;
    // Reset zoom on adjacent pages
    if (index > 0) resetZoom(index - 1);
    if (index < pagesBytes.length - 1) resetZoom(index + 1);
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    transformationControllers.values.forEach((c) => c.dispose());
    super.onClose();
  }
}
```

## Parameters

| Parameter                             | Type                                         | Description                                                | Default          |
|---------------------------------------|----------------------------------------------|------------------------------------------------------------|------------------|
| `children`                            | `List<Widget>`                               | **Required**. List of widgets to display as pages          | -                |
| `transformationControllerBuilder`     | `TransformationController Function(int)?`    | **Required**. Builder for per-page zoom controllers        | -                |
| `duration`                            | `Duration`                                   | Duration of the flip animation                             | 450ms            |
| `cutoffForward`                       | `double`                                     | Threshold to trigger forward page flip (0.0-1.0)           | 0.8              |
| `cutoffPrevious`                      | `double`                                     | Threshold to trigger backward page flip (0.0-1.0)          | 0.1              |
| `backgroundColor`                     | `Color`                                      | Background color during animation                          | `Colors.white`   |
| `initialIndex`                        | `int`                                        | Initial page index to display                              | 0                |
| `lastPage`                            | `Widget?`                                    | Optional widget to show on the last page                   | null             |
| `isRightSwipe`                        | `bool`                                       | Flip direction (true for right-to-left swipe)              | false            |
| `showControllerButton`                | `bool`                                       | Show floating action buttons for navigation                | false            |
| `onPageChanged`                       | `ValueChanged<int>?`                         | Callback when page changes (receives page index)           | null             |
| `onPageFlipped`                       | `void Function(int)?`                        | Callback when flip animation completes (receives page num) | null             |
| `onFlipStart`                         | `void Function()?`                           | Callback when flip animation starts                        | null             |
| `controller`                          | `PageFlipController?`                        | Controller for programmatic page navigation                | null             |

## Programmatic Navigation

### Using PageFlipController

```dart
final PageFlipController _controller = PageFlipController();

// In your build method
CustomPageFlip(
  controller: _controller,
  children: pages,
)

// Navigate programmatically
_controller.nextPage();        // Go to next page
_controller.previousPage();    // Go to previous page
_controller.goToPage(5);       // Jump to specific page (zero-indexed)
```

### Using GlobalKey

```dart
final GlobalKey<CustomPageFlipState> _key = GlobalKey();

// In your build method
CustomPageFlip(
  key: _key,
  children: pages,
)

// Navigate programmatically
await _key.currentState?.animateToNextPage();
await _key.currentState?.animateToPreviousPage();
await _key.currentState?.goToPage(5);
```

## Gesture Handling

### How Gestures Work

The package intelligently distinguishes between different gestures:

| Gesture Type          | Behavior                                    |
|-----------------------|---------------------------------------------|
| **Single-finger swipe** | Triggers page flip animation              |
| **Two-finger pinch**    | Activates zoom (blocks page flip)         |
| **Pan while zoomed**    | Moves content (blocks page flip)          |
| **Zoom out to 1.0x**    | Re-enables page flip functionality        |

### Zoom Configuration

The `InteractiveViewer` is configured with these settings:

```dart
InteractiveViewer(
  transformationController: transformationController,
  panEnabled: true,      // Allow panning when zoomed
  scaleEnabled: true,    // Allow pinch zoom
  minScale: 1.0,        // Minimum zoom level
  maxScale: 4.0,        // Maximum zoom level (4x)
  // ...
)
```

## Advanced Features

### Custom Last Page

```dart
CustomPageFlip(
  children: pages,
  lastPage: Container(
    color: Colors.black,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'The End',
            style: TextStyle(fontSize: 32, color: Colors.white),
          ),
        ],
      ),
    ),
  ),
)
```

### Right-to-Left Swipe

For languages that read right-to-left or different interaction patterns:

```dart
CustomPageFlip(
  isRightSwipe: true,  // Swipe right to go forward
  children: pages,
)
```

### Navigation Buttons

```dart
CustomPageFlip(
  showControllerButton: true,  // Shows prev/next FAB buttons
  children: pages,
)
```

## Best Practices

### 1. TransformationController Management

Always provide a unique `TransformationController` for each page:

```dart
transformationControllerBuilder: (index) => 
    pdfController.getTransformationController(index),
```

### 2. Memory Management

Dispose controllers properly:

```dart
@override
void onClose() {
  transformationControllers.values.forEach((c) => c.dispose());
  super.onClose();
}
```

### 3. Reset Zoom on Page Change

Reset adjacent pages' zoom for better UX:

```dart
void updateCurrentPage(int index) {
  currentPage.value = index + 1;
  if (index > 0) resetZoom(index - 1);
  if (index < totalPages - 1) resetZoom(index + 1);
}
```

### 4. Image Optimization

For better performance with images:

```dart
Image.memory(
  imageBytes,
  fit: BoxFit.contain,
  cacheWidth: 1024,  // Limit decoded image size
  cacheHeight: 1448,
)
```

## Troubleshooting

### Issue: Page flips when trying to zoom

**Solution**: Ensure you're providing the `transformationControllerBuilder`:

```dart
transformationControllerBuilder: (index) => yourController.getTransformationController(index),
```

### Issue: Zoom doesn't work

**Solution**: Make sure you're not nesting `InteractiveViewer` widgets. Only use the one provided by `CustomPageFlip`.

### Issue: Gestures feel laggy

**Solution**: Test on a physical device. Emulators may not accurately represent gesture performance.

## Example App

Check out the [example](example/) directory for a complete working application demonstrating all features.

## Platform Support

| Platform | Supported |
|----------|-----------|
| Android  | ✅        |
| iOS      | ✅        |
| Web      | ✅        |
| macOS    | ✅        |
| Windows  | ✅        |
| Linux    | ✅        |

## Performance Tips

- Use `Image.memory` with `cacheWidth` and `cacheHeight` for large images
- Implement lazy loading for pages with heavy content
- Reset zoom on pages that are not currently visible
- Consider using `RepaintBoundary` for complex page content

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

Developed with ❤️ for the Flutter community.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

## Support

If you find this package helpful, please give it a ⭐️ on [GitHub](https://github.com/yourusername/custom_page_flip)!

For issues and feature requests, please use the [issue tracker](https://github.com/yourusername/custom_page_flip/issues).