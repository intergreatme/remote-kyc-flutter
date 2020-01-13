import 'package:scoped_model/scoped_model.dart';

import 'DocumentFileMessageDTO.dart';

class DocumentFileDTO extends Model {
  String fileType; // [ SELFIE, FRONT, BACK ]
  int createdOn;
  DocumentFileMessageDTO message;

  DocumentFileDTO({this.fileType, this.createdOn, this.message});

  factory DocumentFileDTO.fromData(Map<dynamic, dynamic> data) {
    DocumentFileDTO returnDto = DocumentFileDTO(fileType: data['file_type'], createdOn: data['created_on']);

    if (data['message'] != null) {
      returnDto.message = DocumentFileMessageDTO.fromData(data['message']);
    }

    return returnDto;
  }
}

enum DocumentFileType { selfie, front, back }
