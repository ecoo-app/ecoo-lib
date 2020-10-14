import 'package:json_annotation/json_annotation.dart';

part 'address_auto_completion_result.g.dart';

@JsonSerializable()
class AddressAutoCompletionResult {

  @JsonKey(name: "address_street", nullable: false)
  String street;

  @JsonKey(name: "address_town", nullable: false)
  String town;

  @JsonKey(name: "address_postal_code", nullable: false)
  String postalCode;

  AddressAutoCompletionResult(this.street, this.town, this.postalCode);

  factory AddressAutoCompletionResult.fromJson(Map<String, dynamic> json) => _$AddressAutoCompletionResultFromJson(json);
  Map<String, dynamic> toJson() => _$AddressAutoCompletionResultToJson(this);
}

enum AddressAutoCompletionTarget {
  user,
  company
}
