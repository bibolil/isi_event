import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isi_event/features/user_auth/presentation/pages/login_page.dart';
import 'package:isi_event/features/user_auth/user/sharedpreferences.dart';
import 'eventaddpage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SharedPrefService sharedPrefService = SharedPrefService();
  String? currentUserRole;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndUserId();
  }

  Future<void> _loadUserRoleAndUserId() async {
    currentUserRole = await sharedPrefService.readCache(key: 'role');
    userId = await sharedPrefService.readCache(key: 'userId');
    setState(() {});
  }

  Future<void> _logout() async {
    await sharedPrefService.removeCache();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _deleteEvent(String docId) async {
    await FirebaseFirestore.instance.collection('events').doc(docId).delete();
  }

  Future<void> _showConfirmationDialog(
      BuildContext context, String docId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this event?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _deleteEvent(docId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _subscribeToCategory(String category) async {
    if (userId == null) return;
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw Exception("User does not exist!");
      }

      Map<String, dynamic>? userData = snapshot.data() as Map<String, dynamic>?;
      List<dynamic> subscribed =
          List.from(userData?['subscribedCategories'] ?? []);

      if (!subscribed.contains(category)) {
        subscribed.add(category);

        transaction.update(userRef, {'subscribedCategories': subscribed});
      }
    }).then((value) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Subscribed to $category!')));
    }).catchError((error) {
      print("Failed to subscribe: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HomePage"),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('category')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                Map<String, List<DocumentSnapshot>> groupedEvents = {};
                for (DocumentSnapshot doc in snapshot.data!.docs) {
                  String category = doc['category'];
                  if (!groupedEvents.containsKey(category)) {
                    groupedEvents[category] = [];
                  }
                  groupedEvents[category]?.add(doc);
                }

                return ListView(
                  children: groupedEvents.entries.map((entry) {
                    return ExpansionTile(
                      title: Text(entry.key),
                      children: [
                        ...entry.value
                            .map((doc) => ListTile(
                                  title: Text(doc['title']),
                                  subtitle: Text(doc['description']),
                                  trailing: currentUserRole == 'ADMIN'
                                      ? IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () =>
                                              _showConfirmationDialog(
                                                  context, doc.id),
                                        )
                                      : null,
                                ))
                            .toList(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 8.0),
                          child: ElevatedButton(
                            onPressed: () => _subscribeToCategory(entry.key),
                            child: Text('Subscribe to ${entry.key}'),
                          ),
                        )
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
          if (currentUserRole == 'ADMIN')
            Padding(
              padding: EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EventAddPage()),
                  );
                },
                child: Text('Add Event'),
              ),
            ),
        ],
      ),
    );
  }
}
