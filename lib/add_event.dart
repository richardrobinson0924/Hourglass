import 'package:countdown/state_manager.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'color_stepper.dart';
import 'fillable_container.dart';
import 'model.dart';

class AddEventPage extends StatefulWidget {
  final Model model;

  AddEventPage({Key key, this.model}) : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState(model: model);
}

class _AddEventPageState extends State<AddEventPage> {
  static const titleIndex = 0, timeIndex = 1, colorIndex = 2;

  var _focusNode = FocusNode();
  var _formKey = GlobalKey<FormState>();

  String _eventName = '';
  DateTime _eventTime;
  Color eventColor = Colors.blue;

  final Model model;

  final manager = Manager<MyStepState>(
      steps: Iterable<MyStepState>.generate(3, (_) => MyStepState()));

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

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

  @override
  Widget build(BuildContext context) {
    final eventNameStep = Step(
        title: const Text('Event Title'),
        isActive: manager[titleIndex].isActive,
        state: manager[titleIndex].state,
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
        isActive: manager[timeIndex].isActive,
        state: manager[timeIndex].state,
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

    final colors = [
      Colors.blue,
      Colors.pink,
      Colors.indigo,
      Colors.teal,
      Colors.orange
    ];

    final eventColorStep = Step(
      title: const Text('Choose a Color'),
      isActive: manager[colorIndex].isActive,
      state: manager[colorIndex].state,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: colors
            .map((color) => CircleButton(
                color: color,
                radius: 18.0,
                onTap: () => setState(() => eventColor = color)))
            .toList(),
      ),
    );

    final steps = [eventNameStep, eventTimeStep, eventColorStep];

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Event'),
        backgroundColor: /* isDark ? ThemeData.dark().appBarTheme.color : */ eventColor,
      ),
      body: Container(
        child: Form(
            key: _formKey,
            child: ColorStepper(
              accentColor: eventColor,
              steps: steps,
              type: StepperType.vertical,
              currentStep: manager.currentIndex,
              onStepTapped: (step) =>
                  setState(() => manager.currentIndex = step),
              onStepContinue: _onContinueFunction(),
              onStepCancel: () => Navigator.pop(context),
            )),
      ),
    );
  }

  Callable _onContinueFunction() {
    var goToNextPage = () => setState(() => manager.currentIndex += 1);

    switch (manager.currentIndex) {
      case titleIndex:
        return _eventName.trim().isEmpty ? null : goToNextPage;

      case timeIndex:
        return goToNextPage;

      case colorIndex:
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

class MyStepState implements MyStep {
  bool isActive;
  StepState state;

  MyStepState({this.isActive, this.state});

  @override
  void onStepIsCurrent() {
    isActive = true;
    state = StepState.editing;
  }

  @override
  void onStepIsComplete() {
    isActive = false;
    state = StepState.complete;
  }

  @override
  void onStepIsUpcoming() {
    isActive = false;
    state = StepState.disabled;
  }
}

typedef Callable = void Function();
