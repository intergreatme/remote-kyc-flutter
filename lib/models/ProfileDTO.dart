import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';

import 'AddressDTO.dart';
import 'DocumentDTO.dart';

class ProfileDTO extends Model {
  String id;
  String originTxId;
  String uniqueField; // mobile number
  String documentNumber;
  String passportCountry;
  bool usePassport;
  String firstName;
  String middleNames;
  String lastName;
  String emailAddress;
  AddressDTO address;
  List<DocumentDTO> documents; // the collection of documents, POR, Id etc.
  String shareStatus; // NONE, INCOMPLETE, CONSENT, COMPLETE, TIMEOUT
  bool shareSuccess;
  String livelinessState; // NONE, FAIL, PASS

  ProfileDTO(
      {this.id,
      this.originTxId,
      this.uniqueField,
      this.documentNumber,
      this.passportCountry,
      this.usePassport,
      this.firstName,
      this.middleNames,
      this.lastName,
      this.emailAddress,
      this.address,
      this.documents,
      this.shareStatus,
      this.shareSuccess,
      this.livelinessState});

  factory ProfileDTO.fromData(Map<dynamic, dynamic> data) {
    List<DocumentDTO> profileDocs = [];
    if(data['documents'] != null) {
      List<dynamic> docs = data['documents'];
      for(int i = 0 ; i < docs.length ; i++) {
        profileDocs.add(DocumentDTO.fromData(docs[i]));
      }
    }

    return ProfileDTO(
        id: data['id'],
        originTxId: data['origin_tx_id'],
        uniqueField: data['unique_field'],
        documentNumber: data['document_number'],
        passportCountry: data['passport_country'],
        usePassport: data['use_passport'],
        firstName: data['first_name'],
        middleNames: data['middle_names'],
        lastName: data['last_name'],
        emailAddress: data['email_address'],
        address: AddressDTO.fromData(data['address']),
        documents: profileDocs,
        shareStatus: data['share_status'],
        shareSuccess: data['share_success'],
        livelinessState: data['liveliness_state']);
  }

  DocumentDTO getIdCard() {
    return _getDoc(key: "ID_CARD");
  }

  DocumentDTO getIdBook() {
    return _getDoc(key: "ID_BOOK");
  }

  DocumentDTO getPassport() {
    return _getDoc(key: "PASSPORT");
  }

  DocumentDTO getPor() {
    return _getDoc(key: "PROOF_OF_RESIDENCE");
  }

  DocumentDTO _getDoc({@required String key}) {
    if(documents == null) {
      return DocumentDTO(docType: key);
    }
    for (DocumentDTO doc in documents) {
      if(doc.docType == key) {
        return doc;
      }
    }
    return DocumentDTO(docType: key);
  }
}
