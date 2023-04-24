import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/firestore.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/profile/profile_page.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/widgets/star_rating_average.dart';

class TraineeInstructorSearch extends StatefulWidget {
  const TraineeInstructorSearch({super.key});

  @override
  State<TraineeInstructorSearch> createState() =>
      _TraineeInstructorSearchState();
}

class _TraineeInstructorSearchState extends State<TraineeInstructorSearch> {
  final searchController = TextEditingController();
  String name = '';
  String gender = '';
  String city = '';
  String sort = '';
  String? selectedGender;
  String? selectedCity;
  String? selectedSort;

  List<String> genders = ['Male', 'Female'];
  List<String> cities = [
    'Aali',
    'Al Hajar',
    'Al Hidd',
    'Al Jasra',
    'Al Kharijiya',
    'Al Malikiyah',
    'Al Maqsha',
    'Al Qadam',
    'Al Qalah',
    'Al Qaryah',
    'AlJuffair',
    'Arad',
    'Awali',
    'Bu Quwah',
    'Budiya',
    'Dar Kulaib',
    'Diplomatic Area',
    'Galali',
    'Ghuraifa',
    'Hamad Town',
    'Isa Town',
    'Jid Ali',
    'Jidhafs',
    'Jurdab',
    'Karbabad',
    'Karranah',
    'Ma\'ameer',
    'Mahazza',
    'Manama',
    'Muharraq',
    'Murqoban',
    'Nothern City',
    'Riffa',
    'Saar',
    'Salmabad',
    'Samaheej',
    'Sanabis',
    'Sanad',
    'Tubli',
    'Umm Al Hassam',
    'Wadiyan',
    'Zinj',
  ];
  List<String> sorts = ['Highest Rating', 'Most Reviewed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(left: 20, right: 20, bottom: 10, top: 10),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search Instructor...',
                        border: InputBorder.none,
                        suffixIcon: name.isNotEmpty
                            ? IconButton(
                                onPressed: () => setState(() {
                                  searchController.clear();
                                  name = '';
                                }),
                                icon: const Icon(Icons.cancel, size: 18),
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          name = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Card(
                  margin: EdgeInsets.zero,
                  color: Colors.red,
                  child: IconButton(
                    icon: Icon(
                      city.isNotEmpty || gender.isNotEmpty || sort.isNotEmpty
                          ? Icons.filter_list_off
                          : Icons.filter_list,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => searchFilter(),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FirestoreQueryBuilder(
              query: getQuery(),
              builder: (context, snapshot, _) {
                if (snapshot.isFetching) {
                  return const Loading(color: Colors.white10);
                } else if (snapshot.hasError) {
                  return Text('error ${snapshot.error}');
                } else if (snapshot.docs.isEmpty) {
                  return const Center(child: Text('No results'));
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.docs.length,
                    itemBuilder: (context, index) {
                      if (snapshot.hasMore &&
                          index + 1 == snapshot.docs.length) {
                        snapshot.fetchMore();
                      }
                      final user = snapshot.docs[index].data();
                      return buildUser(user);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Query<AppUser> getQuery() {
    CollectionReference collection =
        FirebaseFirestore.instance.collection('users');
    var query = collection.where('type', isEqualTo: 'Instructor');
    if (gender.isNotEmpty) {
      query = query.where('gender', isEqualTo: gender);
    }
    if (city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }
    if (sort.isNotEmpty) {
      if (sort == 'Highest Rating') {
        query = query.orderBy('ratingAverage', descending: true);
      } else if (sort == 'Most Reviewed') {
        query = query.orderBy('ratingCount', descending: true);
      }
    }
    return query.withConverter(
      fromFirestore: (snapshot, _) => AppUser.fromJson(snapshot.data()!),
      toFirestore: (user, _) => user.toJson(),
    );
  }

  Widget buildUser(AppUser user) {
    if (name.isNotEmpty) {
      if (!user.fullName()!.toLowerCase().contains(name.toLowerCase())) {
        return Container();
      }
    }
    return Card(
      margin: const EdgeInsets.only(right: 10, left: 10, top: 5, bottom: 5),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(7),
        leading: CircleAvatar(
          child: ClipOval(
            child: user.imageURL != null
                ? Image.network(
                    user.imageURL!,
                    fit: BoxFit.cover,
                    width: 90,
                    height: 90,
                  )
                : Image.asset(
                    'assets/guest.png',
                    fit: BoxFit.cover,
                    width: 90,
                    height: 90,
                  ),
          ),
        ),
        title: Text(user.fullName()!),
        trailing: Column(
          children: const [
            Expanded(child: Icon(Icons.arrow_forward_ios)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StarRatingAverage(avg: user.ratingAverage!.toDouble()),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey[700]),
                children: [
                  const WidgetSpan(
                    child: Icon(Icons.location_on, size: 15),
                  ),
                  TextSpan(text: " ${user.city!}"),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey[700]),
                children: [
                  const WidgetSpan(
                    child: Icon(Icons.directions_car, size: 15),
                  ),
                  TextSpan(
                    text:
                        " ${user.carMake!} | ${user.carModel!} | ${user.carYear!}",
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(user: user),
          ),
        ),
      ),
    );
  }

  Widget searchFilter() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StatefulBuilder(
            builder: (BuildContext context, setState) {
              return AlertDialog(
                title: const Text('Search Filter'),
                content: Column(
                  children: [
                    DropdownButtonFormField(
                      value: selectedGender,
                      items: genders
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      onChanged: (item) => setState(() {
                        selectedGender = item;
                        gender = selectedGender!;
                      }),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.wc),
                        labelText: 'Gender',
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField(
                      value: selectedCity,
                      items: cities
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      onChanged: (item) => setState(() {
                        selectedCity = item;
                        city = selectedCity!;
                      }),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_city),
                        labelText: 'City',
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField(
                      value: selectedSort,
                      items: sorts
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      onChanged: (item) => setState(() {
                        selectedSort = item;
                        sort = selectedSort!;
                      }),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.sort),
                        labelText: 'Sort By',
                      ),
                    ),
                  ],
                ),
                actions: [
                  OutlinedButton(
                    onPressed:
                        city.isNotEmpty || gender.isNotEmpty || sort.isNotEmpty
                            ? () => setState(() {
                                  city = '';
                                  gender = '';
                                  sort = '';
                                  selectedCity = null;
                                  selectedGender = null;
                                  selectedSort = null;
                                  FocusScope.of(context).unfocus();
                                })
                            : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('CLEAR'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('DONE'),
                  ),
                ],
                elevation: 5,
                actionsAlignment: MainAxisAlignment.center,
                contentTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                actionsPadding: const EdgeInsets.all(30),
              );
            },
          ),
        ],
      );
}
