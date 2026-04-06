import 'package:flutter/material.dart';

void main() {
  final g = RadioGroup<String>(
    groupValue: 'A',
    onChanged: (v) {},
    child: Column(children: [
      RadioListTile<String>(value: 'A', title: Text('A')),
    ]),
  );
}