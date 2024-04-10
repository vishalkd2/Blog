import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _profilePicturePath;
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Registration',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegistrationForm(
                nameController: _nameController,
                emailController: _emailController,
                numberController: _numberController,
                passwordController: _passwordController,
                profilePicturePath: _profilePicturePath,
              ),
              SizedBox(height: 20),
              SelectProfilePictureButton(onProfilePictureSelected: (imagePath) {
                setState(() {
                  _profilePicturePath = imagePath;
                });
              }),
              SizedBox(height: 20),
              RegisterButton(
                nameController: _nameController,
                emailController: _emailController,
                numberController: _numberController,
                passwordController: _passwordController,
                profilePicturePath: _profilePicturePath,
                onRegister: () {
                  setState(() {
                    _isRegistering = true;
                  });
                },
                onComplete: () {
                  setState(() {
                    _isRegistering = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Registration Successful'),
                    ),
                  );
                  // Clear input fields after successful registration
                  _nameController.clear();
                  _emailController.clear();
                  _numberController.clear();
                  _passwordController.clear();
                },
              ),
              SizedBox(height: 10),
              if (_isRegistering) LinearProgressIndicator(), // Show linear progress bar if registering
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController numberController;
  final TextEditingController passwordController;
  final String? profilePicturePath;

  RegistrationForm({
    required this.nameController,
    required this.emailController,
    required this.numberController,
    required this.passwordController,
    this.profilePicturePath,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: 20.0),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your email';
              }
              return null;
            },
          ),
          SizedBox(height: 20.0),
          TextFormField(
            controller: numberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          SizedBox(height: 20.0),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a password';
              }
              return null;
            },
          ),
          SizedBox(height: 20.0),
          if (profilePicturePath != null)
            Text(
              'Selected Profile Picture: $profilePicturePath',
              style: TextStyle(fontSize: 16),
            ),
          SizedBox(height: 30.0),
        ],
      ),
    );
  }
}

class SelectProfilePictureButton extends StatelessWidget {
  final Function(String) onProfilePictureSelected;

  SelectProfilePictureButton({required this.onProfilePictureSelected});

  Future<void> _selectProfilePicture(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      onProfilePictureSelected(pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _selectProfilePicture(context),
      icon: Icon(Icons.camera_alt),
      label: Text(
        'Select Profile Picture',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
        foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(vertical: 15),
        ),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class RegisterButton extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController numberController;
  final TextEditingController passwordController;
  final String? profilePicturePath;
  final VoidCallback onRegister;
  final VoidCallback onComplete;

  RegisterButton({
    required this.nameController,
    required this.emailController,
    required this.numberController,
    required this.passwordController,
    this.profilePicturePath,
    required this.onRegister,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        onRegister(); // Callback to indicate registration process started

        String name = nameController.text;
        String email = emailController.text;
        String phoneNumber = numberController.text;
        String password = passwordController.text;

        if (name.isEmpty || email.isEmpty || phoneNumber.isEmpty || password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please fill all fields'),
            ),
          );
          return;
        }

        try {
          // Create user with email and password using Firebase Authentication
          UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Upload profile picture to Firebase Storage
          String? profilePictureUrl;
          if (profilePicturePath != null) {
            Reference ref = FirebaseStorage.instance.ref().child("profilePictures/${userCredential.user!.uid}.jpg");
            UploadTask uploadTask = ref.putFile(File(profilePicturePath!));
            TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
            profilePictureUrl = await snapshot.ref.getDownloadURL();
          }

          // Store user information in Firestore
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'name': name,
            'email': email,
            'phone_number': phoneNumber,
            'password': password,
            'profile_picture': profilePictureUrl,
          });

          onComplete(); // Callback to indicate registration process completed

          // Clear input fields
          nameController.clear();
          emailController.clear();
          numberController.clear();
          passwordController.clear();
        } catch (error) {
          print('Error registering user: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error registering user. Please try again.'),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        padding: EdgeInsets.symmetric(vertical: 15.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        'Register',
        style: TextStyle(
          fontSize: 16.0,
          color: Colors.white,
        ),
      ),
    );
  }
}
