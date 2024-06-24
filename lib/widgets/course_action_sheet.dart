import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseActionSheet extends StatefulWidget {
  final Function(String course, String tee) onCourseSelected;
  final Function(
    Map<String, List<int>> pars,
    List<int> mensHcap,
    List<int> womensHcap,
    List<String> tees,
    Map<String, List<int>> yardages,
    String selectedTee,
  ) onCourseDataLoaded;
  final Map<String, List<int>> yardages;
  final Map<String, List<int>> pars;

  final List<int> mensHcap;
  final List<int> womensHcap;
  final List<String> tees;
  final String selectedTee;
  final bool isLoading;

  const CourseActionSheet({
    super.key,
    required this.onCourseSelected,
    required this.onCourseDataLoaded,
    required this.pars,
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
    final data = await rootBundle.loadString('assets/$course - Sheet1.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);

    List<int> mensHcap = csvTable[3].sublist(1).map((e) => e as int).toList();
    List<int> womensHcap = csvTable[4].sublist(1).map((e) => e as int).toList();
    List<String> tees =
        csvTable.map((row) => row[0].toString()).skip(5).toList();
    Map<String, List<int>> yardages = {};
    Map<String, List<int>> pars = {};
    for (var row in csvTable.skip(5)) {
      String teeName = row[0];
      List<int> yardage = row.sublist(1).map((e) => e as int).toList();
      List<int> par = row.sublist(19).map((e) => e as int).toList();
      yardages[teeName] = yardage;
      pars[teeName] = par;
    }
    String selectedTee = tees[0];

    setState(() {
      widget.onCourseDataLoaded(
          pars, mensHcap, womensHcap, tees, yardages, selectedTee);
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
          Text(courseName,
              style: const TextStyle(
                  fontSize: 20, color: CupertinoColors.systemBlue)),
          Text(courseLocation, style: const TextStyle(fontSize: 12)),
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
            style: TextStyle(fontSize: 25, color: CupertinoColors.systemGrey)),
        message: const Text('Select a course.',
            style: TextStyle(fontSize: 20, color: CupertinoColors.systemGrey)),
        actions: [
          _buildAction('beachgrove', 'Beach Grove Golf Club', 'Tsawwassen, BC'),
          _buildAction('bigskygc', 'Big Sky Golf Club', 'Pemberton, BC'),
          _buildAction('calclub', 'Cal Club', 'San Francisco, CA'),
          _buildAction('cordovabay', 'Cordova Bay Golf Course', 'Victoria, BC'),
          _buildAction(
              'fairmontwhistler', 'Chateau Fairmont Whistler', 'Whistler, BC'),
          _buildAction('highlandpacific', 'Highland Pacific Golf Course',
              'Victoria, BC'),
          _buildAction(
              'marinedrive', 'Marine Drive Golf Club', 'Vancouver, BC'),
          _buildAction('mcleery', 'McLeery Golf Course', 'Vancouver, BC'),
          _buildAction('morgancreek', 'Morgan Creek Golf Course', 'Surrey, BC'),
          _buildAction('musqueam', 'Musqueam Golf Course', 'Vancouver, BC'),
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
