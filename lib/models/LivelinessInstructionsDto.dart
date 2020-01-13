import 'package:scoped_model/scoped_model.dart';

import 'LivelinessInstructionDto.dart';

class LivelinessInstructionsDto extends Model {
  String livelinessId;
  List<LivelinessInstructionDto> instructions;

  LivelinessInstructionsDto({this.livelinessId, this.instructions});

  factory LivelinessInstructionsDto.fromData(Map<dynamic, dynamic> data) {
    List<LivelinessInstructionDto> instructionSet = [];
    if(data['instructions'] != null) {
      List<dynamic> instructionsRaw = data['instructions'];
      for(int i = 0 ; i < instructionsRaw.length ; i++) {
        instructionSet.add(LivelinessInstructionDto.fromData(instructionsRaw[i]));
      }
    }

    return LivelinessInstructionsDto(
        livelinessId: data['liveliness_id'],
        instructions: instructionSet
    );
  }
}