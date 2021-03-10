import 'package:ecoupon_lib/common/verification_stage.dart';
import 'package:json_annotation/json_annotation.dart';

part 'company_profile.g.dart';

@JsonSerializable()
class CompanyProfile {

  @JsonKey(includeIfNull: false)
  final String uuid;

  @JsonKey(name: "wallet", nullable: true)
  final String walletID;

  @JsonKey(nullable: true)
  final String name;

  @JsonKey(name: "google_business_account", nullable: true)
  final String googleBusinessAccount;

  @JsonKey(nullable: true)
  final String uid;

  @JsonKey(name: "address_street", nullable: true)
  final String addressStreet;

  @JsonKey(name: "address_town", nullable: true)
  final String addressTown;
  
  @JsonKey(name: "address_postal_code", nullable: true)
  final String addressPostalCode;

  @JsonKey(name: "phone_number", nullable: true)
  final String telephoneNumber;

  @JsonKey(name: "verification_stage", includeIfNull: false)
  final VerificationStage verificationStage;

  CompanyProfile(this.uuid, this.walletID, this.name, this.googleBusinessAccount, this.uid, this.addressStreet, this.addressTown, this.addressPostalCode, this.telephoneNumber, this.verificationStage);

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => _$CompanyProfileFromJson(json);
  Map<String, dynamic> toJson() => _$CompanyProfileToJson(this);
}
