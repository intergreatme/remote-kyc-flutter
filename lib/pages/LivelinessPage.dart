import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:igm_self_kyc/ThemeConstants.dart';
import 'package:igm_self_kyc/models/LivelinessInstructionsDto.dart';
import 'package:igm_self_kyc/utils/ImageUtils.dart';

import '../IgmNetworkHelper.dart';

/// NOTE!!! UNDER CONSTRUCTION, All code here may be regarded as experimental.
///
/// references
/// https://blog.usejournal.com/real-time-object-detection-in-flutter-b31c7ff9ef96
/// https://firebase.google.com/docs/ml-kit/images/examples/face_contours.svg


class LivelinessPage extends StatefulWidget {
  // the max amount of images gathered per second to increase performance
  final maxImageRate = 5.0; // same as angular app

  // set the upper limit of images gathered for each gesture, affects upload sizes
  final maxGifFramesPerGesture = 25; // same as angular app

  // the face detection doesn't always find a face, to keep the ui smooth we user this. once getting this, the gesture will have to be restarted by the user
  final maxNoFaceInSeconds = 3;

  // set the upper limit of time to gather frames to evaluate for gestures
  final maxGestureTimeToEvaluateInMilliseconds = 2000;

  // set the thresholds for gesture detection
  final double thresholdHeadShakeDistance = 20;
  final double thresholdHeadShakeCenterBuffer = 2;
  final double thresholdMouth = 80.0;

  final double thresholdNodDistance = 5;
  final double thresholdLookLeft = 17;
  final double thresholdLookRight = -17;
  final double thresholdLookDown = 2;
  final double thresholdLookUp = 4;
  final double thresholdCenterY = 5;
  final double thresholdCenterX = 5;

  LivelinessPage({Key key}) : super(key: key);

  @override
  _LivelinessPageState createState() {
    return _LivelinessPageState();
  }
}

class _LivelinessPageState extends State<LivelinessPage> {
  CameraController _camera;
  CameraImage currentFrame;

  bool _fullScreen = true;
  bool _isDetecting = false;

  CameraLensDirection _direction = CameraLensDirection.front;
  DateTime _lastCapturedImageTimestamp;
  double _pollingRate;
  FaceDetector _faceDetector;
  List<Image> _gatheredImagesForGif = [];
  LivelinessInstructionsDto _livelinessInstructionsDto;
  int _currentLivelinessStepIndex = 0;
  double _yCenterOffset;

  // values for tracking head movement
  List<GestureFrame> _gestureFrames = [];

//  int _noFaceInFrameCount = 0;

  // values for displaying to the user
  String _errorMessage = "Please face the camera"; // we set a default to ready the user whilst loading the application
  String _instructionMessage;

  @override
  void initState() {
    super.initState();
    _faceDetector = FirebaseVision.instance
        .faceDetector(FaceDetectorOptions(enableContours: true, enableLandmarks: true, mode: FaceDetectorMode.fast, enableClassification: false, enableTracking: false, minFaceSize: 0.333));
    _lastCapturedImageTimestamp = DateTime.now();
    _pollingRate = 1000 / widget.maxImageRate;
    _initializeCamera();
  }

