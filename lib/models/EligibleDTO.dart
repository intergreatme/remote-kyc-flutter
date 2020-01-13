import 'package:scoped_model/scoped_model.dart';

class EligibleDTO extends Model {
  bool eligible;
  String shareId; // UUID
  String completeState; // [INCOMPLETE, CONSENT, COMPLETE, TIMEOUT]
  String authToken;

  EligibleDTO({this.eligible, this.shareId, this.completeState, this.authToken});

  factory EligibleDTO.fromData(Map<dynamic, dynamic> data) {
    return EligibleDTO(eligible: data['eligible'], shareId: data['share_id'], completeState: data['complete_state'], authToken: data['auth_token']);
  }
}
