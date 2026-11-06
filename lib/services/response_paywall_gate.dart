import 'package:flutter/material.dart';

/// Free edition: every feature is available without a subscription.
class ResponsePaywallGate {
  static Future<bool> allow(
    BuildContext context, {
    bool returnOnDismiss = true,
  }) async => true;
}
