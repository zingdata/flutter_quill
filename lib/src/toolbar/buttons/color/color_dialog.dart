import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' as color_picker
    show ColorPicker, MaterialPicker, colorToHex;

import '../../../document/style.dart';
import '../../../editor_toolbar_shared/color.dart';
import '../../../l10n/extensions/localizations_ext.dart';

enum _PickerType {
  material,
  color,
}

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({
    required this.isBackground,
    required this.onRequestChangeColor,
    required this.isToggledColor,
    required this.selectionStyle,
    super.key,
  });
  final bool isBackground;

  final bool isToggledColor;
  final Function(BuildContext context, Color? color) onRequestChangeColor;
  final Style selectionStyle;

  @override
  State<ColorPickerDialog> createState() => ColorPickerDialogState();
}

class ColorPickerDialogState extends State<ColorPickerDialog> {
  var pickerType = _PickerType.color;
  var selectedColor = Colors.blue.shade100;

  late final TextEditingController hexController;
  late void Function(void Function()) colorBoxSetState;
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    hexController =
        TextEditingController(text: color_picker.colorToHex(selectedColor));
    if (widget.isToggledColor) {
      selectedColor = widget.isBackground
          ? hexToColor(widget.selectionStyle.attributes['background']?.value)
          : hexToColor(widget.selectionStyle.attributes['color']?.value);
    }
  }

  Timer debounce(
    Timer? timer,
    VoidCallback onDebounce,
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (timer?.isActive ?? false) {
      timer?.cancel();
      onDebounce();
    }
    return Timer(duration, callback);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.loc.selectColor),
          const CloseButton(),
        ],
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
            ), // Set the border color and width
          ),
          onPressed: () {
            widget.onRequestChangeColor(context, null);
            Navigator.of(context).pop();
          },
          child: Text(
            context.loc.clear,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ), // Set the border color and width
          ),
          onPressed: () {
            widget.onRequestChangeColor(context, selectedColor);
            Navigator.of(context).pop();
          },
          child: Text(
            context.loc.ok,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      ],
      backgroundColor: Theme.of(context).canvasColor,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row(
            //   children: [
            //     TextButton(
            //       onPressed: () {
            //         setState(() {
            //           pickerType = _PickerType.material;
            //         });
            //       },
            //       child: Text(context.loc.material),
            //     ),
            //     TextButton(
            //       onPressed: () {
            //         setState(() {
            //           pickerType = _PickerType.color;
            //         });
            //       },
            //       child: Text(context.loc.color),
            //     ),
            //     TextButton(
            //       onPressed: () {
            //         widget.onRequestChangeColor(context, null);
            //         Navigator.of(context).pop();
            //       },
            //       child: Text(context.loc.clear),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 6),
            Column(
              children: [
                if (pickerType == _PickerType.material)
                  color_picker.MaterialPicker(
                    pickerColor: selectedColor,
                    onColorChanged: (color) {
                      widget.onRequestChangeColor(context, color);
                      Navigator.of(context).pop();
                    },
                  ),
                if (pickerType == _PickerType.color)
                  color_picker.ColorPicker(
                    pickerColor: selectedColor,
                    labelTypes: const [],
                    onHsvColorChanged: (hsvColor) {
                      debounceTimer = debounce(debounceTimer, () {}, () {
                        final color = hsvColor.toColor();
                        widget.onRequestChangeColor(context, color);
                        selectedColor = color;
                        hexController.text = colorToHex(color);
                        colorBoxSetState(() {});
                      });
                    },
                    onColorChanged: (color) {
                      debounceTimer = debounce(debounceTimer, () {}, () {
                        widget.onRequestChangeColor(context, color);
                        selectedColor = color;
                        hexController.text = colorToHex(color);
                        colorBoxSetState(() {});
                      });
                    },
                  ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 60,
                      child: TextFormField(
                        controller: hexController,
                        buildCounter: (context,
                                {required currentLength, required isFocused, required maxLength}) =>
                            const SizedBox.shrink(),
                        onChanged: (value) {
                          debounceTimer = debounce(debounceTimer, () {}, () {
                            selectedColor = hexToColor(value);
                            colorBoxSetState(() {});
                          });
                        },
                        decoration: InputDecoration(
                          labelText: context.loc.hex,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    StatefulBuilder(
                      builder: (context, mcolorBoxSetState) {
                        colorBoxSetState = mcolorBoxSetState;
                        return Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black45,
                            ),
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
