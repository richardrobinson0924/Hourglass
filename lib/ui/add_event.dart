import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/model.dart';

class AddEventPage extends StatefulWidget {
  final Model model;

  AddEventPage({Key key, this.model}) : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState(model: model);
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

  final Model model;

  _AddEventPageState({Key key, this.model})
      : assert(model != null),
        super();

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

  final stepStates = [
    MyStepState(
        name: 'What\'s your Event?', isActive: true, state: StepState.editing),
    MyStepState(name: 'When is it?', isActive: false, state: StepState.indexed),
    MyStepState(
        name: 'Choose a Color', isActive: false, state: StepState.indexed)
  ];

  var currentStepIndex = 0;

  @override
  Widget build(BuildContext context) {
    final eventNameStep = Step(
        title: const Text('Event Title'),
        isActive: stepStates[0].isActive,
        state: stepStates[0].state,
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
        state: stepStates[1].state,
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
        state: stepStates[2].state,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: colors.map<Widget>((color) {
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
        stepStates[currentStepIndex].state = StepState.editing;

        for (int i = 0; i < currentStepIndex; i += 1) {
          stepStates[i].isActive = false;
          stepStates[i].state = StepState.complete;
        }

        for (int i = currentStepIndex + 1; i < stepStates.length; i += 1) {
          stepStates[i].isActive = false;
          stepStates[i].state = StepState.indexed;
        }
      });

  VoidCallback _onContinueFunction() {
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

class MyStepState {
  final String name;
  bool isActive;
  StepState state;

  MyStepState(
      {@required this.name, @required this.isActive, @required this.state});
}
