import 'dart:async';
import 'dart:convert' show jsonDecode;
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter/physics.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:test_project/directions_repository.dart';

import 'directions_model.dart';

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

// EXAMPLE --------------------------------------------------------------------------
class MapSample extends StatefulWidget {
  const MapSample({super.key});
  @override
  State<MapSample> createState() => MapSampleState();
}

Widget buildCardWidget(Map<String, dynamic> tourData, BuildContext context) {
  String imageFileName = tourData['image'];

  return GestureDetector(
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DetailView(tourData: tourData),
        ),
      );
    },
    child: Container(
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/$imageFileName',
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  tourData['title'],
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 5),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  tourData['description'],
                  style: TextStyle(
                    fontSize: 14.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class MapSampleState extends State<MapSample> {
  double latOfUser = 49.01376089808605;
  double longOfUser = 8.40441737052201;
  bool isCardVisible = true;
  Directions? _info = null;

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
            markers: {
              const Marker(
                  markerId: MarkerId("Sonnenbad"),
                  position: LatLng(49.013406, 8.346916),
                  infoWindow:
                      InfoWindow(title: 'tour[x][name] (Sonnenbad)')), // Marker
            },
            polylines: {
              if (_info != null)
                Polyline(
                  polylineId: const PolylineId('overview_polyline'),
                  color: Colors.red,
                  width: 5,
                  points: _info!.polylinePoints // non-null assertion
                      .map((e) => LatLng(e.latitude, e.longitude))
                      .toList(),
                ),
            },
          ),
          Positioned(
            bottom: 10, // Abstand zum unteren Rand
            left: 10, // Abstand zum linken Rand
            right: 10, // Abstand zum rechten Rand
            child: GestureDetector(
              onVerticalDragUpdate: _handleSwipeToClose,
              child:
                  isCardVisible // die Cards werden nur angezeigt, wenn isCardVisible true ist
                      ? Container(
                          height: MediaQuery.of(context).size.height * 0.65,
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
            left: 320, // Verstecke die Buttons, wenn isCardVisible false ist
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _handleNavigate,
                  child: Icon(Icons.directions),
                ),
                SizedBox(height: 20),
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

  // Lädt Daten aus JSON
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

  Future<void> _goToTheCastle() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_castle));
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

  Future<void> _handleNavigate() async {
    final directions = await DirectionsRepository(dio: Dio()).getDirections(
        origin: LatLng(49.01376089808605, 8.40441737052201),
        destination: LatLng(49.013406, 8.346916));
    print(_info);
    setState(() => _info = directions);
    print("navigation gestartet");
    print(_info);
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

// EXAMPLE ENDS --------------------------------------------------------------------------
class DetailView extends StatelessWidget {
  final Map<String, dynamic> tourData;

  DetailView({required this.tourData});

  @override
  Widget build(BuildContext context) {
    // Hier kannst du die Detailansicht erstellen, basierend auf den tourData-Informationen
    // Zeige alle relevanten Informationen an
    return Scaffold(
      appBar: AppBar(
        title: Text('Detailansicht'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          children: [
            // Zeige die Details an, z.B. tourData['title'], tourData['description'], usw.
          ],
        ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;
    return Scaffold(
      body: Column(
        children: [
          Text('A random idea:'),
          BigCard(pair: pair),
          ElevatedButton(
            onPressed: () {
              appState.getNext();
            },
            child: Text('Next'),
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });
  final WordPair pair;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(pair.asLowerCase, style: style),
      ),
    );
  }
}
