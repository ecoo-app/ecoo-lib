import 'package:ecoupon_lib/common/date_of_birth_converter.dart';
import 'package:ecoupon_lib/common/verification_stage.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
@DateOfBirthConverter()
class UserProfile {
  
  @JsonKey(includeIfNull: false)
  final String uuid;

  @JsonKey(name: "wallet", nullable: false)
  final String walletID;

  @JsonKey(name: "first_name", nullable: false)
  final String firstName;

  @JsonKey(name: "last_name", nullable: false)
  final String lastName;

  @JsonKey(name: "address_street", nullable: false)
  final String addressStreet;

  @JsonKey(name: "address_town", nullable: false)
  final String addressTown;
  
  @JsonKey(name: "address_postal_code", nullable: false)
  final String addressPostalCode;

  @JsonKey(name: "telephone_number", nullable: false)
  final String telephoneNumber;

  @JsonKey(name: "date_of_birth", nullable: false)
  final DateTime dateOfBirth;

  @JsonKey(name: "place_of_origin", nullable: false)
  final String placeOfOrigin;

  @JsonKey(name: "verification_stage", includeIfNull: false)
  final VerificationStage verificationStage;

  UserProfile(this.uuid, this.walletID, this.firstName, this.lastName, this.addressStreet, this.addressTown, this.addressPostalCode, this.telephoneNumber, this.dateOfBirth, this.placeOfOrigin, this.verificationStage);

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
