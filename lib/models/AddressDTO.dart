import 'package:scoped_model/scoped_model.dart';

class AddressDTO extends Model {
  String unitComplex;
  String line1;
  String line2;
  String suburb;
  String city;
  String province;
  String country;
  String postalCode;
  String latitude;
  String longitude;

  AddressDTO({this.unitComplex, this.line1, this.line2, this.city, this.province, this.country, this.postalCode, this.latitude, this.longitude, this.suburb});

  factory AddressDTO.fromData(Map<dynamic, dynamic> data) {
    return AddressDTO(
        unitComplex: data['unit_complex'],
        line1: data['line1'],
        line2: data['line2'],
        city: data['city'],
        province: data['province'],
        country: data['country'],
        postalCode: data['postal_code'],
        latitude: data['latitude'],
        longitude: data['longitude'],
        suburb: data['suburb']);
  }

  Map<String, String> toData() {
    return {
      "unitComplex": unitComplex,
      "line1": line1,
      "line2": line2,
      "suburb": suburb,
      "city": city,
      "province": province,
      "country": country,
      "postalCode": postalCode,
      "latitude": latitude,
      "longitude": longitude,
    };
  }
}
