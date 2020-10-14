
import 'package:json_annotation/json_annotation.dart';

class DateOfBirthConverter implements JsonConverter<DateTime, String> {
  const DateOfBirthConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime date) => "${date.year}-${date.month < 10 ? "0" : ""}${date.month}-${date.day < 10 ? "0" : ""}${date.day}";
}