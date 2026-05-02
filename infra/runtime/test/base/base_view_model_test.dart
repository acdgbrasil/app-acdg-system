import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestViewModel extends BaseViewModel {
  int disposeCount = 0;

  @override
  void onDispose() {
    disposeCount++;
  }
}

void main() {
  group('BaseViewModel', () {
    test('starts not disposed', () {
      final vm = _TestViewModel();
      expect(vm.disposed, isFalse);
      vm.dispose();
    });

    test('disposed is true after dispose', () {
      final vm = _TestViewModel();
      vm.dispose();
      expect(vm.disposed, isTrue);
    });

    test('onDispose is called on dispose', () {
      final vm = _TestViewModel();
      vm.dispose();
      expect(vm.disposeCount, 1);
    });

    test('notifyListeners does nothing after dispose', () {
      final vm = _TestViewModel();
      var notified = false;
      vm.addListener(() => notified = true);
      vm.dispose();
      vm.notifyListeners();
      expect(notified, isFalse);
    });
  });
}
