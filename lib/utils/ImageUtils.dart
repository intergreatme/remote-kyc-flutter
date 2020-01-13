import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image/image.dart' as imgLib;

Future<List<int>> convertYUV420toImage(CameraImage image, ImageRotation rotation) async {
  try {
    final int width = image.width;
    final int height = image.height;

    // imglib -> Image package from https://pub.dartlang.org/packages/image
    var img = imgLib.Image(width, height); // Create Image buffer

    Plane plane = image.planes[0];
    const int shift = (0xFF << 24);

    // Fill image buffer with plane[0] from YUV420_888
    for (int x = 0; x < width; x++) {
      for (int planeOffset = 0; planeOffset < height * width; planeOffset += width) {
        final pixelColor = plane.bytes[planeOffset + x];
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        // Calculate pixel color
        var newVal = shift | (pixelColor << 16) | (pixelColor << 8) | pixelColor;
        img.data[planeOffset + x] = newVal;
      }
    }

    imgLib.PngEncoder pngEncoder = imgLib.PngEncoder(level: 0, filter: 0);
    // Convert to png
    List<int> png = pngEncoder.encodeImage(img);
    return png;
  } catch (e) {
    print(">>>>>>>>>>>> ERROR:" + e.toString());
  }
  return null;
}

imgLib.Image resizeImageIfSmaller({imgLib.Image inputImage, int maxDimension}) {
  var returnImage = inputImage;

  /// evaluate the current size, we don't want to resize small images
  if (inputImage.width > maxDimension || inputImage.height > maxDimension) {
    // find max
    if (inputImage.width >= inputImage.height) {
      // wider
      returnImage =
          imgLib.copyResize(returnImage, width: maxDimension, interpolation: imgLib.Interpolation.linear);
    } else {
      // taller
      returnImage =
          imgLib.copyResize(returnImage, height: maxDimension, interpolation: imgLib.Interpolation.linear);
    }
  }
  return returnImage;
}

imgLib.Image resizeImageForPor(imgLib.Image inputImage) {
  final int maxSize = 2500;
  var returnImage = inputImage;

  /// evaluate the current size, we don't want to resize small images
  if (inputImage.width > maxSize || inputImage.height > maxSize) {
    // find max
    if (inputImage.width >= inputImage.height) {
      // wider
      returnImage =
          imgLib.copyResize(returnImage, width: maxSize, interpolation: imgLib.Interpolation.linear);
    } else {
      // taller
      returnImage =
          imgLib.copyResize(returnImage, height: maxSize, interpolation: imgLib.Interpolation.linear);
    }
  }
  return returnImage;
}

imgLib.Image resizeImageForDoc(imgLib.Image inputImage) {
  final int maxSize = 1920;
  var returnImage = inputImage;

  /// evaluate the current size, we don't want to resize small images
  if (inputImage.width > maxSize || inputImage.height > maxSize) {
    // find max
    if (inputImage.width >= inputImage.height) {
      // wider
      returnImage =
          imgLib.copyResize(returnImage, width: maxSize, interpolation: imgLib.Interpolation.linear);
    } else {
      // taller
      returnImage =
          imgLib.copyResize(returnImage, height: maxSize, interpolation: imgLib.Interpolation.linear);
    }
  }
  return returnImage;
}