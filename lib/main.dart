import 'package:flutter/material.dart';
import 'package:sara_lab4/providers/exam_provider.dart';
import 'package:sara_lab4/screens/calendar_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExamProvider(),
      child: MaterialApp(
        title: 'Распоред на испити',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: CalendarScreen(),
      ),
    );
  }
}