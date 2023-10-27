import 'dart:ui';

class AppointmentData {
  AppointmentData({
    this.id = 0,
    this.title = "",
    this.startTime,
    this.endTime,
    this.color,
    this.comment = "",
  });

  int id = 0;
  String title = "";
  DateTime? startTime;
  DateTime? endTime;
  Color? color;
  String comment = "";

  factory AppointmentData.fromJson(Map<String, dynamic> json) =>
      AppointmentData(
        id: json['id'],
        title: json['title'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        color: _parseColor((json['color'])),
        comment: json['comment'],
      );

  static Color _parseColor(String colorString) {
    final int colorIntValue = int.parse(colorString);
    return Color(colorIntValue);
  }
}