import 'package:countdown/fillable_container.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'model.dart';

class AddEventPage extends StatefulWidget {
  final Model model;

  AddEventPage({Key key, this.model}) : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState(model: model);
}

class _AddEventPageState extends State<AddEventPage> {
  var _focusNode = FocusNode();
  var _formKey = GlobalKey<FormState>();

  String _eventName = '';
  DateTime _eventTime;
  Color eventColor = Colors.blue;

  final Model model;

  _AddEventPageState({Key key, this.model})
      : assert(model != null),
        super();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));

    var now = DateTime.now();
    _eventTime = DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  var stepStates = [
    MyStepState(isActive: true, stepState: StepState.editing),
    MyStepState(isActive: false, stepState: StepState.indexed),
    MyStepState(isActive: false, stepState: StepState.indexed)
  ];

  var currentStepIndex = 0;
  var pickerColor = Colors.blue;

  final colorOptions = <Option<Color>>[
    Option(Colors.tealAccent, isSelected: true),
    Option(Colors.deepPurpleAccent),
    Option(Colors.indigoAccent),
    Option(Colors.orange),
    Option(Colors.redAccent)
  ];

  @override
  Widget build(BuildContext context) {
    final eventNameStep = Step(
        title: const Text('Event Title'),
        isActive: stepStates[0].isActive,
        state: stepStates[0].stepState,
        content: TextFormField(
          focusNode: _focusNode,
          keyboardType: TextInputType.text,
          onChanged: (value) => setState(() => _eventName = value),
          onSaved: (value) => _eventName = value,
          decoration: InputDecoration(
            labelText: 'Label text',
            hintText: 'Hint text',
            labelStyle: TextStyle(decorationStyle: TextDecorationStyle.solid),
          ),
        ));

    final format = DateFormat('MMMM d, yyyy \'at\' h:mm a');
    final now = DateTime.now();

    final eventTimeStep = Step(
        title: const Text('Event Time'),
        isActive: stepStates[1].isActive,
        state: stepStates[1].stepState,
        content: DateTimeField(
          readOnly: true,
          initialValue: DateTime(now.year, now.month, now.day, now.hour + 1),
          format: format,
          onShowPicker: (context, value) async {
            final date = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: now.add(Duration(minutes: 1)),
                lastDate: DateTime(2050));

            if (date != null) {
              final time = await showTimePicker(
                  context: context, initialTime: TimeOfDay.fromDateTime(value));

              return DateTimeField.combine(date, time);
            } else {
              return value;
            }
          },
          onChanged: (value) => _eventTime = value,
          onSaved: (value) => _eventTime = value,
        ));

    final eventColorStep = Step(
        title: const Text('Choose a Color'),
        isActive: stepStates[2].isActive,
        state: stepStates[2].stepState,
        content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: Iterable.generate(
                colorOptions.length,
                (index) => CircleButton(
                      radius: 18.0,
                      color: colorOptions[index].choice,
                      isSelected: colorOptions[index].isSelected,
                      onTap: () {
                        setState(() {
                          eventColor = colorOptions[index].choice;
                          colorOptions
                              .forEach((option) => option.isSelected = false);
                          colorOptions[index].isSelected = true;
                        });
                      },
                    )).toList()
//            colorOptions
//                .map((option) => CircleButton(
//                      radius: 15.0,
//                      color: option.color,
//                      isSelected: option.isSelected,
//                      onTap: () => setState(() {
//                        eventColor = option.color;
//                        colorOptions.forEach((o) => o.isSelected = false);
//                        option.isSelected = true;
//                      }),
//                    ))
//                .toList()
            ));

    final steps = [eventNameStep, eventTimeStep, eventColorStep];

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Event'),
      ),
      body: Container(
        child: Form(
            key: _formKey,
            child: Stepper(
              steps: steps,
              type: StepperType.vertical,
              currentStep: currentStepIndex,
              onStepTapped: onStepTapped,
              onStepContinue: _onContinueFunction(),
              onStepCancel: () => Navigator.pop(context),
            )),
      ),
    );
  }

  void onStepTapped(int stepIndex) => setState(() {
        currentStepIndex = stepIndex;
        stepStates[currentStepIndex].isActive = true;
        stepStates[currentStepIndex].stepState = StepState.editing;

        for (int i = 0; i < currentStepIndex; i += 1) {
          stepStates[i].isActive = false;
          stepStates[i].stepState = StepState.complete;
        }

        for (int i = currentStepIndex + 1; i < stepStates.length; i += 1) {
          stepStates[i].isActive = false;
          stepStates[i].stepState = StepState.indexed;
        }
      });

  void Function() _onContinueFunction() {
    var goToNextPage = () => onStepTapped(currentStepIndex + 1);

    switch (currentStepIndex) {
      case 0:
        return _eventName.trim().isEmpty ? null : goToNextPage;

      case 1:
        return goToNextPage;

      case 2:
        return () {
          model.addEvent(Event(
              title: this._eventName,
              end: this._eventTime,
              color: this.eventColor));

          Global.saveModel(model);
          Navigator.pop(context);
        };

      default:
        throw Exception();
    }
  }
}

class Option<T> {
  final T choice;
  bool isSelected;

  Option(this.choice, {this.isSelected = false});

  @override
  String toString() =>
      'Option(\n\tchoice: ${choice.toString()}\n\tisSelected: $isSelected\n)';
}

class MyStepState {
  bool isActive;
  StepState stepState;

  MyStepState({@required this.isActive, @required this.stepState});
}
