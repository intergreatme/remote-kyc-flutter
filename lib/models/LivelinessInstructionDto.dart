import 'package:scoped_model/scoped_model.dart';

class LivelinessInstructionDto extends Model {
  String gestureCategory; // [ LOOK, MOUTH, HEAD_MOVEMENT ]
  String gesture; // [ LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN, MOUTH_MOVED, HEAD_NOD, HEAD_SHAKE ]
  String word;

  LivelinessInstructionDto({this.gestureCategory, this.gesture, this.word});

  factory LivelinessInstructionDto.fromData(Map<dynamic, dynamic> data) {
    return LivelinessInstructionDto(gestureCategory: data['gesture_category'], gesture: data['gesture'], word: data['word']);
  }
}
