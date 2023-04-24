import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seyaqti_app/shared_import.dart';
import 'package:seyaqti_app/auth/login_widget.dart';
import 'package:seyaqti_app/main.dart';
import 'package:seyaqti_app/widgets/loading.dart';
import 'package:seyaqti_app/widgets/location_picker.dart';

class RegisterWidget extends StatefulWidget {
  const RegisterWidget({super.key});

  @override
  State<RegisterWidget> createState() => _RegisterWidgetState();
}

class _RegisterWidgetState extends State<RegisterWidget> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final dateController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mapLocationController = TextEditingController();
  final picker = LocationPicker();
  final experienceYearsController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final carMakeController = TextEditingController();
  final carModelController = TextEditingController();
  final carYearController = TextEditingController();
  final previousHoursController = TextEditingController();
  final hourForm = GlobalKey<FormState>();

  DateTime dateOfBirth = DateTime.now();
  List<GlobalKey<FormState>> formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
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
  List<String> transmissionTypes = ['Automatic', 'Manual'];
  int currentStep = 0;
  bool loading = false;
  String? accountType;
  String? selectedGender;
  String? selectedCity;
  String? selectedTransmission;
  int? previousHours;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (_) {
        FocusScope.of(context).unfocus();
      },
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: loading
          ? const Loading()
          : Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (accountType == null) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        accountType = null;
                        previousHours = null;
                      });
                    }
                  },
                ),
                title: Text(
                    accountType == null ? 'Register' : '$accountType Register'),
                centerTitle: true,
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginWidget(),
                          ));
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.person, color: Colors.white),
                        SizedBox(width: 5),
                        Text('Login', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  )
                ],
              ),
              body: accountType == null
                  ? alert()
                  : accountType == 'Trainee' && previousHours == null
                      ? traineeHourAlert()
                      : Stepper(
                          type: StepperType.horizontal,
                          controlsBuilder: (context, controls) {
                            int lastStep;
                            accountType == 'Instructor'
                                ? lastStep = getSteps().length - 1
                                : lastStep = getStepsWithoutLast().length - 1;
                            return Column(
                              children: [
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: controls.onStepContinue,
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                        ),
                                        child: Text((currentStep != lastStep)
                                            ? 'NEXT'
                                            : 'CONFIRM'),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    if (currentStep != 0)
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: controls.onStepCancel,
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: const Text('BACK'),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                          steps: accountType == 'Instructor'
                              ? getSteps()
                              : getStepsWithoutLast(),
                          currentStep: currentStep,
                          onStepTapped: (step) {
                            if (step >= currentStep) {
                              for (var i = 0; i < step; i++) {
                                if (!formKeys[i].currentState!.validate()) {
                                  return;
                                }
                              }
                            }
                            setState(() => currentStep = step);
                          },
                          onStepContinue: () {
                            int lastStep;
                            accountType == 'Instructor'
                                ? lastStep = getSteps().length - 1
                                : lastStep = getStepsWithoutLast().length - 1;
                            setState(() {
                              if (formKeys[currentStep]
                                  .currentState!
                                  .validate()) {
                                if (currentStep < lastStep) {
                                  currentStep += 1;
                                }
                                //completed
                                else {
                                  register();
                                }
                              }
                            });
                          },
                          onStepCancel: () {
                            setState(() {
                              if (currentStep != 0) currentStep -= 1;
                            });
                          },
                        ),
            ),
    );
  }

  List<Step> getSteps() => [
        Step(
          isActive: currentStep >= 0,
          title: const Text('Account'),
          content: SingleChildScrollView(
            child: Form(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              key: formKeys[0],
              child: Column(
                children: [
                  TextFormField(
                    controller: emailController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: 'Email',
                    ),
                    validator: (value) {
                      if (value != null && !EmailValidator.validate(value)) {
                        return 'Enter a valid email.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value != null && value.length < 8) {
                        return 'Enter atleast 8 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: confirmPasswordController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (passwordController.text !=
                          confirmPasswordController.text) {
                        return "Passwords don't match.";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Step(
          isActive: currentStep >= 1,
          title: const Text('Personal'),
          content: SingleChildScrollView(
            child: Form(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              key: formKeys[1],
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
                      } else if (value.contains(RegExp(r'[0-9]'))) {
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
                      } else if (value.contains(RegExp(r'[0-9]'))) {
                        return 'Last name cannot contain numbers.';
                      } else if (value.length > 35) {
                        return 'Last name is too long.';
                      } else {
                        return null;
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    readOnly: true,
                    controller: dateController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today),
                      labelText: 'Date of Birth',
                    ),
                    onTap: () async {
                      DateTime now = DateTime.now();
                      DateTime? pickDate = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime(now.year - 18, now.month, now.day),
                        firstDate: DateTime(DateTime.now().year - 100),
                        lastDate: DateTime(DateTime.now().year - 17),
                      );
                      if (pickDate != null) {
                        dateController.text =
                            DateFormat('MM/dd/yyyy').format(pickDate);
                      }
                    },
                    validator: (value) {
                      try {
                        DateTime pickDate =
                            DateFormat('MM/dd/yyyy').parse(dateController.text);
                        if (pickDate.difference(DateTime.now()).inDays.abs() ~/
                                365 <
                            18) {
                          return 'You need to be atleast 18 years old.';
                        }
                      } catch (e) {
                        return 'This field is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
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
                    }),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.wc),
                      labelText: 'Gender',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Your gender cannot be empty.';
                      }
                      return null;
                    },
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
                    }),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_city),
                      labelText: 'City',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Your city cannot be empty.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    readOnly: true,
                    controller: mapLocationController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.gps_fixed),
                      labelText: 'Google Maps Location',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => picker,
                        ),
                      ).then((_) {
                        if (picker.selectedMarker != null) {
                          mapLocationController.text =
                              "Latitude: ${picker.selectedMarker?.position.latitude.toStringAsFixed(3)}, Longitude: ${picker.selectedMarker?.position.longitude.toStringAsFixed(3)}";
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Your map location is needed.';
                      } else {
                        return null;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Step(
          isActive: currentStep >= 2,
          title: const Text('Work'),
          content: SingleChildScrollView(
            child: Form(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              key: formKeys[2],
              child: Column(
                children: [
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
              ),
            ),
          ),
        ),
      ];

  List<Step> getStepsWithoutLast() {
    List<Step> steps = getSteps();
    steps.removeLast();
    return steps;
  }

  Future register() async {
    try {
      setState(() => loading = true);
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      //add user data
      await addUserData();
      //remove loading page
      navigatorKey.currentState!.popUntil((route) => route.isFirst);
    } on FirebaseException catch (e) {
      setState(() {
        Utils.ShowErrorBar("Error: ${e.message}");
        loading = false;
      });
    }
  }

  Future addUserData() async {
    final userID = FirebaseAuth.instance.currentUser?.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    //adding data to user
    final user = AppUser(
      id: userID,
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      gender: selectedGender!,
      birthday: DateFormat('MM/dd/yyyy').parse(dateController.text),
      type: accountType!,
      city: selectedCity!,
      mapLatitude: picker.selectedMarker!.position.latitude,
      mapLongitude: picker.selectedMarker!.position.longitude,
      experienceYears: experienceYearsController.text.isEmpty
          ? null
          : int.parse(experienceYearsController.text),
      phoneNumber: phoneNumberController.text.isEmpty
          ? null
          : phoneNumberController.text,
      carMake: carMakeController.text.isEmpty ? null : carMakeController.text,
      carModel:
          carModelController.text.isEmpty ? null : carModelController.text,
      carYear: carYearController.text.isEmpty
          ? null
          : int.parse(carYearController.text),
      transmissionType: selectedTransmission,
      ratingAverage: 0,
      ratingCount: 0,
    );
    final json = user.toJson();
    try {
      await userDoc.set(json);
      if (previousHours != null) {
        await userDoc
            .collection('hours')
            .doc(userID)
            .set({'hours': previousHours});
      }
    } on FirebaseException catch (_) {
      debugPrint(_.message);
    }
  }

  Column alert() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AlertDialog(
          title: const Center(child: Loading()),
          content: const Text(
            'Are you registering as a Driving Instructor or a Trainee?',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => setState(() => accountType = 'Trainee'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('TRAINEE'),
            ),
            ElevatedButton(
              onPressed: () => setState(() => accountType = 'Instructor'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('DRIVING INSTRUCTOR'),
            ),
          ],
          elevation: 5,
          actionsAlignment: MainAxisAlignment.center,
          contentTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          actionsPadding: const EdgeInsets.all(30),
        ),
      ],
    );
  }

  Column traineeHourAlert() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AlertDialog(
          title: const Center(child: Loading()),
          content: const Text(
            'Did you complete some training hours before?',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() => previousHours = 0);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('NO'),
            ),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => traineeSetHour(),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('YES'),
            ),
          ],
          elevation: 5,
          actionsAlignment: MainAxisAlignment.center,
          contentTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          actionsPadding: const EdgeInsets.all(30),
        ),
      ],
    );
  }

  Column traineeSetHour() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AlertDialog(
          title: const Center(child: Loading()),
          content: Column(
            children: [
              const Text(
                'How many hours did you complete?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Form(
                key: hourForm,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: TextFormField(
                  controller: previousHoursController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.hourglass_full),
                    labelText: 'Completed Hours',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Previous hours cannot be empty.';
                    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Previous hours must be in digit numbers';
                    } else if (int.parse(value) >= 22) {
                      return 'That number is unrealisitic.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (hourForm.currentState!.validate()) {
                  setState(() {
                    previousHours = int.parse(previousHoursController.text);
                  });
                  Navigator.pop(context);
                }
              },
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          actionsPadding: const EdgeInsets.all(30),
        ),
      ],
    );
  }
}
