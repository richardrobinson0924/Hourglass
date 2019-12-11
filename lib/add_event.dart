import 'dart:convert';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

class AddEventPage extends StatefulWidget {
  final Model model;

  AddEventPage({Key key, this.model}) : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState(model: model);
}

class _AddEventPageState extends State<AddEventPage> {
  var _focusNode = FocusNode();
  int currStep = 0;
  var _formKey = GlobalKey<FormState>();

  String _eventName;
  DateTime _eventTime;

  final Model model;

  _AddEventPageState({Key key, this.model}) : super();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    var eventNameStep = Step(
      title: const Text('Event Title'),
      isActive: true,
      state: StepState.indexed,
      content: TextFormField(
        focusNode: _focusNode,
        keyboardType: TextInputType.text,
        onChanged: (value) => _eventName = value,
        onSaved: (value) => _eventName = value,
        decoration: InputDecoration(
          labelText: 'Label text',
          hintText: 'Hint text',
          labelStyle: TextStyle(decorationStyle: TextDecorationStyle.solid),
        ),
      )
    );

    final format = DateFormat('yyyy-MM-dd HH:mm');

    var eventTimeStep = Step(
      title: const Text('Event Time'),
      isActive: true,
      state: StepState.indexed,
      content: DateTimeField(
        format: format,
        onShowPicker: (context, value) async {
          var now = DateTime.now();

          final date = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: now,
              lastDate: DateTime(2050)
          );

          if (date != null) {
            final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(value ?? now)
            );

            return DateTimeField.combine(date, time);
          } else {
            return value;
          }
        },
        onChanged: (value) => _eventTime = value,
        onSaved: (value) => _eventTime = value,
      )
    );

    var steps = [eventNameStep, eventTimeStep];

    var onContinue = () async {
      if (currStep < steps.length - 1) {
        setState(() => currStep = currStep + 1);
      } else {
        assert (this._eventTime != null);

        var event = Event(title: this._eventName, end: this._eventTime);
        model.events.add(event);

        Navigator.pop(context);
      }
    };

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Add Event'),
      ),
      body: Container(
        child: Form(
          key: _formKey,
          child: Stepper(
            steps: steps,
            type: StepperType.vertical,
            currentStep: this.currStep,
            onStepContinue: onContinue,
            onStepCancel: () => setState(() => currStep > 0 ? currStep - 1 : 0),
            onStepTapped: (step) => setState(() => currStep = step),
          ),
        ),
      ),
    );
  }
}
