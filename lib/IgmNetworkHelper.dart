import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:igm_self_kyc/models/AddressDTO.dart';
import 'package:igm_self_kyc/models/ProfileDTO.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'models/EligibleDTO.dart';
import 'models/LivelinessInstructionsDto.dart';

class IgmNetworkHelper {
  static IgmNetworkHelper _instance;
  final _configId = '<your site ID key>'; // the site Id you obtained from Intergreatme

  final _apiPath = "https://dev.intergreatme.com/kyc/za/api/"; // "https://kyc.intergreatme.com/za/api" for prod
  final _companyName = "<your app name>";
  String _authToken;
  String _txId;
  String _originTxId;

  ProfileDTO currentProfileObject;

  /// singleton for the class, you may not want to use one, really doesnt matter
  static IgmNetworkHelper getInstance() {
    if (_instance == null) {
      _instance = new IgmNetworkHelper._internal();
    }
    return _instance;
  }

  IgmNetworkHelper._internal(); // part of the singleton declaration

  /// STEP 1) create some test data, to get the originTxId and whitelistId back and store them for the session
  Future sendWhitelistInfo({@required String idNumber, @required String name, @required String surname, AddressDTO addressDTO, String email, String mobile}) async {
    /* request body
    {
      "id_number":"8305125050089",
      "firstname":"John",
      "surname":"Doe",
      "email\":"john@doe.com",
      "mobile\":"0792922380",
      "line1":"3 Melrose Boulevard",
      "line2":"Melrose Arch",
      "suburb":"Melrose",
      "province":"Gauteng",
      "post_code":"2196",
      "country":"South Africa"
    }
     */

    Map<String, String> payloadContent = {};
    payloadContent.addAll({"id_number": idNumber, "first_name": name, "last_name": surname, "email": email, "mobile": mobile}); // add the required fields
    payloadContent.addAll(addressDTO.toData()); // add the addressDTO

    final url = "https://www.intergreatme.com/api/self-kyc-util/whitelist/?config=" + _configId + "&name=" + _companyName;
    final payloadString = "{\"payload\":" + json.encode(json.encode(payloadContent)) + "}";

    var response = await http.post(url, body: payloadString);
    if (response.statusCode == 200) {
      var jsonBodyString = json.decode(response.body)["payload"];
      if (jsonBodyString != null) {
        var jsonBody = json.decode(jsonBodyString);
        var transactionId = jsonBody["tx_id"];
        var originId = jsonBody["origin_tx_id"];

        if (transactionId != null && originId != null) {
          _txId = transactionId;
          _originTxId = originId;
        } else {
          throw ("Failed to get transactionId or originId");
        }
      } else {
        throw ("Failed to get payload");
      }
    } else {
      throw ("Request failed, code[" + response.statusCode.toString() + "]");
    }
  }

  /// STEP 2) check that the information you have gathered is eligible to start the process, this gets the authToken to be used going forward
  Future<EligibleDTO> getEligible() async {
    /* request body
    {
      "whitelist_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6", //from the whitelist entry
      "origin_tx_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6"  //from the whitelist entry
    }
     */
    var response = await http.post(_apiPath + "user/eligible", headers: _getHeaders(), body: json.encode({'whitelist_id': _txId, 'origin_tx_id': _originTxId}));

    if (response.statusCode == 200) {
      var jsonBodyString = json.decode(response.body)["data"];
      if (jsonBodyString != null) {
        var eligibleDto = EligibleDTO.fromData(jsonBodyString);
        if (eligibleDto.completeState == "INCOMPLETE") {
          _authToken = eligibleDto.authToken;
          return eligibleDto;
        } else {
          // CONSENT, COMPLETE, TIMEOUT are the other values that may come through
          throw ("Cannot start [" + eligibleDto.completeState + "]");
        }
      } else {
        throw ("Failed to get data");
      }
    } else {
      throw ("Request failed, code[" + response.statusCode.toString() + "]");
    }
  }

