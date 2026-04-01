import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetreck/core/routing/app_routes.dart';

void openNotificationTarget(
  BuildContext context, {
  required String route,
  required String entityId,
  Map<String, dynamic>? payload,
}) {
  final trimmedRoute = route.trim();
  if (trimmedRoute.isNotEmpty) {
    context.push(trimmedRoute);
    return;
  }

  final resolvedPostId =
      (payload?['post_id'] ?? payload?['entity_id'] ?? entityId).toString();
  if (resolvedPostId.isNotEmpty && resolvedPostId != 'null') {
    context.push(AppRoutes.feedPost(resolvedPostId));
  }
}
