import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/widgets/loading.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.user,
  });
  final AppUser user;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final experienceYearsController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final carMakeController = TextEditingController();
  final carModelController = TextEditingController();
  final carYearController = TextEditingController();
  final editKey = GlobalKey<FormState>();
  final scroller = ScrollController();

  List<String> transmissionTypes = ['Automatic', 'Manual'];
  File? profileImage;
  File? carImage;
  String? selectedTransmission;
  String? imageURL;
  String? carURL;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    firstNameController.text = widget.user.firstName!;
    lastNameController.text = widget.user.lastName!;
    if (widget.user.type! == 'Instructor') {
      experienceYearsController.text = widget.user.experienceYears.toString();
      phoneNumberController.text = widget.user.phoneNumber!;
      carMakeController.text = widget.user.carMake!;
      carModelController.text = widget.user.carModel!;
      carYearController.text = widget.user.carYear.toString();
      selectedTransmission = widget.user.transmissionType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onPanDown: (_) => FocusScope.of(context).unfocus(),
      child: isSaving
          ? const Loading()
          : Scaffold(
              appBar: AppBar(
                title: const Text('Edit Profile'),
                centerTitle: true,
              ),
              body: Scrollbar(
                thumbVisibility: true,
                controller: scroller,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            controller: scroller,
                            shrinkWrap: true,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info,
                                    color: Colors.grey[700],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Profile Info',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              profileImageStack(),
                              const SizedBox(height: 20),
                              Form(
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                key: editKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: firstNameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.perm_identity),
                                        labelText: 'First Name',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'First name cannot be empty.';
                                        } else if (value
                                            .contains(RegExp(r'[0-9]'))) {
                                          return 'First name cannot contain numbers.';
                                        } else if (value.length > 35) {
                                          return 'First name is too long.';
                                        } else {
                                          return null;
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: lastNameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.perm_identity),
                                        labelText: 'Last Name',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Last name cannot be empty.';
                                        } else if (value
                                            .contains(RegExp(r'[0-9]'))) {
                                          return 'Last name cannot contain numbers.';
                                        } else if (value.length > 35) {
                                          return 'Last name is too long.';
                                        } else {
                                          return null;
                                        }
                                      },
                                    ),
                                    if (widget.user.type == 'Instructor')
                                      instructorExtra(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            minimumSize: const Size.fromHeight(40),
                          ),
                          onPressed: () {
                            if (editKey.currentState!.validate()) {
                              finishEditing();
                            }
                          },
                          child: const Text('SAVE CHANGES'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future pickImage(ImageSource source, String whichPic) async {
    try {
      final image =
          await ImagePicker().pickImage(source: source, imageQuality: 60);
      if (image == null) return Utils.ShowErrorBar('No image selected.');
      setState(() {
        if (whichPic == 'profile') {
          profileImage = File(image.path);
        } else {
          carImage = File(image.path);
        }
      });
    } on PlatformException catch (_) {
      Utils.ShowErrorBar('Failed to get image...');
    }
  }

  Widget instructorExtra() => Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(height: 20),
          //experience years
          TextFormField(
            controller: experienceYearsController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.military_tech),
              labelText: 'Experience Years',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Experience years cannot be empty.';
              } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'Experience years must be in digit numbers.';
              } else if (value.length > 2) {
                return 'That number is unrealisitic.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          //phone number
          TextFormField(
            controller: phoneNumberController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone),
              labelText: 'Phone Number',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number cannot be empty.';
              } else if (!value.contains(RegExp(r'[0-9]'))) {
                return 'Phone number must contain digit numbers.';
              } else if (value.length < 8) {
                return 'Phone number must be atleast 8 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info,
                color: Colors.grey[700],
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                'Vehicle Info',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          carImageStack(),
          const SizedBox(height: 20),
          //car make
          TextFormField(
            controller: carMakeController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.directions_car),
              labelText: 'Car Make',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Car make cannot be empty.';
              } else if (value.contains(RegExp(r'[0-9]'))) {
                return 'Car make cannot contain numbers.';
              } else if (value.length > 35) {
                return 'Car make is too long.';
              } else {
                return null;
              }
            },
          ),
          const SizedBox(height: 20),
          //car model
          TextFormField(
            controller: carModelController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.directions_car),
              labelText: 'Car Model',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Car model cannot be empty.';
              } else if (value.contains(RegExp(r'[0-9]'))) {
                return 'Car model cannot contain numbers.';
              } else if (value.length > 35) {
                return 'Car model is too long.';
              } else {
                return null;
              }
            },
          ),
          const SizedBox(height: 20),
          //car year
          TextFormField(
            controller: carYearController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.directions_car),
              labelText: 'Car Year',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Car year cannot be empty.';
              } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'Car year must be in digit numbers.';
              } else if (value.length > 4) {
                return 'That number is unrealisitic.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          //transmission type
          DropdownButtonFormField(
            value: selectedTransmission,
            items: transmissionTypes
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: (item) => setState(() {
              selectedTransmission = item;
            }),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.settings),
              labelText: 'Transmission Type',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Transmission type cannot be empty.';
              }
              return null;
            },
          ),
        ],
      );

  Widget profileImageStack() {
    return Center(
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            width: 150,
            height: 150,
            child: Card(
              elevation: 3,
              shape: const CircleBorder(),
              child: Container(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: profileImage != null
                        ? Image.file(profileImage!).image
                        : widget.user.imageURL == null
                            ? Image.asset('assets/guest.png').image
                            : Image.network(widget.user.imageURL!).image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 105,
            left: 90,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Wrap(
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey[600],
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.all(20),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.gallery, 'profile');
                                  },
                                  label: const Text('Gallery'),
                                  icon: const Icon(Icons.image),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey[600],
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.all(20),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.camera, 'profile');
                                  },
                                  label: const Text('Camera'),
                                  icon: const Icon(Icons.camera_alt),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.upload),
            ),
          ),
        ],
      ),
    );
  }

  Widget carImageStack() {
    return Center(
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            width: 300,
            height: 150,
            child: Card(
              elevation: 3,
              child: Container(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  image: DecorationImage(
                    image: carImage != null
                        ? Image.file(carImage!).image
                        : widget.user.carURL == null
                            ? Image.asset('assets/car.jpg').image
                            : Image.network(widget.user.carURL!).image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 105,
            left: 250,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Wrap(
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey[600],
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.all(20),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.gallery, '');
                                  },
                                  label: const Text('Gallery'),
                                  icon: const Icon(Icons.image),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey[600],
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.all(20),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    pickImage(ImageSource.camera, '');
                                  },
                                  label: const Text('Camera'),
                                  icon: const Icon(Icons.camera_alt),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.upload),
            ),
          ),
        ],
      ),
    );
  }

  Future addUserData() async {
    final userID = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);

    //adding data to user
    AppUser.currentUser!.firstName = firstNameController.text;
    AppUser.currentUser!.lastName = lastNameController.text;
    AppUser.currentUser!.imageURL = imageURL ?? AppUser.currentUser!.imageURL;
    if (AppUser.currentUser!.type == 'Instructor') {
      AppUser.currentUser!.experienceYears =
          int.parse(experienceYearsController.text);
      AppUser.currentUser!.phoneNumber = phoneNumberController.text;
      AppUser.currentUser!.carMake = carMakeController.text;
      AppUser.currentUser!.carModel = carModelController.text;
      AppUser.currentUser!.carYear = int.parse(carYearController.text);
      AppUser.currentUser!.transmissionType = selectedTransmission;
      AppUser.currentUser!.carURL = carURL ?? AppUser.currentUser!.carURL;
    }

    final json = AppUser.currentUser!.toJson();
    await userDoc.set(json);
  }

  Future finishEditing() async {
    try {
      setState(() {
        isSaving = true;
      });
      //check if images not null to upload them
      if (profileImage != null) {
        await uploadImage(profileImage!.path, 'profile');
      }
      if (carImage != null) {
        await uploadImage(carImage!.path, 'car');
      }
      //save data
      await addUserData();
      //display success
      Utils.ShowSuccessBar('Profile updated successfully.');
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      Utils.ShowErrorBar(e.message);
      debugPrint(e.message);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future uploadImage(String filePath, String fileName) async {
    final storage = FirebaseStorage.instance;
    File file = File(filePath);
    final upload = await storage
        .ref(
            'images/${FirebaseAuth.instance.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}')
        .putFile(file);
    if (fileName == 'profile') {
      imageURL = await upload.ref.getDownloadURL();
    } else if (fileName == 'car') {
      carURL = await upload.ref.getDownloadURL();
    }
  }
}
