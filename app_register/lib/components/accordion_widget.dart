import 'package:flutter/material.dart';
import 'accordion_item_widget.dart';

class AccordionWidget extends StatelessWidget {
  final List<AccordionItemWidget> items;

  const AccordionWidget({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items,
    );
  }
}
