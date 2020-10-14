import 'package:ecoupon_lib/common/verification_stage.dart';
import 'package:json_annotation/json_annotation.dart';

part 'company_profile.g.dart';

@JsonSerializable()
class CompanyProfile {

  @JsonKey(includeIfNull: false)
  final String uuid;

  @JsonKey(name: "wallet", nullable: false)
  final String walletID;

  @JsonKey(nullable: false)
  final String name;

  @JsonKey(nullable: false)
  final String uid;

  @JsonKey(name: "address_street", nullable: false)
  final String addressStreet;

  @JsonKey(name: "address_town", nullable: false)
  final String addressTown;
  
  @JsonKey(name: "address_postal_code", nullable: false)
  final String addressPostalCode;

  @JsonKey(name: "phone_number", nullable: false)
  final String telephoneNumber;

  @JsonKey(name: "verification_stage", includeIfNull: false)
  final VerificationStage verificationStage;

  CompanyProfile(this.uuid, this.walletID, this.name, this.uid, this.addressStreet, this.addressTown, this.addressPostalCode, this.telephoneNumber, this.verificationStage);

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => _$CompanyProfileFromJson(json);
  Map<String, dynamic> toJson() => _$CompanyProfileToJson(this);
}