  @override
  void dispose() {
    _camera.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget imagePreview;
    if (_camera != null && _camera.value != null && _camera.value.aspectRatio != null && _camera.value.isInitialized) {
      imagePreview = FittedBox(
        fit: _fullScreen ? BoxFit.cover : BoxFit.fitWidth,
        child: SizedBox(
          width: _camera.value.aspectRatio * 10000, // X 10,000 for iOS to do the correct layout too, without this, the image will not show
          height: 10000, // 1 x 10,000
          child: AspectRatio(
            aspectRatio: _camera.value.aspectRatio,
            child: CameraPreview(_camera),
          ),
        ),
      );
    } else {
      imagePreview = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            Divider(),
            Text(
              "loading, please wait",
              style: Theme.of(context).textTheme.subhead.apply(color: Colors.white),
            )
          ],
        ),
      );
    }

    // TODO add small please wait, close everything back up before going back
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: Text("Liveliness Detection"),
        actions: <Widget>[
          IconButton(
            icon: Icon(_fullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
            splashColor: Theme.of(context).splashColor,
            color: Colors.white,
            padding: EdgeInsets.only(right: 10),
            onPressed: () {
              setState(() {
                _fullScreen = !_fullScreen;
              });
            },
          )
        ],
      ),
      body: FutureBuilder<LivelinessInstructionsDto>(
        future: IgmNetworkHelper.getInstance().getLivelinessInstructions(),
        builder: (BuildContext context, AsyncSnapshot<LivelinessInstructionsDto> snapshot) {
          if (snapshot.hasData) {
            _livelinessInstructionsDto = snapshot.data;

            if (_instructionMessage == null) {
              if (_yCenterOffset == null) {
                _instructionMessage = "Please look straight at the camera, keeping your head still";
              } else {
                _instructionMessage = _getInstructionForGesture(gestureString: _livelinessInstructionsDto.instructions[0].gesture, word: _livelinessInstructionsDto.instructions[0].word);
              }
            }

            return Stack(
              children: <Widget>[
                Positioned(
                  child: imagePreview,
                  bottom: 0,
                  top: 0,
                  left: 0,
                  right: 0,
                ),
                _errorMessage == null
                    ? Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Theme.of(context).primaryColor.withOpacity(0.8),
                          padding: EdgeInsets.all(ThemeConstants.padding),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                _instructionMessage,
                                style: Theme.of(context).textTheme.title.apply(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Theme.of(context).errorColor.withOpacity(0.8),
                          padding: EdgeInsets.all(ThemeConstants.padding),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                _errorMessage,
                                style: Theme.of(context).textTheme.subtitle.apply(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      )
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.error,
                    size: 80,
                    color: Theme.of(context).errorColor,
                  ),
                  Divider(),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.body1.apply(color: Theme.of(context).errorColor),
                  ),
                  Divider(),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "Loading, please wait",
                    style: Theme.of(context).textTheme.title.apply(color: Colors.white),
                  ),
                  Divider(),
                  CircularProgressIndicator()
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<CameraDescription> _getCamera(CameraLensDirection dir) async {
    return await availableCameras().then(
      (List<CameraDescription> cameras) => cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection == dir,
      ),
    );
  }

  void _initializeCamera() async {
    _camera = CameraController(
      await _getCamera(_direction),
      defaultTargetPlatform == TargetPlatform.iOS ? ResolutionPreset.medium : ResolutionPreset.medium,
    );
    await _camera.initialize();
    setState(() {});
    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return; // skip processing every frame, only do one if completed the last
      _processImage(image);
    });
  }

  _processImage(CameraImage image) async {
    _isDetecting = true;
    try {
      final FirebaseVisionImage visionImage = FirebaseVisionImage.fromBytes(
        image.planes[0].bytes,
        FirebaseVisionImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            planeData: image.planes.map((currentPlane) => FirebaseVisionImagePlaneMetadata(bytesPerRow: currentPlane.bytesPerRow, height: currentPlane.height, width: currentPlane.width)).toList(),
            rawFormat: image.format.raw,
            rotation: ImageRotation.rotation270),
      );

      final List<Face> allFaces = await _faceDetector.processImage(visionImage);

      if (allFaces.length > 0) {
        DateTime startTime = DateTime.now();

        Face biggestFace = allFaces[0];
        // find the biggest face
        if (allFaces.length > 1) {
          for (int i = 1; i < allFaces.length; i++) {
            if (allFaces[i].boundingBox.size > biggestFace.boundingBox.size) {
              biggestFace = allFaces[i];
            }
          }
        }
        // check the last time you got a frame
        DateTime aLittleWhileLater = DateTime.now();

        if (aLittleWhileLater.difference(_lastCapturedImageTimestamp).inMilliseconds > _pollingRate) {
          _lastCapturedImageTimestamp = aLittleWhileLater;
          // add the frame to a list to be used later down the process to create a gif to send back to the server, but first dump frames that are too old
          while (_gatheredImagesForGif.length > widget.maxGifFramesPerGesture - 1) {
            _gatheredImagesForGif.removeAt(0);
          }
          _gatheredImagesForGif.add(Image.memory(await convertYUV420toImage(image, ImageRotation.rotation270)));
        }

        // check the upper limit for gathered frames
        while (_gestureFrames.length > 0 && _gestureFrames[0] != null && aLittleWhileLater.difference(_gestureFrames[0].captureTime).inMilliseconds > widget.maxGestureTimeToEvaluateInMilliseconds) {
          _gestureFrames.removeAt(0);
        }

        print("Upperlipbottom " + biggestFace.getContour(FaceContourType.upperLipBottom).positionsList[4].dy.toString());
        print("LowerlipTop " + biggestFace.getContour(FaceContourType.lowerLipTop).positionsList[4].dy.toString());

        double faceHeight = biggestFace.getContour(FaceContourType.face).positionsList[18].dy - biggestFace.getContour(FaceContourType.face).positionsList[0].dy;
        double mouthOpenAmount = biggestFace.getContour(FaceContourType.lowerLipTop).positionsList[4].dy - biggestFace.getContour(FaceContourType.upperLipBottom).positionsList[4].dy;
        double mouthOpenDistance = 0;
        print("faceHeight : $faceHeight  mouthOpenAmount : $mouthOpenAmount");
        if (faceHeight > 0 && mouthOpenAmount > 0) {
          mouthOpenDistance = faceHeight / mouthOpenAmount;
          print("ratio calculated : $mouthOpenDistance");
        }

        _gestureFrames.add(
          GestureFrame(
              rotY: biggestFace.headEulerAngleY,
              rotX: biggestFace.getContour(FaceContourType.noseBottom).positionsList[1].dy - biggestFace.getContour(FaceContourType.noseBridge).positionsList[1].dy,
              allPoints: biggestFace.getContour(FaceContourType.allPoints).positionsList,
              mouthOpenDistance: mouthOpenDistance,
              captureTime: aLittleWhileLater),
        );

        print("we have " + _gestureFrames.length.toString() + " frames now");

        _evaluateGestureSet();

        // TODO check if view is gone before updating state
        // don't update the state if we don't need to
        if (_errorMessage != null) {
          setState(() {
            _errorMessage = null;
          });
        }
//        print("Took : " + startTime.difference(DateTime.now()).inMilliseconds.toString());
      } else {
        if (_lastCapturedImageTimestamp == null || DateTime.now().difference(_lastCapturedImageTimestamp).inMilliseconds > widget.maxNoFaceInSeconds * 1000) {
          _errorMessage = "Please face the camera";

          // TODO check if view is gone before updating state
          // clear the gathered data as it is no longer valid
          setState(() {
            _gestureFrames = [];
            _gatheredImagesForGif = [];
          });
        }
      }
    } catch (e) {
      print("Error! : " + e.toString());
    } finally {
      _isDetecting = false;
    }
  }

  _evaluateGestureSet() {
    double minX = 1000, maxX = -1000, minY = 1000, maxY = -1000, minMouth = 1000, maxMouth = -1000;
//    bool isPositiveX;

    List<Gesture> returnGestures = [];
    // go through each frame to see what was done.
    for (int i = 0; i < _gestureFrames.length; i++) {
      GestureFrame frame = _gestureFrames[i];

      // get the min and max x movement
      if (frame.rotY < minX) {
        minX = frame.rotY;
      }
      if (frame.rotY > maxX) {
        maxX = frame.rotY;
      }

      // get the min and max y movement
      if (frame.rotX < minY) {
        minY = frame.rotX;
      }
      if (frame.rotX > maxY) {
        maxY = frame.rotX;
      }

//      // get how many times the center was crossed the x center
//      if (isPositiveX == null) {
//        // get the start point
//        if (frame.rotY > 0 + widget.thresholdHorizontalCenter) {
//          isPositiveX = true;
//        }
//        if (frame.rotY < 0 - widget.thresholdHorizontalCenter) {
//          isPositiveX = false;
//        }
//      } else {
//        if (!isPositiveX && frame.rotY > 0 + widget.thresholdHorizontalCenter) {
//          centerXCount++;
//          isPositiveX = true;
//        }
//        if (isPositiveX && frame.rotY < 0 - widget.thresholdHorizontalCenter) {
//          centerXCount++;
//          isPositiveX = false;
//        }
//      }

      if (frame.mouthOpenDistance < minMouth) {
        minMouth = frame.mouthOpenDistance;
      }
      if (frame.mouthOpenDistance > maxMouth) {
        maxMouth = frame.mouthOpenDistance;
      }
    }
    print("frame Count " + _gestureFrames.length.toString());

    // detect head shake
    if (maxX - minX > widget.thresholdHeadShakeDistance && minX < widget.thresholdHeadShakeCenterBuffer * -1 && maxX > widget.thresholdHeadShakeCenterBuffer) {
      returnGestures.add(Gesture.headShake);
    }

    // detect head nod TODO, needs centering first, or it wont work
//    if (maxY - minY > widget.thresholdNodDistance) {
//      returnGestures.add(Gesture.headNod);
//    }

    // detect mouth movement
    if (maxMouth - minMouth < widget.thresholdMouth) {
      print("mouth[$maxMouth - $minMouth] = " + (maxMouth - minMouth).toString());
      returnGestures.add(Gesture.mouthMoved);
    }

    // detect look left
    if (maxX > widget.thresholdLookLeft) {
      print("left[$maxX]");
      returnGestures.add(Gesture.lookLeft);
    }

    // detect look right
    if (minX < widget.thresholdLookRight) {
      print("right[$minX]");
      returnGestures.add(Gesture.lookRight);
    }
//
//    // detect look up
//    if (maxY > widget.thresholdLookUp) {
//      returnGestures.add(Gesture.lookUp);
//    }
//
//    // detect look down
//    if (minY < widget.thresholdLookDown) {
//      returnGestures.add(Gesture.lookDown);
//    }
//
//    // detect head nod
//    if (maxY - minY > widget.thresholdNodDistance) {
//      returnGestures.add(Gesture.headNod);
//    }
//
    // look at camera, this is used to center and measure the persons note, get a zeroed amound and then capture the gesture
    if (maxY - minY < widget.thresholdCenterY && maxX - minX < widget.thresholdCenterX) {
      print("centered[$maxY - $minY][$maxX - $minX]");
      returnGestures.add(Gesture.headCentered);
    } else {
      print("!centered[" + (maxY - minY).toString() + "]" + (maxY - minY < widget.thresholdCenterY).toString() + "[" + (maxX - minX).toString() + "]" +  (maxX - minX < widget.thresholdCenterX).toString());
    }

    print("Gestures detected " + returnGestures.toString());
  }

  _getInstructionForGesture({@required String gestureString, String word}) {
    switch (gestureString) {
      case "HEAD_CENTERED":
        return "Please look at the camera";
      case "HEAD_NOD":
        return "Nod your head";
      case "HEAD_SHAKE":
        return "Shake your head";
      case "LOOK_UP":
        return "Look up";
      case "LOOK_DOWN":
        return "Look down";
      case "LOOK_RIGHT":
        return "Look right";
      case "LOOK_LEFT":
        return "Look left";
      case "MOUTH_MOVED":
        return "Say the words: \"" + word + "\"";
    }
  }
}

