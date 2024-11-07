import 'package:flutter/material.dart';
import 'package:Learnbound/database/auth_service.dart';
import 'auth_screen.dart'; // Import your AuthScreen here
import 'dart:io'; // Ensure you import this for File usage

class ProfileSettingsScreen extends StatefulWidget {

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final AuthService _authService = AuthService();
  String? _profilePicturePath;
  

 
  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  void _loadProfilePicture() {
    setState(() {
      _profilePicturePath = _authService.profilePicturePath;
    });
  }

  void _changeProfilePicture() async {
  
    await _authService.changeProfilePicture(1);//test
    _loadProfilePicture();
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController _currentPasswordController = TextEditingController();
    final TextEditingController _newPasswordController = TextEditingController();
     
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                decoration: InputDecoration(labelText: 'Current Password'),
                obscureText: true,
              ),
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _authService.changePassword(
                    _currentPasswordController.text,
                    _newPasswordController.text,
                  );
                  Navigator.of(context).pop(); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password changed successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text('Change'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
      ),
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD3A97D).withOpacity(1), // Start color
              Color(0xFFEBE1C8).withOpacity(1), // End color
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        
        child: ListView(
          children: [
            Padding(
  padding: EdgeInsets.symmetric(vertical: 15.0), // Adjust the padding as needed
  child: GestureDetector(
    onTap: _changeProfilePicture,
    child: CircleAvatar(
      radius: 50,
      backgroundImage: _profilePicturePath != null
          ? FileImage(File(_profilePicturePath!))
          : AssetImage('assets/defaultprofile.png') as ImageProvider,
      child: _profilePicturePath == null
          ? Icon(Icons.camera_alt, size: 30, color: Colors.grey)
          : null,
    ),
  ),
),



            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Change Password'),
              onTap: () {
                _showChangePasswordDialog(context);
              },
            ),
           
             ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
