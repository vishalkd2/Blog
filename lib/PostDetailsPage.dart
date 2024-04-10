import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostDetailsPage extends StatelessWidget {
  final DocumentSnapshot document;

  const PostDetailsPage({Key? key, required this.document}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              document['imageUrl'],
              fit: BoxFit.cover,
            ),
            SizedBox(height: 5),
            Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.teal
            ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.thumb_up),
                    iconSize: 15,
                    onPressed: () {
                      // Add functionality for like button
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.comment),
                    iconSize: 15,
                    onPressed: () {
                      // Add functionality for comment button
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.share),
                    iconSize: 15,
                    onPressed: () {
                      // Add functionality for share button
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.save),
                    iconSize: 15,
                    onPressed: () {
                      // Add functionality for save button
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document['title'], // Full title
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    document['description'], // Full description
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
