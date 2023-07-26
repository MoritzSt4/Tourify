import 'dart:async';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';


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
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 219, 236, 255)),
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

class MapSampleState extends State<MapSample> {
  double latOfUser = 49.01376089808605;
  double longOfUser = 8.40441737052201;

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(49.015029983797106, 8.390162377008094),
    zoom: 16,
  );

  static const CameraPosition _kLake = CameraPosition(
      bearing: 5,
      target: LatLng(49.01376089808605, 8.40441737052201),
      tilt: 60,
      zoom: 18);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        zoomControlsEnabled: false,
        myLocationEnabled: true,
      ),
      floatingActionButton: 
         Column(
          mainAxisAlignment: MainAxisAlignment.end,
          
          children: [
            FloatingActionButton(
              onPressed:  _goToCurrentLocation,
              child: Icon(Icons.gps_not_fixed),
            ),

            SizedBox(
              height: 20,
            ),

            FloatingActionButton(
              onPressed:  _goToTheCastle, 
              child: Icon(Icons.view_carousel_rounded),
            ),

            SizedBox(
              height: 20,
            ),
          
        ],
        
      )
      
    );
  }

  Future<void> _goToTheCastle() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  Future<void> _goToCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    _getCurrentLocation().then((value) {
      latOfUser = double.parse('${value.latitude}');
      longOfUser = double.parse('${value.longitude}');
    });

     CameraPosition posUser = CameraPosition(
      bearing: 5,
      target: LatLng(latOfUser, longOfUser),
      zoom: 18);

    controller.animateCamera(CameraUpdate.newCameraPosition(posUser));
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled) {
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
      return Future.error("Dein Standortzugriff wurde abgelehnt, Standoertzugriff nicht möglich!");
    }

    return await Geolocator.getCurrentPosition();
  }

}
// EXAMPLE ENDS --------------------------------------------------------------------------


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

    return Card
    (
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(pair.asLowerCase, style: style),
      ),
    );
  }
}