import 'package:igm_self_kyc/models/DocumentFileDTO.dart';
import 'package:scoped_model/scoped_model.dart';

class DocumentDTO extends Model {
  int createdOn;
  String docType; // [ UNDEFINED, SELFIE, ID_BOOK, ID_CARD, DRIVERS_LICENCE, PASSPORT, PROOF_OF_RESIDENCE, MARRIAGE_CERTIFICATE ]
  List<DocumentFileDTO> files;
  String status; // [ NEW, ON_HOLD, PENDING_VALIDATION, DELAYED, REQUIRES_SUPPORT, VALID, PENDING_VERIFICATION, VERIFIED, VALIDATION_FAILED, VERIFICATION_FAILED ]
  bool delayed;

  DocumentDTO({this.createdOn, this.docType, this.files, this.status, this.delayed});

  factory DocumentDTO.fromData(Map<dynamic, dynamic> data) {
    List<DocumentFileDTO> docFiles = [];
    if(data['files'] != null) {
      List<dynamic> files = data['files'];
      for (int i = 0 ; i < files.length ; i++) {
        docFiles.add(DocumentFileDTO.fromData(files[i]));
      }
    }

    return DocumentDTO(createdOn: data['created_on'],
        docType: data['doc_type'],
        files: docFiles,
        status: data['status'],
        delayed: data['delayed']);
  }

  DocumentFileDTO _getFile(String type) {
    if(files == null) {
      return null;
    }

    for (DocumentFileDTO file in files) {
      if (file.fileType == type) {
        return file;
      }
    }
    return null;
  }

  DocumentFileDTO getSelfie() {
    return _getFile("SELFIE");
  }

  DocumentFileDTO getFront() {
    return _getFile("FRONT");
  }

  DocumentFileDTO getBack() {
    return _getFile("BACK");
  }

  DocumentStatus getStatus() {
    if(status == null) {
      return DocumentStatus.none;
    }
    switch (status) {
      case 'NEW':
        return DocumentStatus.partial;

      case 'VALID':
      case 'VERIFIED':
        return DocumentStatus.complete;

      case 'PENDING_VALIDATION':
      case 'ON_HOLD':
      case 'REQUIRES_SUPPORT':
      case 'PENDING_VERIFICATION':
        return DocumentStatus.pending;

      case 'VALIDATION_FAILED':
      case 'VERIFICATION_FAILED':
        return DocumentStatus.error;

      default:
        return DocumentStatus.none;
    }
  }

  static String getFileTypeForEnum(DocumentType type) {
    switch(type) {

      case DocumentType.idBook:
        return "ID_BOOK";
        break;

      case DocumentType.idCard:
        return "ID_CARD";
        break;

      case DocumentType.passport:
        return "PASSPORT";
        break;

      case DocumentType.proofOfResidence:
        return "PROOF_OF_RESIDENCE";
        break;
    }
    throw("Unknown filetype");
  }
}

enum DocumentStatus {
  partial,
  complete,
  pending,
  error,
  none
}

// there are more types, but this project wont support them
enum DocumentType {
  idBook,
  idCard,
  passport,
  proofOfResidence,
}
