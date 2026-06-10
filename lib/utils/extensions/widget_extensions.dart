// lib/utils/extensions/widget_extensions.dart

import 'package:flutter/material.dart';

extension WidgetExtensions on Widget {
  Widget withPadding(EdgeInsets padding) =>
      Padding(padding: padding, child: this);

  Widget withAllPadding(double value) =>
      Padding(padding: EdgeInsets.all(value), child: this);

  Widget withHorizontalPadding(double value) =>
      Padding(
          padding: EdgeInsets.symmetric(horizontal: value), child: this);

  Widget withVerticalPadding(double value) =>
      Padding(
          padding: EdgeInsets.symmetric(vertical: value), child: this);

  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);

  Widget flexible({int flex = 1}) => Flexible(flex: flex, child: this);

  Widget centered() => Center(child: this);

  Widget opacity(double value) => Opacity(opacity: value, child: this);

  Widget visible(bool isVisible) =>
      Visibility(visible: isVisible, child: this);
}