  /// Step 3) fetch the profile, and check the state of items
  Future<ProfileDTO> getProfile() async {
    // no body is required for this request
    var response = await http.get(_apiPath + "user/profile", headers: _getHeaders());
    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      // possible response codes
      // [ OK, UNEXPECTED_ERROR, CONFIG_NOT_FOUND, UNAUTHORIZED_ACTION, REGISTER_NOT_ELIGIBLE, OTP_SERVICE_UNAVAILABLE, BAD_DATA_PROVIDED, FIRST_NAME_REQUIRED, LAST_NAME_REQUIRED ]
      if (jsonData['code'] == "OK") {
        currentProfileObject = ProfileDTO.fromData(jsonData['data']);
        return currentProfileObject;
      } else {
        return throw ("Request failed, resoponse code [" + jsonData['code'] + "]");
      }
    } else {
      throw ("Request failed, code[" + response.statusCode.toString() + "]");
    }
  }

  /// STEP 4) upload a file, repeat this for all files in the group (selfie, front, back etc... )
  Future<bool> uploadFile({@required String documentType, @required String documentFileType, @required File file}) async {
    /* request body
    {
      "share": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "documentType": "string",
      "documentFileType": "string",
      "mime": "string",
      "file": {}
    }
    */

    var fileName = basename(file.path);
    var fileType = "";
    // ensure that the correct mime type is being sent through, we only accept pdf or images, so best to do a sanity check before you get this far
    if (fileName.toLowerCase().endsWith('.pdf')) {
      fileType = 'application/pdf';
    } else {
      var index = fileName.indexOf('.');
      if (index > -1) {
        fileType = 'image/' + fileName.substring(index + 1);
      }
    }

    var request = http.MultipartRequest('POST', Uri.parse(_apiPath + "file/upload"));
    // set the headers
    request.headers['config'] = _configId;
    request.headers['Authorization'] = "bearer " + _authToken;

    // set the body
    request.fields['share'] = _txId;
    request.fields['documentType'] = documentType;
    request.fields['documentFileType'] = documentFileType;
    request.fields['mime'] = fileType;

    // add the file
    var multiPartFile = await http.MultipartFile.fromPath('file', file.path);
    request.files.add(multiPartFile);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else {
      throw HttpRequestError(code: response.statusCode, message: "Upload  failed");
    }
  }

  /// STEP 5) get the preview of the file that the user has already uploaded
  Future<String> getFileThumbnail({@required String documentType, @required String documentFileType, @required int maxWidth}) async {
    HttpClient client = new HttpClient();
    var httpRequest = await client.getUrl(Uri.parse(_apiPath + "file/getFileThumbnail?documentType=" + documentType + "&documentFileType=" + documentFileType + "&maxWidth=" + maxWidth.toString()));
    httpRequest.headers.add('config', _configId);
    httpRequest.headers.add('Authorization', "bearer " + _authToken);
    httpRequest.headers.add('Content-Type', "application/json");


    var httpResponse = await httpRequest.close();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    File file = new File(appDocPath + "/" + documentFileType + ".png");

    var raf = file.openSync(mode: FileMode.write);

    Completer completer = new Completer<String>();

    httpResponse.listen(
      (data) {
        raf.writeFromSync(data);
      },
      onDone: () {
        raf.closeSync();
        completer.complete(file.path);
      },
      onError: (e) {
        raf.closeSync();
        file.deleteSync();
        completer.completeError(e);
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  ///  STEP 6) submit the document files for validation
  Future requestValidation({@required String documentType}) async {
    /* request body
    {
      "document_type": "string"
    }
     */
    var response = await http.post(_apiPath + "file/requestValidation",
        headers: {'config': _configId, 'Authorization': "bearer " + _authToken, "Content-Type": "application/json"}, body: json.encode({'document_type': documentType}));
    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      return jsonData['code'];
    } else {
      throw ("Request failed, code[" + response.statusCode.toString() + "]");
    }
  }

  /// STEP 7) get the liveliness instruction set
  Future<LivelinessInstructionsDto> getLivelinessInstructions() async {
    /* request body
    not required, the configId ensures the correct instructions are returned
     */
    var response = await http.get(_apiPath + "liveliness/instructions", headers: _getHeaders());
    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      // possible response codes
      // [ OK, UNEXPECTED_ERROR, CONFIG_NOT_FOUND, UNAUTHORIZED_ACTION, REGISTER_NOT_ELIGIBLE, OTP_SERVICE_UNAVAILABLE, BAD_DATA_PROVIDED, FIRST_NAME_REQUIRED, LAST_NAME_REQUIRED ]
      if (jsonData['code'] == "OK") {
        return LivelinessInstructionsDto.fromData(jsonData['data']);
      } else {
        return jsonData['code'];
      }
    } else {
      throw ("Request failed, code[" + response.statusCode.toString() + "]");
    }
  }

  clearAll() {
    _authToken = null;
    _txId = null;
    _originTxId = null;

    currentProfileObject = null;
  }

  /// Used to build the headers for most methods, if its not used there is a reason for it
  _getHeaders() {
    if (_authToken != null) {
      return {'config': _configId, 'Authorization': "bearer " + _authToken, "Content-Type": "application/json"};
    } else {
      return {'config': _configId, "Content-Type": "application/json"};
    }
  }
}

class HttpRequestError {
  int code;
  String message;
  HttpRequestError({@required this.code, @required this.message});
}
