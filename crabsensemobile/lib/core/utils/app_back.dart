import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';

/// Back trên mọi màn: pop nếu còn stack, không thì về Trang chủ.
void appBack(BuildContext context, {String fallback = RoutePaths.dashboard}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(fallback);
}
