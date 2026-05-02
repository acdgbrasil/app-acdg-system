/// RED-phase tests for `resultsAreOnline` (D01 W0.5).
///
/// `connectivity_plus` v7 emits a `List<ConnectivityResult>` per change
/// (not a single value) so devices with multiple active interfaces — Wi-Fi
/// + VPN, Wi-Fi + Ethernet, Wi-Fi + Bluetooth — can report all of them at
/// once. The facade collapses that list to a boolean for D5 γ
/// (trigger-based drain on the offline → online edge).
///
/// Today the helper lives at line 716 of `social_care_desktop.dart` as
/// the private `_resultsAreOnline`. D01 extracts it to
/// `lib/src/facade/composition/connectivity_helpers.dart` as a free
/// top-level `bool resultsAreOnline(...)` so the connectivity wiring in
/// the facade can be unit-tested independently of the rest of the
/// composition root.
///
/// ── Surface under test ────────────────────────────────────────────────
///   * `bool resultsAreOnline(List<ConnectivityResult> results)`
///       Truth table: returns `true` iff at least one element is NOT
///       `ConnectivityResult.none`. Empty list → `false`
///       (no signal == not online).
///
/// ── REGRA #2: empty-list semantics ────────────────────────────────────
/// `connectivity_plus` does not document whether an empty list is
/// possible (the API typically returns at least `[none]`). We assert
/// `false` for `[]` because that's the safest interpretation for the
/// drain-trigger contract: "no reported interfaces ⇒ no triggering".
/// If W1 implements `[]` as `true` (no interfaces == online by default),
/// that's a contract change and must be flagged.
///
/// IMPORTANT (RED phase): the import resolves to a file that does NOT
/// exist yet — `lib/src/facade/composition/connectivity_helpers.dart`
/// is W1's output. Until then this file fails to analyze. That is the
/// intended RED signal.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/facade/composition/connectivity_helpers.dart';

void main() {
  group('resultsAreOnline', () {
    test('empty list → false (no reported interfaces == not online)', () {
      expect(resultsAreOnline(const <ConnectivityResult>[]), isFalse);
    });

    test('[none] → false', () {
      expect(
        resultsAreOnline(const [ConnectivityResult.none]),
        isFalse,
        reason: 'a single `none` result is the canonical offline signal',
      );
    });

    test('[wifi] → true', () {
      expect(resultsAreOnline(const [ConnectivityResult.wifi]), isTrue);
    });

    test('[mobile] → true', () {
      expect(resultsAreOnline(const [ConnectivityResult.mobile]), isTrue);
    });

    test('[none, wifi] → true (any non-none counts)', () {
      expect(
        resultsAreOnline(
          const [ConnectivityResult.none, ConnectivityResult.wifi],
        ),
        isTrue,
        reason:
            'mixed results: presence of one online interface flips the bit',
      );
    });

    test('[bluetooth, none, ethernet] → true (multiple non-none entries)', () {
      expect(
        resultsAreOnline(
          const [
            ConnectivityResult.bluetooth,
            ConnectivityResult.none,
            ConnectivityResult.ethernet,
          ],
        ),
        isTrue,
      );
    });

    test('[vpn, other] → true (non-standard interfaces still count)', () {
      expect(
        resultsAreOnline(
          const [ConnectivityResult.vpn, ConnectivityResult.other],
        ),
        isTrue,
        reason:
            'spec uses `any((r) => r != ConnectivityResult.none)` — every '
            'enum value except `none` MUST yield true',
      );
    });
  });
}
