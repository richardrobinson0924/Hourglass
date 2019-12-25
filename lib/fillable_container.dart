import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SelectionBar<Option> extends StatefulWidget {
  final List<Option> options;
  final void Function(Option) onSelected;
  final Widget Function(BuildContext, Option, bool) builder;

  SelectionBar({Key key, this.options, this.onSelected, this.builder})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SelectionBarState();
}

class _SelectionBarState<Option> extends State<SelectionBar<Option>> {
  Option currentOption;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentOption = widget.options.first;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: widget.options
            .map((option) => InkResponse(
                onTap: () {
                  widget.onSelected(option);
                  setState(() => currentOption = option);
                },
                child:
                    widget.builder(context, option, option == currentOption)))
            .toList());
  }
}

class CircleButton extends StatefulWidget {
  final Color color;
  final double radius;
  final VoidCallback onTap;
  final bool isSelected;

  CircleButton(
      {Key key,
      this.color,
      @required this.radius,
      this.onTap,
      this.isSelected = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<CircleButton> {
  _CircleButtonState() : super();

  @override
  Widget build(BuildContext context) {
    final large = Container(
      alignment: Alignment.center,
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
          color: widget.color ?? Theme.of(context).primaryColor,
          shape: BoxShape.circle),
    );

    final mini = Container(
        alignment: Alignment.center,
        width: widget.radius * 2 / 3,
        height: widget.radius * 2 / 3,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle));

    final circle = widget.isSelected
        ? Stack(alignment: Alignment.center, children: [large, mini])
        : large;

    return InkResponse(child: circle, onTap: widget.onTap);
  }
}
