import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseActionSheet extends StatefulWidget {
  final Function(String course, String tee) onCourseSelected;
  final Function(
      List<int> par,
      List<int> mensHcap,
      List<int> womensHcap,
      List<String> tees,
      Map<String, List<int>> yardages,
      String selectedTee) onCourseDataLoaded;
  final List<int> par;
  final List<int> mensHcap;
  final List<int> womensHcap;
  final List<String> tees;
  final Map<String, List<int>> yardages;
  final String selectedTee;
  final bool isLoading;

  const CourseActionSheet({
    super.key,
    required this.onCourseSelected,
    required this.onCourseDataLoaded,
    required this.par,
    required this.mensHcap,
    required this.womensHcap,
    required this.tees,
    required this.yardages,
    required this.selectedTee,
    required this.isLoading,
  });

  @override
  State<CourseActionSheet> createState() => _CourseActionSheetState();
}

class _CourseActionSheetState extends State<CourseActionSheet> {
  Future<void> _loadCourseData(String course, String courseName) async {
    final rawData = await rootBundle.loadString('assets/$course.csv');
    List<List<dynamic>> csvData = const CsvToListConverter().convert(rawData);

    List<int> par = csvData[2].sublist(1).map((e) => e as int).toList();
    List<int> mensHcap = csvData[3].sublist(1).map((e) => e as int).toList();
    List<int> womensHcap = csvData[4].sublist(1).map((e) => e as int).toList();
    List<String> tees =
        csvData.map((row) => row[0].toString()).skip(5).toList();
    Map<String, List<int>> yardages = {};
    for (var row in csvData.skip(5)) {
      String teeName = row[0];
      List<int> yardage = row.sublist(1).map((e) => e as int).toList();
      yardages[teeName] = yardage;
    }
    String selectedTee = tees[0];

    setState(() {
      widget.onCourseDataLoaded(
          par, mensHcap, womensHcap, tees, yardages, selectedTee);
      widget.onCourseSelected(courseName, selectedTee);
    });
  }

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _requestCourse() async {
    const phoneNumber = '6048087500';
    const message = 'I would like to request a course: ';

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      query: encodeQueryParameters(<String, String>{
        'body': message,
      }),
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw 'Could not launch $smsUri';
    }
  }

  CupertinoActionSheetAction _buildAction(
      String courseFile, String courseName, String courseLocation) {
    return CupertinoActionSheetAction(
      onPressed: () {
        _loadCourseData(courseFile, courseName);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Text(courseName),
          Text(courseLocation,
              style: const TextStyle(
                  fontSize: 12, color: CupertinoColors.systemGrey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 435,
      child: CupertinoActionSheet(
        title: const Text('Courses',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
        message: const Text('Select a course.'),
        actions: [
          _buildAction('beachgrove', 'Beach Grove Golf Club', 'Tsawwassen, BC'),
          _buildAction('bigskygc', 'Big Sky Golf Club', 'Pemberton, BC'),
          _buildAction('cordovabay', 'Cordova Bay Golf Course', 'Victoria, BC'),
          _buildAction('highlandpacific', 'Highland Pacific Golf Course',
              'Victoria, BC'),
          _buildAction(
              'marinedrive', 'Marine Drive Golf Club', 'Vancouver, BC'),
          _buildAction(
              'nicklausnorth', 'Nicklaus North Golf Club', 'Whistler, BC'),
          _buildAction(
              'pheasantglen', 'Pheasant Glen Golf Resort', 'Nanaimo, BC'),
          _buildAction('pointgrey', 'Point Grey G&CC', 'Vancouver, BC'),
          _buildAction(
              'royalcolwood', 'Royal Colwood Golf Club', 'Colwood, BC'),
          _buildAction('shaughnessy', 'Shaughnessy G&CC', 'Vancouver, BC'),
          _buildAction(
              'universitygolfclub', 'University Golf Club', 'Vancouver, BC'),
          _buildAction(
              'victoriagolfclub', 'Victoria Golf Club', 'Victoria, BC'),
          _buildAction('whistlergc', 'Whistler Golf Club', 'Whistler, BC'),
          CupertinoActionSheetAction(
            onPressed: () {
              _requestCourse();
              Navigator.pop(context);
            },
            child: const Text('Request a Course'),
          ),
        ],
      ),
    );
  }
}
