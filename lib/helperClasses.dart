import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//WidgedBuilder
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

//VIEWS

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