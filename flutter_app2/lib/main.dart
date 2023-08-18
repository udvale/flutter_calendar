import 'dart:math';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'database/database.dart';
import 'database/indicators.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', 'US'),
      ],
      home: CalenderPage(),
    ),
  );
}

class CalenderPage extends StatefulWidget {
  const CalenderPage({super.key});
  @override
  State<CalenderPage> createState() => CalenderPageState();
}

class CalenderPageState extends State<CalenderPage> {
  TextEditingController subjectController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeFromController = TextEditingController();
  TextEditingController timeToController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now();
  TimeOfDay today2 = TimeOfDay.now();
  TimeOfDay today1 = TimeOfDay.now();
  Color pickerColor = const Color(0xff443a49);
  Color newColor = Colors.blue;
  final Random _random = Random();
  String colorString = "";
  String? hexColor;
  String subject = "";
  String comment = "";
  CalendarDataSource<Object?>? dataSource;
  final List<Appointment> appointments = <Appointment>[];
  List<AppointmentData> appointmentsdb = <AppointmentData>[];
  Appointment? app;
  bool alertDialogVisible = false;
  int id = 0;

  @override
  void initState() {
    loadAppointmentsToCalendar();
    super.initState();
  }

  void loadAppointmentsToCalendar() async {
    try {
      appointmentsdb = await DBAppointment.fetchAppointments();
      for (AppointmentData a in appointmentsdb) {
        app = Appointment(
            subject: a.title,
            startTime: a.startTime!,
            endTime: a.endTime!,
            color: a.color!.withOpacity(1),
            notes: a.comment);
        setState(() {
          if (app != null) {
            _getCalendarDataSource(app!.subject, app!.startTime, app!.endTime,
                app!.color, app!.notes!);
          }
        });
      }
    } catch (error) {
      print('Error loading appointments: $error');
      // Handle the error appropriately
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
          onPressed: () {
            showBookingDialog(context);
          },
          child: const Icon(Icons.add)),
      body: SfCalendar(
        view: CalendarView.week,
        allowedViews: const [
          CalendarView.day,
          CalendarView.week,
          CalendarView.month,
          CalendarView.schedule,
          CalendarView.timelineDay,
          CalendarView.timelineMonth,
          CalendarView.timelineWeek
        ],
        firstDayOfWeek: 1,
        onTap: (CalendarTapDetails details) {
          calendarTapped(details);
        },
        showNavigationArrow: true,
        showDatePickerButton: true,
        // allowAppointmentResize: true,
        dragAndDropSettings: const DragAndDropSettings(
          allowScroll: true,
        ),
        dataSource: dataSource,
        // allowDragAndDrop: true,
        timeSlotViewSettings:
            const TimeSlotViewSettings(dateFormat: 'd', dayFormat: 'EEE'),
        viewHeaderStyle: const ViewHeaderStyle(
            dayTextStyle: TextStyle(fontSize: 10),
            dateTextStyle: TextStyle(fontSize: 20)),
        monthViewSettings: const MonthViewSettings(
            showAgenda: true,
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment),
      ),
    );
  }

  void changeColor() {
    setState(() {
      pickerColor = Color.fromARGB(_random.nextInt(256), _random.nextInt(256),
          _random.nextInt(256), _random.nextInt(256));
    });
  }

