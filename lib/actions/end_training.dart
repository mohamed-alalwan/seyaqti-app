import 'package:flutter/material.dart';
import 'package:seyaqti_app/widgets/loading.dart';

// ignore: must_be_immutable
class EndTraining extends StatefulWidget {
  EndTraining({super.key});
  bool? confirm;
  @override
  State<EndTraining> createState() => _EndTrainingState();
}

class _EndTrainingState extends State<EndTraining> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AlertDialog(
          title: const Center(child: Loading()),
          content: const Text(
            'Are you sure you want to end the training?',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() => widget.confirm = true);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('CONFIRM'),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() => widget.confirm = false);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('CANCEL'),
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
