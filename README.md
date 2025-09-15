## Features

- Smooth flip page transition
- Supports multiple pages and last page customization
- Configurable animation duration and swipe direction
- Callbacks for page change events
- Lightweight and easy to integrate

## Getting Started

Add this package as a dependency in your `pubspec.yaml`:

```dart
  dependencies :
    flip_curl_animation_widget: <latest_version>
```

Import the package:

```dart
  final PdfController pdfController = Get.put(PdfController());  // PdfController is your getx controller
  final GlobalKey<PageFlipWidgetState> pageFlipKey = GlobalKey();
```

```dart
import 'package:custom_page_flip/custom_page_flip.dart';

```

## Usage

```dart
CustomPageFlip(
key: pageFlipKey,
children: List.generate(
pdfController.pagesBytes.length,
(index) => GestureDetector(
onTap: () {
},
child: Container(
color: Colors.pink.shade300,
child: Image.memory(
pdfController.pagesBytes[index],
fit: BoxFit.contain,
),
),
),
),

onPageChanged: (index) {
pdfController.playFlipSound();
pdfController.updateCurrentPage(index);
},
),

```

text

## Parameters

| Parameter         | Description                              | Default          |
|-------------------|------------------------------------------|------------------|
| `duration`        | Duration of the flip animation           | 450 milliseconds |
| `cutoffForward`   | Threshold to consider animation forward  | 0.8              |
| `cutoffPrevious`  | Threshold to consider animation backward | 0.1              |
| `backgroundColor` | Background color during animation        | Colors.white     |
| `children`        | List of Widgets to display as pages      | Required         |
| `initialIndex`    | Initial page index                       | 0                |
| `lastPage`        | Optional Widget to show on the last page | null             |
| `isRightSwipe`    | Flip direction (true for right swipe)    | false            |
| `onPageChanged`   | Callback when page changes               | null             |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
