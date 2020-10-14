import 'package:json_annotation/json_annotation.dart';

enum VerificationStage {
  @JsonValue(0) notMatched,
  @JsonValue(1) pendingPIN,
  @JsonValue(2) verified,
  @JsonValue(3) maxClaimsReached
}