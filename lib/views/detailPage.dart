import 'package:flutter/material.dart';

import 'activePage.dart';

class DetailView extends StatefulWidget {
  final Map<String, dynamic> tourData;

  DetailView({required this.tourData});

  @override
  _DetailView createState() => _DetailView();
}

class _DetailView extends State<DetailView> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> locationsList = widget.tourData['locations'];
    final List<String> imagesList = locationsList.map((location) {
      return 'assets/images/${location['image']}';
    }).toList();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) {
              setState(() {
                if (details.velocity.pixelsPerSecond.dx > 0) {
                  currentIndex = (currentIndex - 1) % imagesList.length;
                } else if (details.velocity.pixelsPerSecond.dx < 0) {
                  currentIndex = (currentIndex + 1 + imagesList.length) %
                      imagesList.length;
                }
              });
            },
            child: Image.asset(
              imagesList[currentIndex],
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 250,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < imagesList.length; i++)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor:
                        i == currentIndex ? Colors.blue : Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.65,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ActiveTourView(),
                  ),
                );
              },
              child: Container(
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
                margin: EdgeInsets.all(16.0),
                padding: EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tourData['title'],
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        widget.tourData['detailDescription'],
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      Divider(
                        thickness: 1,
                        color: Colors.black,
                        height: 30,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dauer: ' + widget.tourData['duration'],
                            style: TextStyle(
                              fontSize: 14.0,
                            ),
                          ),
                          Text(
                            widget.tourData['category'],
                            style: TextStyle(
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        locationsList.length.toString() + ' Stopps',
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
