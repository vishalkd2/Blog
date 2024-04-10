import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LoginPage.dart';
import 'PostDetailsPage.dart';
import 'UploadScreen.dart';

class Homepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Homepage'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('images').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Get the current user
          User? currentUser = FirebaseAuth.instance.currentUser;

          // Filter documents based on visibility and user
          List<DocumentSnapshot> filteredDocuments = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;

            // Check if the post is public or posted by the current user
            return data['isPublic'] == true || (currentUser != null && data['userId'] == currentUser.uid);
          }).toList();

          // Display filtered documents in a scrollable list
          return ListView.builder(
            itemCount: filteredDocuments.length,
            itemBuilder: (context, index) {
              var document = filteredDocuments[index];
              return PostCard(document: document);
            },
          );
        },
      ),
      drawer: AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to UploadScreen when FloatingActionButton is pressed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UploadScreen()),
          );
        },
        child: Icon(Icons.upload),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<User?>(
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Replace progress indicator with an empty SizedBox
            return SizedBox();
          }
          if (snapshot.hasData && snapshot.data != null) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  // Replace progress indicator with an empty SizedBox
                  return SizedBox();
                }
                if (userSnapshot.hasData && userSnapshot.data != null) {
                  Map<String, dynamic>? userData = userSnapshot.data!.data() as Map<String, dynamic>?;

                  return DrawerContent(userData: userData);
                } else {
                  return DrawerContent(userData: null);
                }
              },
            );
          } else {
            return DrawerContent(userData: null);
          }
        },
      ),
    );
  }
}

class DrawerContent extends StatelessWidget {
  final Map<String, dynamic>? userData;

  DrawerContent({required this.userData});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        UserAccountsDrawerHeader(
          accountName: Text(userData?['name'] ?? ''),
          accountEmail: Text(userData?['email'] ?? ''),
          decoration: BoxDecoration(color: Colors.blue),
          currentAccountPicture: CircleAvatar(
            backgroundImage: NetworkImage(userData?['profile_picture'] ?? ''),
          ),
        ),
        ListTile(
          leading: Icon(Icons.save),
          title: Text('Favourite'),
          onTap: () {
            // Add functionality for Save button
          },
        ),
        ListTile(
          leading: Icon(Icons.share),
          title: Text('Shared'),
          onTap: () {
            // Add functionality for Shared button
          },
        ),
        ListTile(
          leading: Icon(Icons.person),
          title: Text('Profile'),
          onTap: () {
            // Add functionality for Profile button
          },
        ),
        ListTile(
          leading: Icon(Icons.developer_board),
          title: Text('About Developer'),
          onTap: () {
            // Add functionality for About Developer button
          },
        ),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Logout'),
          onTap: () async {
            // Logout user
            FirebaseAuth.instance.signOut(); // Logout user from Firebase

            // Navigate to login page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
      ],
    );
  }
}

class PostCard extends StatelessWidget {
  final DocumentSnapshot document;

  const PostCard({Key? key, required this.document}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          // Open the post details page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostDetailsPage(document: document)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FutureBuilder(
                    future: FirebaseFirestore.instance.collection('users').doc(document['userId']).get(),
                    builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (userSnapshot.hasError) {
                        return Text('Error: ${userSnapshot.error}');
                      }
                      if (userSnapshot.hasData && userSnapshot.data != null) {
                        String userName = userSnapshot.data!['name'];
                        String userProfilePicture = userSnapshot.data!['profile_picture'];
                        return Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(userProfilePicture),
                            ),
                            SizedBox(width: 8),
                            Text(
                              userName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Text('Unknown user');
                      }
                    },
                  ),
                ),
              ],
            ),
            Image.network(
              document['imageUrl'],
              fit: BoxFit.cover,
              height: 200, // Adjust the height to make the image larger
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _limitText(document['title'], 15), // Limiting to 15 words
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _limitText(document['description'], 30), // Limiting to 30 words
                    style: TextStyle(
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis, // Adding ellipsis if text exceeds the limit
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _limitText(String text, int limit) {
    if (text.split(' ').length > limit) {
      return text.split(' ').take(limit).join(' ') + '...';
    } else {
      return text;
    }
  }
}