//Set parameters to default
  void setToNull() {
    setState(() {
      subjectController.text = "";
      descriptionController.text = "";
      dateController.text = "";
      timeToController.text = "";
      timeFromController.text = "";
    });
  }

  //Check if time slot is in the appointment list
  bool isEventTimeSlotOccupied(DateTime startTime, DateTime endTime) {
    for (var event in appointments) {
      if (event.startTime.isBefore(endTime) &&
          event.endTime.isAfter(startTime)) {
        return true;
      }
    }
    return false;
  }

  //Getting data information for appointments
  void _getCalendarDataSource(String subject, DateTime start, DateTime end,
      Color color, String comment) {
    Appointment app = Appointment(
      subject: subject,
      startTime: start,
      endTime: end,
      isAllDay: false,
      color: color,
      notes: comment,
    );

    if (isEventTimeSlotOccupied(startTime, endTime) == true) {
      showDialog(
        context: context,
        builder: (context) {
          return SizedBox(
            height: 20,
            width: 10,
            child: AlertDialog(
              title: const Text('Time Slot Occupied'),
              content: const Text(
                  'Cannot add an appointment at this time as it is already occupied by another event.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      );
    } else {
      appointments.add(app);
      dataSource
          ?.notifyListeners(CalendarDataSourceAction.add, <Appointment>[app]);
    }
    setState(() {
      dataSource = DataSource(appointments);
    });
  }

  void deletAppointments(int num) async {
    try {
      await DBAppointment.deletAppointments(num);
    } catch (error) {
      print('Error loading appointments: $error');
      // Handle the error appropriately
    }
  }

  //Get Appointment details
  void calendarTapped(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment ||
        details.targetElement == CalendarElement.agenda) {
      final Appointment appointment = details.appointments![0];
      for (AppointmentData a in appointmentsdb) {
        app = Appointment(
            subject: a.title,
            startTime: a.startTime!,
            endTime: a.endTime!,
            color: a.color!.withOpacity(1),
            notes: a.comment);
        if (appointment == app) {
          setState(() {
            id = a.id;
          });
        }
      }
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                appointment.subject,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              content: SizedBox(
                height: 68,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.access_time_sharp,
                          size: 17,
                        ),
                        Text(
                          DateFormat('    EEEE, MMMM d')
                              .format(appointment.startTime),
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                        const Text(' · '),
                        Text(
                          DateFormat('hh:mm a').format(appointment.startTime),
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                        const Text('–'),
                        Text(
                          DateFormat('hh:mm a').format(appointment.endTime),
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Text(" "),
                    Row(
                      children: [
                        const Icon(
                          Icons.subject_sharp,
                          size: 17,
                        ),
                        Text((("    ") + appointment.notes!),
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                            )),
                      ],
                    )
                  ],
                ),
              ),
              actions: <Widget>[
                SizedBox(
                  height: 25,
                  width: 70,
                  child: FloatingActionButton.extended(
                      backgroundColor: const Color.fromARGB(255, 97, 188, 202),
                      onPressed: () {
                        deletAppointments(id);
                        appointments.remove(appointment);
                        dataSource?.notifyListeners(
                            CalendarDataSourceAction.remove,
                            <Appointment>[appointment]);
                        setState(() {
                          dataSource = DataSource(appointments);
                        });
                        print("Done!");
                        Navigator.of(context).pop();
                      },
                      label: const Text("Delete")),
                ),
                SizedBox(
                  height: 25,
                  width: 70,
                  child: FloatingActionButton.extended(
                      backgroundColor: const Color.fromARGB(255, 167, 60, 60),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      label: const Text("Close")),
                ),
              ],
            );
          });
    } else {
      final int hour = details.date!.hour;
      final int minute = details.date!.minute;
      final int year = details.date!.year;
      final int month = details.date!.month;
      final int day = details.date!.day;
      DateTime timeFormat = DateTime(year, month, day, hour, minute, 00);
      setState(() {
        selectedDate = details.date!;
        dateController.text = DateFormat('yyyy-MM-dd').format(details.date!);
        startTime = timeFormat;
        today1 = TimeOfDay.fromDateTime(startTime);
        timeFromController.text =
            DateFormat('hh:mm a').format(timeFormat).toString();
        DateTime newTimeFormat = timeFormat.add(const Duration(hours: 1));
        endTime = newTimeFormat;
        today2 = TimeOfDay.fromDateTime(endTime);
        timeToController.text =
            DateFormat('hh:mm a').format(newTimeFormat).toString();
      });
      showBookingDialog(context);
    }
  }

  void closeAlertDialog() {
    setState(() {
      alertDialogVisible = false;
      setToNull();
    });
    Navigator.of(context).pop(); // Close the AlertDialog
  }

  //Add Appointment informations
  void showBookingDialog(BuildContext context) {
    setState(() {
      alertDialogVisible = true;
    });
    today2 = TimeOfDay.fromDateTime(startTime.add(const Duration(minutes: 30)));
    var alert = SizedBox(
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        content: WillPopScope(
          onWillPop: () async {
            closeAlertDialog();
            return false;
          },
          child: SizedBox(
            height: 350,
            width: 250,
            child: Column(
              children: [
                Column(
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            const Text('Subject:  '),
                            Expanded(
                              child: TextField(
                                controller: subjectController,
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.comment),
                                  labelText: "Subject",
                                ),
                                readOnly: false,
                                keyboardType: TextInputType.text,
                                onChanged: (newValue) {
                                  setState(() {
                                    subject = newValue;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Date:       '),
                            Expanded(
                              child: TextField(
                                controller: dateController,
                                decoration: const InputDecoration(
                                    icon: Icon(Icons.calendar_today),
                                    labelText: "Choose Date"),
                                readOnly: true,
                                onTap: () async {
                                  DateTime? date = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2099));
                                  if (date != null) {
                                    String formatted =
                                        DateFormat('yyyy-MM-dd').format(date);
                                    setState(() {
                                      dateController.text = formatted;
                                      selectedDate = date;
                                    });
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: [
                            const Text('From:      '),
                            Expanded(
                              child: TextField(
                                controller: timeFromController,
                                decoration: const InputDecoration(
                                    icon: Icon(Icons.lock_clock),
                                    labelText: "Choose Time"),
                                readOnly: false,
                                onTap: () async {
                                  TimeOfDay? time = await showTimePicker(
                                      context: context, initialTime: today1);
                                  if (time != null) {
                                    final int hour = time.hour;
                                    final int minute = time.minute;
                                    final int year = selectedDate.year;
                                    final int month = selectedDate.month;
                                    final int day = selectedDate.day;
                                    DateTime timeFormat = DateTime(
                                        year, month, day, hour, minute, 00);
                                    // ignore: use_build_context_synchronously
                                    String formattedTime = time.format(context);
                                    setState(() {
                                      timeFromController.text = formattedTime;
                                      startTime = timeFormat;
                                      today1 =
                                          TimeOfDay.fromDateTime(startTime);
                                      today2 = TimeOfDay.fromDateTime(startTime
                                          .add(const Duration(minutes: 30)));
                                    });
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: [
                            const Text('To:           '),
                            Expanded(
                              child: TextField(
                                controller: timeToController,
                                decoration: const InputDecoration(
                                    icon: Icon(Icons.lock_clock),
                                    labelText: "Choose Time"),
                                readOnly: false,
                                onTap: () async {
                                  TimeOfDay? time = await showTimePicker(
                                      context: context, initialTime: today2);
                                  if (time != null) {
                                    String stringformattedTime =
                                        // ignore: use_build_context_synchronously
                                        time.format(context);
                                    final int hour = time.hour;
                                    final int minute = time.minute;
                                    final int year = selectedDate.year;
                                    final int month = selectedDate.month;
                                    final int day = selectedDate.day;
                                    DateTime timeFormat = DateTime(
                                        year, month, day, hour, minute, 00);
                                    setState(() {
                                      timeToController.text =
                                          stringformattedTime;
                                      endTime = timeFormat;
                                      today2 = TimeOfDay.fromDateTime(endTime);
                                    });
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                        Row(children: [Text(" ")]),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 100,
                                width: 60,
                                child: TextField(
                                  controller: descriptionController,
                                  decoration: const InputDecoration(
                                    hintText: "Add Description",
                                    disabledBorder: UnderlineInputBorder(),
                                    filled: true,
                                  ),
                                  readOnly: false,
                                  expands: false,
                                  maxLines: 6,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.multiline,
                                  onChanged: (newValue) {
                                    setState(() {
                                      comment = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            height: 25,
            width: 70,
            child: FloatingActionButton.extended(
                backgroundColor: const Color.fromARGB(255, 70, 172, 66),
                onPressed: () {
                  changeColor();
                  Appointment newAppointment = Appointment(
                      subject: subject,
                      startTime: startTime,
                      endTime: endTime,
                      color: pickerColor,
                      notes: comment);
                  try {
                    DBAppointment.createAppointment(newAppointment);
                  } catch (e) {
                    print('Failed to create appointment in calendar: $e');
                  }
                  _getCalendarDataSource(
                      newAppointment.subject,
                      newAppointment.startTime,
                      newAppointment.endTime,
                      newAppointment.color.withOpacity(1),
                      newAppointment.notes!);
                  setToNull();
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                },
                label: const Text("Submit")),
          ),
          SizedBox(
            height: 25,
            width: 70,
            child: FloatingActionButton.extended(
                backgroundColor: const Color.fromARGB(255, 167, 60, 60),
                onPressed: () {
                  setToNull();
                  Navigator.of(context).pop();
                },
                label: const Text("Cancel")),
          ),
        ],
      ),
    );

    showDialog(
      context: context,
      // barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}

class DataSource extends CalendarDataSource {
  DataSource(List<Appointment> source) {
    appointments = source;
  }
}
