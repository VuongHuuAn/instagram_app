import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/resources/auth_methods.dart';
import 'package:instagram_clone/resources/firestore_methods.dart';
import 'package:instagram_clone/screens/edit_profile_screen.dart';
import 'package:instagram_clone/screens/login_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:instagram_clone/widgets/follow_button.dart';
import 'package:provider/provider.dart';
import 'package:instagram_clone/providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> refreshData() async {
    await Provider.of<UserProvider>(context, listen: false).refreshUser();
    await getData();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.uid)
          .get();
      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();
      postLen = postSnap.docs.length;

      if (userSnap.data() != null) {
        userData = userSnap.data()!;

        if (userData['followers'] != null && userData['followers'] is List) {
          followers = (userData['followers'] as List).length;
        } else {
          followers = 0;
        }
        if (userData['following'] != null && userData['following'] is List) {
          following = (userData['following'] as List).length;
        } else {
          following = 0;
        }
      }
      isFollowing = userSnap
          .data()!['followers']
          .contains(FirebaseAuth.instance.currentUser!.uid);

      setState(() {});
    } catch (e) {
      showSnackBar(e.toString(), context);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              title: Text(userData['username']),
              centerTitle: false,
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'signout') {
                      AuthMethods().signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'signout',
                        child: Text('Sign Out'),
                      ),
                    ];
                  },
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: refreshData,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey,
                              backgroundImage: NetworkImage(userData['photoUrl']),
                              radius: 40,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      buildStatColumn(postLen, "posts"),
                                      buildStatColumn(followers, "followers"),
                                      buildStatColumn(following, "following"),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: FirebaseAuth.instance
                                                      .currentUser!.uid ==
                                                  widget.uid
                                              ? FollowButton(
                                                  text: 'Edit Profile',
                                                  backgroundColor:
                                                      mobileBackgroundColor,
                                                  textColor: primaryColor,
                                                  borderColor: Colors.grey,
                                                  function: () async {
                                                    DocumentSnapshot userDoc =
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection('user')
                                                            .doc(widget.uid)
                                                            .get();

                                                    await Navigator.of(context)
                                                        .push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            EditProfileScreen(
                                                          userData: userDoc
                                                              as DocumentSnapshot<
                                                                  Map<String,
                                                                      dynamic>>,
                                                        ),
                                                      ),
                                                    );
                                                    refreshData();
                                                  },
                                                )
                                              : Row(
                                                  children: [
                                                    Expanded(
                                                      child: isFollowing
                                                          ? FollowButton(
                                                              text: 'Unfollow',
                                                              backgroundColor:
                                                                  Colors.white,
                                                              textColor:
                                                                  Colors.black,
                                                              borderColor:
                                                                  Colors.grey,
                                                              function: () async {
                                                                await FirestoreMethods()
                                                                    .followUser(
                                                                  FirebaseAuth
                                                                      .instance
                                                                      .currentUser!
                                                                      .uid,
                                                                  userData['uid'],
                                                                );
                                                                setState(() {
                                                                  isFollowing =
                                                                      false;
                                                                  followers--;
                                                                });
                                                              },
                                                            )
                                                          : FollowButton(
                                                              text: 'Follow',
                                                              backgroundColor:
                                                                  Colors.blue,
                                                              textColor:
                                                                  Colors.white,
                                                              borderColor:
                                                                  Colors.blue,
                                                              function: () async {
                                                                await FirestoreMethods()
                                                                    .followUser(
                                                                  FirebaseAuth
                                                                      .instance
                                                                      .currentUser!
                                                                      .uid,
                                                                  userData['uid'],
                                                                );
                                                                setState(() {
                                                                  isFollowing =
                                                                      true;
                                                                  followers++;
                                                                });
                                                              },
                                                            ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: FollowButton(
                                                        text: 'My Profile',
                                                        backgroundColor:
                                                            mobileBackgroundColor,
                                                        textColor: primaryColor,
                                                        borderColor: Colors.grey,
                                                        function: () {
                                                          Navigator.of(context)
                                                              .pushReplacement(
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  ProfileScreen(
                                                                uid: FirebaseAuth
                                                                    .instance
                                                                    .currentUser!
                                                                    .uid,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            userData['username'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            userData['bio'] ?? '',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('posts')
                        .where('uid', isEqualTo: widget.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        itemCount: (snapshot.data! as dynamic).docs.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 1.5,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          DocumentSnapshot snap =
                              (snapshot.data! as dynamic).docs[index];
                          return Container(
                            child: Image(
                              image: NetworkImage(snap['postUrl']),
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      );
                    },
                  )
                ],
              ),
            ),
          );
  }
}

Column buildStatColumn(int num, String label) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        num.toString(),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      Container(
        margin: const EdgeInsets.only(top: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
      ),
    ],
  );
}