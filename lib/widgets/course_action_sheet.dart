import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
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
  List<String> favoriteCourses = [];
  bool showFavoritesOnly = false; // can toggle this to show favorites

  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteCourses = prefs.getStringList('favoriteCourses') ?? [];
    });
  }

  Future<void> _toggleFavorite(String courseFile) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favoriteCourses.contains(courseFile)) {
        favoriteCourses.remove(courseFile);
      } else {
        favoriteCourses.add(courseFile);
      }
      prefs.setStringList('favoriteCourses', favoriteCourses);
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

  Widget _buildAction(
      String courseFile, String courseName, String courseLocation) {
    bool isFavorite = favoriteCourses.contains(courseFile);

    return GestureDetector(
      onTap: () async {
        await _loadCourseData(courseFile, courseName);
        Navigator.pop(context);
      },
      onLongPress: () async {
        await _toggleFavorite(courseFile);
      },
      behavior: HitTestBehavior.opaque, // Ensures entire row is tappable
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Course Name & Location (Now just text, no GestureDetector needed)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseName,
                    style: const TextStyle(
                      fontSize: 20,
                      color: CupertinoColors.systemBlue,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Text(
                    courseLocation,
                    style: const TextStyle(
                        fontSize: 12, color: CupertinoColors.systemGrey),
                  )
                ],
              ),
            ),

            // Star Icon (Reflects Favorite Status)
            Icon(
              isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
              color: CupertinoColors.systemYellow,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> courseActions = [
      _buildAction(
          'baileyranchgolfclub', 'Bailey Ranch Golf Club', 'Owasso, Oklahoma'),
      _buildAction('bandondunes', 'Bandon Dunes', 'Bandon, Oregon'),
      _buildAction('bandontrails', 'Bandon Trails', 'Bandon, Oregon'),
      _buildAction(
          'beachgrovegolfclub', 'Beach Grove Golf Club', 'Tsawwassen, BC'),
      _buildAction('bigskygolfclub', 'Big Sky Golf Club', 'Pemberton, BC'),
      _buildAction('calclub', 'Cal Club', 'San Francisco, CA'),
      _buildAction(
          'cordovabaygolfcourse', 'Cordova Bay Golf Course', 'Victoria, BC'),
      _buildAction('chateaufairmontwhistler', 'Chateau Fairmont Whistler',
          'Whistler, BC'),
      _buildAction('highlandpacificgolfcourse', 'Highland Pacific Golf Course',
          'Victoria, BC'),
      _buildAction(
          'marinedrivegolfclub', 'Marine Drive Golf Club', 'Vancouver, BC'),
      _buildAction('mcleerygolfcourse', 'McLeery Golf Course', 'Vancouver, BC'),
      _buildAction(
          'morgancreekgolfcourse', 'Morgan Creek Golf Course', 'Surrey, BC'),
      _buildAction(
          'musqueamgolfcourse', 'Musqueam Golf Course', 'Vancouver, BC'),
      _buildAction(
          'nicklausnorthgolfclub', 'Nicklaus North Golf Club', 'Whistler, BC'),
      _buildAction('oldmacdonald', 'Old MacDonald', 'Bandon, Oregon'),
      _buildAction('pacificdunes', 'Pacific Dunes', 'Bandon, Oregon'),
      _buildAction(
          'pheasantglengolfresort', 'Pheasant Glen Golf Resort', 'Nanaimo, BC'),
      _buildAction('pointgreyg&cc', 'Point Grey G&CC', 'Vancouver, BC'),
      _buildAction(
          'royalcolwoodgolfclub', 'Royal Colwood Golf Club', 'Colwood, BC'),
      _buildAction('shaughnessyg&cc', 'Shaughnessy G&CC', 'Vancouver, BC'),
      _buildAction('sheepranch', 'Sheep Ranch', 'Bandon, Oregon'),
      _buildAction(
          'universitygolfclub', 'University Golf Club', 'Vancouver, BC'),
      _buildAction('victoriagolfclub', 'Victoria Golf Club', 'Victoria, BC'),
      _buildAction('whistlergolfclub', 'Whistler Golf Club', 'Whistler, BC')
    ];

    // List<CupertinoActionSheetAction> displayedActions = showFavoritesOnly
    //     ? allActions.where((action) {
    //         String courseFile = action.child is Row
    //             ? (action.child as Row).children[1].key.toString()
    //             : '';
    //         return favoriteCourses.contains(courseFile);
    //       }).toList()
    //     : allActions;

    if (showFavoritesOnly) {
      courseActions = courseActions.where((course) {
        final courseFile =
            (course as GestureDetector).onTap.toString().split("'")[1];
        return favoriteCourses.contains(courseFile);
      }).toList();
    }

    return SizedBox(
      height: 435,
      child: CupertinoActionSheet(
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Courses',
                style:
                    TextStyle(fontSize: 25, color: CupertinoColors.systemGrey),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  showFavoritesOnly = !showFavoritesOnly;
                });
              },
              child: Icon(
                showFavoritesOnly
                    ? CupertinoIcons.star_fill
                    : CupertinoIcons.star,
                color: CupertinoColors.systemYellow,
                size: 30,
              ),
            ),
          ],
        ),
        message: const Text('Select a course.',
            style: TextStyle(fontSize: 20, color: CupertinoColors.systemGrey)),
        actions: courseActions,
        // actions: [
        //   ...displayedActions,
        //   CupertinoActionSheetAction(
        //     onPressed: () {
        //       _requestCourse();
        //       Navigator.pop(context);
        //     },
        //     child: const Text('Request a Course'),
        //   ),
        // ],
      ),
    );
  }
}
