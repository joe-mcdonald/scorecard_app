import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scorecard_app/course_data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<String> favoriteCourseFiles = [];

  @override
  void initState() {
    super.initState();
    loadFavoriteCourses();
  }

  Future<void> loadFavoriteCourses() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteCourseFiles = prefs.getStringList('favoriteCourses') ?? [];
    });
  }

  Future<void> toggleFavoriteCourse(String courseFile) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favoriteCourseFiles.contains(courseFile)) {
        favoriteCourseFiles.remove(courseFile);
      } else {
        favoriteCourseFiles.add(courseFile);
      }
      prefs.setStringList('favoriteCourses', favoriteCourseFiles);
    });
  }

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

    Provider.of<CourseDataProvider>(context, listen: false).updateCourseData(
      newPar: pars[selectedTee]!,
      newMensHcap: mensHcap,
      newWomensHcap: womensHcap,
    );
  }

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _requestCourse() async {
    const phoneNumber = '6048087500';
    const message = 'I would like to request a course:';

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

  Widget buildCourseRow(String file, String name, String location) {
    bool isFavorite = favoriteCourseFiles.contains(file);
    return GestureDetector(
      onTap: () {
        _loadCourseData(file, name);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: CupertinoColors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Text column
            Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 20, color: CupertinoColors.systemBlue)),
                  Text(location,
                      style: const TextStyle(
                          fontSize: 12, color: CupertinoColors.systemGrey)),
                ],
              ),
            ),
            // Star icon (independently tappable)
            GestureDetector(
              onTap: () async => await toggleFavoriteCourse(file),
              behavior: HitTestBehavior.translucent,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  color: CupertinoColors.systemYellow,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCourses = [
      ['baileyranchgolfclub', 'Bailey Ranch Golf Club', 'Owasso, Oklahoma'],
      ['bandondunes', 'Bandon Dunes', 'Bandon, Oregon'],
      ['bandontrails', 'Bandon Trails', 'Bandon, Oregon'],
      ['beachgrovegolfclub', 'Beach Grove Golf Club', 'Tsawwassen, BC'],
      ['bigskygolfclub', 'Big Sky Golf Club', 'Pemberton, BC'],
      ['calclub', 'Cal Club', 'San Francisco, CA'],
      ['cordovabaygolfcourse', 'Cordova Bay Golf Course', 'Victoria, BC'],
      ['cordovabayridgecourse', 'Cordova Bay Ridge Course', 'Victoria, BC'],
      ['chateaufairmontwhistler', 'Chateau Fairmont Whistler', 'Whistler, BC'],
      ['desertfalls', 'Desert Falls', 'Palm Desert, CA'],
      ['eaglefalls', 'Eagle Falls', 'Palm Desert, CA'],
      ['highlandpacificgolfcourse', 'Highland Pacific', 'Victoria, BC'],
      ['marinedrivegolfclub', 'Marine Drive Golf Club', 'Vancouver, BC'],
      ['mcleerygolfcourse', 'McLeery Golf Course', 'Vancouver, BC'],
      ['morgancreekgolfcourse', 'Morgan Creek Golf Course', 'Surrey, BC'],
      ['musqueamgolfcourse', 'Musqueam Golf Course', 'Vancouver, BC'],
      ['nicklausnorthgolfclub', 'Nicklaus North Golf Club', 'Whistler, BC'],
      ['oldmacdonald', 'Old MacDonald', 'Bandon, Oregon'],
      ['pacificdunes', 'Pacific Dunes', 'Bandon, Oregon'],
      ['pheasantglengolfresort', 'Pheasant Glen Golf Resort', 'Nanaimo, BC'],
      ['pointgreyg&cc', 'Point Grey G&CC', 'Vancouver, BC'],
      ['royalcolwoodgolfclub', 'Royal Colwood Golf Club', 'Colwood, BC'],
      ['shaughnessyg&cc', 'Shaughnessy G&CC', 'Vancouver, BC'],
      ['sheepranch', 'Sheep Ranch', 'Bandon, Oregon'],
      ['universitygolfclub', 'University Golf Club', 'Vancouver, BC'],
      ['victoriagolfclub', 'Victoria Golf Club', 'Victoria, BC'],
      ['whistlergolfclub', 'Whistler Golf Club', 'Whistler, BC'],
    ];

    final favoriteCourses = allCourses
        .where((course) => favoriteCourseFiles.contains(course[0]))
        .toList();
    final regularCourses = allCourses
        .where((course) => !favoriteCourseFiles.contains(course[0]))
        .toList();

    return SizedBox(
      height: 435,
      child: CupertinoActionSheet(
        title: const Text('Courses',
            style: TextStyle(fontSize: 25, color: CupertinoColors.systemGrey)),
        message: const Text('Select a course.',
            style: TextStyle(fontSize: 20, color: CupertinoColors.systemGrey)),
        actions: [
          ...favoriteCourses.map((course) => buildCourseRow(
                course[0],
                course[1],
                course[2],
              )),
          if (favoriteCourses.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1),
            ),
          ...regularCourses.map((course) => buildCourseRow(
                course[0],
                course[1],
                course[2],
              )),
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
