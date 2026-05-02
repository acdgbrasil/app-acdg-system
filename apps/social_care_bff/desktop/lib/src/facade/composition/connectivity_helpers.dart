import 'package:connectivity_plus/connectivity_plus.dart';

/// True if any [ConnectivityResult] in the list is non-`none`. The
/// `connectivity_plus` v7 plugin emits a list per change to support
/// devices with multiple active interfaces (Wi-Fi + VPN, Wi-Fi +
/// Ethernet, Wi-Fi + Bluetooth); ANY non-`none` member counts as
/// online for our trigger.
///
/// Empty list returns `false` — the safest interpretation for the
/// drain-trigger contract: no reported interfaces means no signal,
/// therefore no drain trigger.
bool resultsAreOnline(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);
