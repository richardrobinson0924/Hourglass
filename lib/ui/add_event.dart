import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/model.dart';

class AddEventPage extends StatefulWidget {
  AddEventPage({Key key}) : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  var _focusNode = FocusNode();
  var _formKey = GlobalKey<FormState>();

  static final colors = <Color>[
    Colors.teal,
    Colors.deepPurpleAccent,
    Colors.indigoAccent,
    Colors.orange,
    Colors.redAccent
  ];

  String _eventName = '';

  DateTime _eventTime = () {
    var now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }();

  Color eventColor = colors.first;

  _AddEventPageState() : super();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  final stepStates = {
    MyState.name: MyStepState(
        name: 'What\'s your Event?', isActive: true, state: StepState.editing),
    MyState.date: MyStepState(
        name: 'When is it?', isActive: false, state: StepState.indexed),
    MyState.color: MyStepState(
        name: 'Choose a Color', isActive: false, state: StepState.indexed)
  };

  var currentStep = MyState.name;

  @override
  Widget build(BuildContext context) {
    final eventNameStep = Step(
        title: const Text('Event Title'),
        isActive: stepStates[MyState.name].isActive,
        state: stepStates[MyState.name].state,
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
        isActive: stepStates[MyState.date].isActive,
        state: stepStates[MyState.date].state,
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
        isActive: stepStates[MyState.color].isActive,
        state: stepStates[MyState.color].state,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: colors.map((color) {
            final large = Circle(radius: 18.0, color: color);
            final mini = Circle(radius: 7.0, color: Colors.white);

            return InkResponse(
              onTap: () => setState(() => eventColor = color),
              radius: 30.0,
              child: color == eventColor
                  ? Stack(alignment: Alignment.center, children: [large, mini])
                  : large,
            );
          }).toList(),
        ));

    return Theme(
      data: Theme.of(context)
          .copyWith(primaryColor: eventColor, accentColor: eventColor),
      child: Scaffold(
        appBar: AppBar(
            title: Text('Add Event', style: TextStyle(color: Colors.white))),
        body: Container(
          child: Form(
              key: _formKey,
              child: Stepper(
                steps: [eventNameStep, eventTimeStep, eventColorStep],
                type: StepperType.vertical,
                currentStep: currentStep.index,
                onStepTapped: onStepTapped,
                onStepContinue: _onContinueFunction(),
                onStepCancel: () => Navigator.pop(context),
              )),
        ),
      ),
    );
  }

  void onStepTapped(int stepIndex) => setState(() {
        currentStep = MyState.values[stepIndex];
        stepStates[currentStep].isActive = true;
        stepStates[currentStep].state = StepState.editing;

        for (int i = 0; i < currentStep.index; i += 1) {
          stepStates[i].isActive = false;
          stepStates[i].state = StepState.complete;
        }

        for (int i = currentStep.index + 1; i < stepStates.length; i += 1) {
          stepStates[i].isActive = false;
          stepStates[i].state = StepState.indexed;
        }
      });

  VoidCallback _onContinueFunction() {
    var goToNextPage = () => onStepTapped(currentStep.index + 1);

    switch (currentStep) {
      case MyState.name:
        return _eventName.trim().isEmpty ? null : goToNextPage;

      case MyState.date:
        return goToNextPage;

      case MyState.color:
        return () {
          Model.instance().addEvent(
              Event(title: _eventName, end: _eventTime, color: eventColor));

          Model.instance().save();
          Navigator.pop(context);
        };

      default:
        throw Exception();
    }
  }
}

enum MyState { name, date, color }

class MyStepState {
  final String name;
  bool isActive;
  StepState state;

  MyStepState(
      {@required this.name, @required this.isActive, @required this.state});
}
