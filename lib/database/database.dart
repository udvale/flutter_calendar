import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_cal/database/indicators.dart';
import 'package:flutter_cal/database/controller.dart';

String subject = "";
DateTime start = DateTime.now();
DateTime end = DateTime.now();
Color? color;
String comment = "";

class DBAppointment {
  static Future createAppointment(Appointment appointment) async {
    final map = {
      'title': appointment.subject,
      'startTime': appointment.startTime.toString(),
      'endTime': appointment.endTime.toString(),
      'color': appointment.color.toString().substring(6, 16),
      'comment': appointment.notes,
    };
    final jsonString = jsonEncode(map);
    try {
      var url = Uri.parse(ApiConstants.apiUrl + ApiConstants.endPoints);
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept-Charset": "UTF-8"
        },
        body: jsonString,
      );

      if (response.statusCode == 200) {
        // Appointment created successfully
        print("Appointment created successfully");
      } else {
        // Handle error if the server returned a non-200 response
        throw Exception("Failed to create appointment: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error $e");
    }
  }

  static Future<List<AppointmentData>> fetchAppointments() async {
    try {
      var url = Uri.parse(ApiConstants.apiUrl + ("/appointments/"));
      final resp = await http.get(url, headers: {"Accept": "application/json"});

      if (resp.statusCode == 200) {
        final jsonResp = resp.body;
        final jsonData = json.decode(jsonResp)["result"] as List;

        final appointments =
            jsonData.map((data) => AppointmentData.fromJson(data)).toList();

        return appointments;
      } else {
        throw Exception('Failed to fetch appointments');
      }
    } catch (error) {
      throw Exception('Failed to fetch appointments: $error');
    }
  }

  static Future<void> deletAppointments(int id) async {
    try {
      var url = Uri.parse(ApiConstants.apiUrl + ("/appointments/") + ('$id'));
      await http.delete(url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
    } catch (e) {
      throw Exception("Failed to delete appointment: $e");
    }
  }
}
