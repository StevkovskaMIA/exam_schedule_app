import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Exam Schedule',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExamScheduleScreen(),
    );
  }
}

class ExamScheduleScreen extends StatefulWidget {
  const ExamScheduleScreen({super.key});

  @override
  ExamScheduleScreenState createState() => ExamScheduleScreenState();
}

class ExamScheduleScreenState extends State<ExamScheduleScreen> {
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  late Map<DateTime, List<String>> _events;
  late TextEditingController _timeController;
  late TextEditingController _locationController;
  late DateTime _selectedDay;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _events = {};
    _timeController = TextEditingController();
    _locationController = TextEditingController();
    _selectedDay = DateTime.now();
    _getCurrentLocation();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  void _scheduleNotification(String location) async {
    if (_currentPosition == null) return;

    var androidDetails = AndroidNotificationDetails(
        'channel_id', 'channel_name',
        importance: Importance.high);
    var platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Exam Location Reminder',
      'You have an exam at $location near your current location!',
      platformDetails,
      payload: 'Exam Reminder',
    );
  }

  void _addEvent() {
    final String time = _timeController.text;
    final String location = _locationController.text;

    if (time.isNotEmpty && location.isNotEmpty) {
      final event = 'Exam at $time, Location: $location';

      setState(() {
        if (_events[_selectedDay] == null) {
          _events[_selectedDay] = [];
        }
        _events[_selectedDay]?.add(event);
        _timeController.clear();
        _locationController.clear();
      });

      _scheduleNotification(location);
    }
  }

  Widget _buildEventList() {
    final events = _events[_selectedDay];
    if (events == null || events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('No exams scheduled for this day'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: events.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(events[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exam Schedule'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _selectedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
              },
              eventLoader: (day) {
                return _events[day] ?? [];
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: 'Time of Exam',
                      hintText: 'Enter exam time',
                    ),
                  ),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      hintText: 'Enter exam location',
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _addEvent();
                    },
                    child: Text('Add Exam'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildEventList(),
          ],
        ),
      ),
    );
  }
}
