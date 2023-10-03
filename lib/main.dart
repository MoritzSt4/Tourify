import 'dart:async';
import 'dart:convert' show jsonDecode;
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:test_project/directions_repository.dart';

import 'helperClasses.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required by FlutterConfig
  await FlutterConfig.loadEnvVariables();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Tourify',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromARGB(255, 219, 236, 255)),
        ),
        home: MapSample(),
      ),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({super.key});
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  double latOfUser = 49.01376089808605;
  double longOfUser = 8.40441737052201;
  bool isCardVisible = true;

  final PageController _pageController = PageController(initialPage: 0);
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(49.015029983797106, 8.390162377008094),
    zoom: 16,
  );
  static const CameraPosition _castle = CameraPosition(
      bearing: 5,
      target: LatLng(49.01376089808605, 8.40441737052201),
      tilt: 60,
      zoom: 18);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            bottom: 0, // Abstand zum unteren Rand
            left: 0, // Abstand zum linken Rand
            right: 0, // Abstand zum rechten Rand
            child: GestureDetector(
              onVerticalDragUpdate: _handleSwipeToClose,
              child:
                  isCardVisible // die Cards werden nur angezeigt, wenn isCardVisible true ist
                      ? Container(
                          height: MediaQuery.of(context).size.height * 0.65,
                          margin: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FutureBuilder<List<Widget>>(
                            //FutureBuilder ist ein Error handler aufgrund der asychronen Funktion vonm readAndBuildCards
                            future: readAndBuildCards(context),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator(); // Loading indicator
                              } else if (snapshot.hasError) {
                                return Text(
                                    'Error loading cards'); // Error message
                              } else if (snapshot.hasData) {
                                return PageView(
                                  controller: _pageController,
                                  children: snapshot.data!,
                                ); // List of widgets
                              } else {
                                return Text('No data'); // Other states
                              }
                            },
                          ),
                        )
                      : SizedBox(),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300), // Animationsdauer
            bottom: isCardVisible ? 550 : 20,
            left: 320,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      1,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    _goToTheCastle();
                  },
                  child: Icon(Icons.play_arrow),
                ),
                SizedBox(height: 20),
                FloatingActionButton(
                  onPressed: _goToCurrentLocation,
                  child: Icon(Icons.gps_not_fixed),
                ),
                SizedBox(height: 20),
                FloatingActionButton(
                  onPressed: () {
                    _handleIsCardVisible();
                  },
                  child: Icon(Icons.view_carousel_rounded),
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Functions
  Future<void> _goToTheCastle() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_castle));
  }

  Future<List<dynamic>> readJson() async {
    final String response =
        await rootBundle.loadString('assets/data/citytour.json');
    final List<dynamic> data = jsonDecode(response);
    return data;
  }

  Future<List<Widget>> readAndBuildCards(BuildContext context) async {
    final citytourJsonContent =
        await readJson(); //lädt die JSON Datei um Karten mit Inhalt zu erzeugen
    List<Widget> citytourList = []; // enthät die Karten der Touren
    for (int i = 0; i < citytourJsonContent.length; i++) {
      citytourList.add(
        buildCardWidget(citytourJsonContent[i], context),
      );
    }
    return citytourList;
  }

  Future<void> _handleIsCardVisible() async {
    if (isCardVisible) {
      setState(() {
        isCardVisible = false;
      });
    } else {
      setState(() {
        isCardVisible = true;
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    _getCurrentLocation().then((value) {
      latOfUser = double.parse('${value.latitude}');
      longOfUser = double.parse('${value.longitude}');
    });
    CameraPosition posUser = CameraPosition(
        bearing: 5, target: LatLng(latOfUser, longOfUser), zoom: 18);
    controller.animateCamera(CameraUpdate.newCameraPosition(posUser));
  }

  void _handleSwipeToClose(DragUpdateDetails details) {
    if (details.primaryDelta! > 0) {
      // Swipe nach unten
      setState(() {
        isCardVisible = false;
      });
      ; // Karten ausblenden
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Standortzugriff ist deaktiviert');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Standortzugriff wurde nicht erlaubt');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          "Dein Standortzugriff wurde abgelehnt, Standoertzugriff nicht möglich!");
    }
    return await Geolocator.getCurrentPosition();
  }
}
