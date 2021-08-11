import 'package:app_usage/app_usage.dart';
import 'package:device_apps/device_apps.dart';
import 'package:ekam_app_usage/widgets/rotation_animation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUsageScreen extends StatefulWidget {
  const AppUsageScreen({Key? key}) : super(key: key);

  @override
  _AppUsageScreenState createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> {
  List<ModelApp> _displayApps = [];
  List<AppUsageInfo> _infos = [];
  String displayCenterHours = '';
  String displayCenterMins = '';
  List apps = [];
  List<ChartDataModel> _chartData = [];
  List<AppUsageInfo> _finalList = [];
  bool _isLoading = true;
  bool _expanded = false;
  var _totalTime = 0;
  var _firstapp;
  var _secondapp;
  var _thirdapp;
  var _otherapps;
  var _otherappsduration = 0;
  bool _isInit = true;
  Future<void> getUsageStats() async {
    try {
      DateTime endDate = new DateTime.now();
      DateTime startDate = endDate.subtract(Duration(hours: 1));
      List<AppUsageInfo> infoList = await AppUsage.getAppUsage(
        startDate,
        endDate,
      );
      setState(() {
        _infos = infoList;
      });

      for (var info in infoList) {
        print(info.toString());
      }
    } on AppUsageException catch (exception) {
      print(exception);
    }
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    if (duration.inMinutes >= 120) {
      return '${duration.inHours} hours and $twoDigitMinutes mins';
    } else if (duration.inMinutes < 120 && duration.inMinutes >= 60) {
      return '${duration.inHours} hour and $twoDigitMinutes mins';
    } else {
      return '${duration.inMinutes} mins';
    }
  }

  Future<void> getAllApps() async {
    await Future.wait(_finalList
        .map(
          (e) => DeviceApps.getApp(
            e.packageName,
            true,
          ).then((app) {
            apps.add(app);
          }),
        )
        .toList());
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      Firebase.initializeApp().then((_) async {
        getUsageStats().then((_) {
          _finalList =
              _infos.where((element) => element.usage.inMinutes > 0).toList();
          _finalList
              .sort((a, b) => a.usage.inMinutes.compareTo(b.usage.inMinutes));
          _finalList = _finalList.reversed.toList();
          _finalList.forEach((element) {
            _totalTime = _totalTime + element.usage.inMinutes;
            print('${element.appName} + ${element.usage.inMinutes}');
          });
          getAllApps().then((_) {
            print('start>>>>>>');
            var _totalDuration = Duration(minutes: _totalTime);

            _finalList.forEach((appElement) {
              final app = apps.firstWhere(
                  (element) => element.packageName == appElement.packageName);

              var usagePercentage =
                  (appElement.usage.inMinutes / _totalTime) * 100;
              var duration = _printDuration(appElement.usage);
              var appIcon = Image.memory(app.icon);

              ModelApp modelApp =
                  ModelApp(app.appName, usagePercentage, appIcon, duration);
              _displayApps.add(modelApp);
            });
            _firstapp =
                ChartDataModel(_displayApps[0].appName, _displayApps[0].usage);

            _secondapp =
                ChartDataModel(_displayApps[1].appName, _displayApps[1].usage);
            _thirdapp =
                ChartDataModel(_displayApps[2].appName, _displayApps[2].usage);
            _otherapps = ChartDataModel('Others',
                100 - (_firstapp.usage + _secondapp.usage + _thirdapp.usage));
            _otherappsduration = _totalTime -
                _finalList[0].usage.inMinutes -
                _finalList[1].usage.inMinutes -
                _finalList[2].usage.inMinutes;

            _chartData.add(_firstapp);
            _chartData.add(ChartDataModel('', 2));
            _chartData.add(_secondapp);
            _chartData.add(ChartDataModel('', 2));
            _chartData.add(_thirdapp);
            _chartData.add(ChartDataModel('', 2));
            _chartData.add(_otherapps);
            _chartData.add(ChartDataModel('', 2));
            displayCenterHours =
                '${Duration(minutes: _totalTime).inHours} Hours';
            displayCenterMins =
                '${Duration(minutes: _totalTime).inMinutes.remainder(60)} mins';
            _displayApps.forEach((element) {
              if (_displayApps.indexOf(element) < 10) {
                FirebaseFirestore.instance.collection('app_usage').add({
                  'app_name': element.appName,
                  'usage': element.duration,
                });
              }
            });
            setState(() {
              _isLoading = false;
            });
          });
        });
      });

      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(children: [
        SizedBox(
          height: 40,
        ),
        if (!_isLoading)
          Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              height: 100,
              child: Image.asset(
                'assets/images/ekam_logo.png',
                fit: BoxFit.cover,
              )),
        Expanded(
          child: _isLoading
              ? Center(
                  child: RotationAnimation(),
                )
              : Stack(children: [
                  Container(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      Navigator.of(context)
                                          .pushReplacement(MaterialPageRoute(
                                        builder: (context) => AppUsageScreen(),
                                      ));
                                    });
                                  },
                                  child: Text(
                                    'Total Time Spent on Mobile',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  )),
                              SizedBox(
                                width: 10,
                              ),
                              Icon(
                                Icons.refresh,
                                color: Colors.blue,
                                size: 30,
                              )
                            ],
                          ),
                          Container(
                            height: 280,
                            width: double.infinity,
                            child:
                                Stack(alignment: Alignment.center, children: [
                              SfCircularChart(
                                palette: [
                                  Colors.redAccent,
                                  Colors.transparent,
                                  Colors.purple,
                                  Colors.transparent,
                                  Colors.blueAccent,
                                  Colors.transparent,
                                  Colors.grey,
                                  Colors.transparent,
                                ],
                                series: <DoughnutSeries>[
                                  DoughnutSeries<ChartDataModel, String>(
                                      cornerStyle: CornerStyle.bothCurve,
                                      innerRadius: '95',
                                      dataSource: _chartData,
                                      xValueMapper: (ChartDataModel data, _) =>
                                          data.appName,
                                      yValueMapper: (ChartDataModel data, _) =>
                                          data.usage)
                                ],
                              ),
                              Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (Duration(minutes: _totalTime)
                                            .inMinutes >
                                        60)
                                      Text(
                                        displayCenterHours,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                      ),
                                    Text(
                                      displayCenterMins,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                  ],
                                ),
                              )
                            ]),
                          )
                        ]),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 300,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(30),
                                )),
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 30),
                                  child: Text(
                                    'Top 3 Apps killing your time:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    child: ListView(
                                      children: [
                                        ListTile(
                                          leading: _displayApps[0].appIcon,
                                          title: Text(
                                            _displayApps[0].appName,
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle:
                                              Text(_displayApps[0].duration,
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  )),
                                          trailing: Text(
                                            '${_displayApps[0].usage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          ),
                                        ),
                                        ListTile(
                                          leading: _displayApps[1].appIcon,
                                          title: Text(
                                            _displayApps[1].appName,
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle:
                                              Text(_displayApps[1].duration,
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  )),
                                          trailing: Text(
                                            '${_displayApps[1].usage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          ),
                                        ),
                                        ListTile(
                                          leading: _displayApps[2].appIcon,
                                          title: Text(
                                            _displayApps[2].appName,
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle:
                                              Text(_displayApps[2].duration,
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  )),
                                          trailing: Text(
                                            '${_displayApps[2].usage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          ),
                                        ),
                                        ListTile(
                                          leading: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _expanded = !_expanded;
                                              });
                                            },
                                            icon: Icon(
                                              !_expanded
                                                  ? Icons.arrow_drop_down
                                                  : Icons.arrow_drop_up,
                                              size: 25,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          subtitle: Text(
                                              _printDuration(Duration(
                                                  minutes: (_otherapps.usage *
                                                          _totalTime /
                                                          100)
                                                      .ceil())),
                                              style: TextStyle(
                                                color: Colors.red,
                                              )),
                                          title: Text(
                                            'Other Apps',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          trailing: Text(
                                            '${_otherapps.usage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          ),
                                        ),
                                        if (_expanded)
                                          AnimatedContainer(
                                            height: _expanded
                                                ? (_displayApps.length - 3) * 75
                                                : 0,
                                            duration:
                                                Duration(milliseconds: 500),
                                            curve: Curves.easeInOut,
                                            child: ListView.builder(
                                              physics:
                                                  NeverScrollableScrollPhysics(),
                                              itemCount:
                                                  _displayApps.length - 3,
                                              itemBuilder: (context, index) =>
                                                  Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 18),
                                                child: ListTile(
                                                  leading:
                                                      _displayApps[index + 3]
                                                          .appIcon,
                                                  title: Text(
                                                    _displayApps[index + 3]
                                                        .appName,
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  subtitle: Text(
                                                      _displayApps[index + 3]
                                                          .duration,
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      )),
                                                  trailing: Text(
                                                    '${_displayApps[index + 3].usage.toStringAsFixed(1)}%',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],

                                      // itemBuilder: (context, index) => ListTile(
                                      //   leading: _displayApps[index].appIcon,
                                      //   title:
                                      //       Text(_displayApps[index].appName),
                                      //   subtitle:
                                      //       Text(_displayApps[index].duration),
                                      //   trailing: Text(
                                      //       '${_displayApps[index].usage.toStringAsFixed(1)}%'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ]),
        ),
      ]),
    );
  }
}

class ModelApp {
  final String appName;
  final double usage;
  final Image appIcon;
  final String duration;

  ModelApp(this.appName, this.usage, this.appIcon, this.duration);
}

class ChartDataModel {
  final String appName;
  final usage;

  ChartDataModel(this.appName, this.usage);
}
