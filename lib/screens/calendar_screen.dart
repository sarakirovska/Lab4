import 'package:flutter/material.dart';
import 'package:sara_lab4/providers/exam_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

import 'add_event_screen.dart';
import 'map_screen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Распоред на испити',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.view_agenda),
            onPressed: () {
              setState(() {
                if (_calendarFormat == CalendarFormat.month) {
                  _calendarFormat = CalendarFormat.week;
                } else if (_calendarFormat == CalendarFormat.week) {
                  _calendarFormat = CalendarFormat.twoWeeks;
                } else {
                  _calendarFormat = CalendarFormat.month;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) {
              return context.read<ExamProvider>().getEventsForDay(day);
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Consumer<ExamProvider>(
              builder: (context, examProvider, child) {
                final events = _selectedDay != null
                    ? examProvider.getEventsForDay(_selectedDay!)
                    : [];
                return events.isEmpty
                    ? Center(
                        child: Text(
                          'Нема испити за избраниот ден.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        separatorBuilder: (context, index) => Divider(),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return ListTile(
                            leading: Icon(
                              Icons.event_note,
                              color: Colors.blueAccent,
                            ),
                            title: Text(
                              event.title,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${event.dateTime.toString()} - ${event.location}',
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              // Navigate to map screen with the event location
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapScreen(event: event),
                                ),
                              );
                            },
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add event screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEventScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Додај нов испит',
        backgroundColor: Colors.greenAccent,
      ),
    );
  }
}
