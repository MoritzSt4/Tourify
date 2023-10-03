import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourify/views/detailPage.dart';

//WidgedBuilder
Widget buildCardWidget(
    Map<String, dynamic> tourData, BuildContext context, bool tapable) {
  String imageFileName = tourData['image'];
  return GestureDetector(
    onTap: tapable
        ? () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DetailView(tourData: tourData),
              ),
            );
          }
        : () {},
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
