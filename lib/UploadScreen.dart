import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _image;
  final picker = ImagePicker();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;
  bool _isPublic = false;

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _uploadImage() async {
    setState(() {
      _isUploading = true;
    });

    if (_image == null || _titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Image, title, and description cannot be empty.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    Reference ref = FirebaseStorage.instance.ref().child("images/${DateTime.now().millisecondsSinceEpoch}.jpg");
    UploadTask uploadTask = ref.putFile(_image!);
    TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
    String imageUrl = await snapshot.ref.getDownloadURL();

    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();

    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      // Check if user is signed in
      if (user != null) {
        // Save image details to Firestore
        await FirebaseFirestore.instance.collection('images').add({
          'title': title,
          'description': description,
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'isPublic': _isPublic,
          'userId': user.uid, // Associate post with user ID
        });

        Fluttertoast.showToast(
          msg: 'Post uploaded successfully.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _image = null;
        });
      } else {
        // User is not signed in
        Fluttertoast.showToast(
          msg: 'You need to sign in to upload images.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (error) {
      Fluttertoast.showToast(
        msg: 'Failed to upload image: $error',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }

    setState(() {
      _isUploading = false;
    });
  }

  // Method to show the edit dialog
  void _showEditDialog(DocumentSnapshot document) {
    TextEditingController titleController = TextEditingController(text: document['title']);
    TextEditingController descriptionController = TextEditingController(text: document['description']);
    bool isPublic = document['isPublic'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                ),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                ),
              ),

            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('images').doc(document.id).update({
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'isPublic': isPublic,
                  });
                  Fluttertoast.showToast(
                    msg: 'Post updated successfully.',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );
                  Navigator.of(context).pop();
                } catch (error) {
                  Fluttertoast.showToast(
                    msg: 'Failed to update post: $error',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Image'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: _getImage,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_upload),
                        SizedBox(width: 8.0),
                        Text(
                          'Select Image',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              _image != null
                  ? Image.file(
                _image!,
                height: 200.0,
              )
                  : Container(),
              SizedBox(height: 20.0),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.0),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.0),
              Row(
                children: [
                  Icon(Icons.visibility),
                  Text(' Public'),
                  Switch(
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Upload'),
              ),
              SizedBox(height: 20.0),
              if (_isUploading) ...[
                LinearProgressIndicator(),
                SizedBox(height: 10.0),
              ],
              SizedBox(height: 20.0),
              StreamBuilder(
                stream: FirebaseFirestore.instance.collection('images').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: Text('No data available'),
                    );
                  }

                  // Filter documents based on visibility and user
                  List<DocumentSnapshot> documents = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    var currentUser = FirebaseAuth.instance.currentUser;
                    if (_isPublic) {
                      // Show public posts by current user
                      return data['isPublic'] == true && data['userId'] == currentUser?.uid;
                    } else {
                      // Show private posts by current user
                      return data['isPublic'] == false && data['userId'] == currentUser?.uid;
                    }
                  }).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> data = documents[index].data() as Map<String, dynamic>;

                      String title = data['title'];
                      String description = data['description'];

                      // Truncate title and description if they are longer than the specified limits
                      if (title.length > 20) {
                        title = title.substring(0, 25) + '...';
                      }
                      if (description.length > 15) {
                        description = description.substring(0, 15) + '...';
                      }

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              Container(
                                width: 100.0,
                                height: 100.0,
                                child: Image.network(
                                  data['imageUrl'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 10.0),
                              // Title and Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 5.0),
                                    Text(
                                      description,
                                      style: TextStyle(fontSize: 12.0),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10.0),
                              // Edit and Delete icons
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      _showEditDialog(documents[index]);
                                    },
                                    iconSize: 24,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () async {
                                      // Show an alert dialog to confirm deletion
                                      bool confirmDelete = await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Confirm Deletion'),
                                          content: Text('Are you sure you want to delete this post?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(false); // Return false indicating cancellation
                                              },
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(true); // Return true indicating confirmation
                                              },
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      // Check user's choice
                                      if (confirmDelete == true) {
                                        // Proceed with deletion
                                        String documentId = documents[index].id;
                                        try {
                                          await FirebaseFirestore.instance.collection('images').doc(documentId).delete();
                                          // Remove the deleted post from UI
                                          setState(() {
                                            documents.removeAt(index);
                                          });
                                          Fluttertoast.showToast(
                                            msg: 'Post deleted successfully.',
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.BOTTOM,
                                            backgroundColor: Colors.green,
                                            textColor: Colors.white,
                                          );
                                        } catch (error) {
                                          Fluttertoast.showToast(
                                            msg: 'Failed to delete post: $error',
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.BOTTOM,
                                            backgroundColor: Colors.red,
                                            textColor: Colors.white,
                                          );
                                        }
                                      }
                                    },
                                    iconSize: 24,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