enum Gesture { headCentered, headNod, headShake, lookUp, lookDown, lookRight, lookLeft, mouthMoved }

class GestureFrame {
  double rotY, rotX; // yaw, pitch
  double mouthOpenDistance;
  List<Offset> allPoints;
  DateTime captureTime;

  GestureFrame({@required this.rotY, @required this.rotX, @required this.mouthOpenDistance, @required this.allPoints, @required this.captureTime});
}

/// calculate the pitch of the face
//        Offset eyeCornerRight = biggestFace.getContour(FaceContourType.rightEye).positionsList[8];
//        Offset eyeCornerLeft = biggestFace.getContour(FaceContourType.leftEye).positionsList[0];
//        Offset eyeCenter = Offset((eyeCornerRight.dx + eyeCornerLeft.dx) / 2, (eyeCornerRight.dy + eyeCornerLeft.dy) / 2);
//
//        Offset mouthRight = biggestFace.getContour(FaceContourType.upperLipTop).positionsList[10];
//        Offset mouthLeft = biggestFace.getContour(FaceContourType.upperLipTop).positionsList[0];
//        Offset mouthCenter = Offset((mouthLeft.dx + mouthRight.dx) / 2, (mouthLeft.dy + mouthRight.dy) / 2);
//
//        Offset noseTip = biggestFace.getContour(FaceContourType.noseBottom).positionsList[1];
//        Offset noseBase = biggestFace.getLandmark(FaceLandmarkType.noseBase).position;
//
//        //Get lengths
//        double lf = Math.sqrt(Math.pow(eyeCenter.dx - mouthCenter.dx, 2) + Math.pow(eyeCenter.dy - mouthCenter.dy, 2));
//        double ln = Math.sqrt(Math.pow(noseTip.dx - noseBase.dx, 2) + Math.pow(noseTip.dy - noseBase.dy, 2));
//
//        double Rn = 0.6;
//        double tilt = Math.atan2(noseTip.dy - noseBase.dy, noseTip.dx - noseBase.dx);
//
//        double theta = Math.atan2(noseTip.dy - eyeCenter.dy, eyeCenter.dx - noseTip.dx) - Math.atan2(noseBase.dy - noseTip.dy, noseTip.dx - noseBase.dx);
//        double m1 = Math.pow(ln / lf, 2);
//        double m2 = Math.pow(Math.cos(theta), 2);
//
//        double a = Math.pow(Rn, 2) * (1 - m2);
//        double b = m1 - Math.pow(Rn, 2) + 2 * m2 * Math.pow(Rn, 2);
//        double c = -m2 * Math.pow(Rn, 2);
//
//        double dz = (-b + Math.sqrt(Math.pow(b, 2) - 4 * a * c)) / (2 * a).abs();
//
//        double slant = Math.acos(dz);
//        double pitch = Math.asin(-(Math.sin(slant) * Math.sin(tilt)));
