import 'dart:async';

import 'package:flutter/material.dart';

class CustomPage<T> extends MaterialPage<T> {
  CustomPage({
    required Widget child,
    bool maintainState = true,
    bool fullscreenDialog = false,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  })  : completerResult = Completer(),
        super(
          child: child,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
          key: key,
          name: name,
          arguments: arguments,
          restorationId: restorationId);
  final Completer completerResult;
}