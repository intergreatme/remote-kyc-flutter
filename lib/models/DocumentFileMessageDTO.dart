import 'package:scoped_model/scoped_model.dart';

/// this class is used to store the errors when a document comes back from validation
class DocumentFileMessageDTO extends Model {
  String id;
  String title;
  String body;

  DocumentFileMessageDTO({this.id, this.body, this.title});

  factory DocumentFileMessageDTO.fromData(Map<dynamic, dynamic> data) {
    return DocumentFileMessageDTO(id: data['id'], title: data['title'], body: data['body']);
  }
}
