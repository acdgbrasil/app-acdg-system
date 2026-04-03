import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acdg_system/logic/di/auth_providers.dart';
import 'package:acdg_system/logic/router/app_router.dart';
import 'package:acdg_system/ui/view_models/auth_view_model.dart';
import 'package:auth/auth.dart';
import 'fake_auth_repository.dart';

void main() {
  group('Auth DI Regression & Blindagem', () {
    late FakeAuthRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('REGRESSÃO: AuthViewModel e AppRouter DEVEM compartilhar a mesma instância via Riverpod', () {
      final authVM = container.read(authViewModelProvider);
      final router = container.read(appRouterProvider);

      expect(router.authViewModel, same(authVM), 
        reason: 'ALERTA: Instâncias duplicadas detectadas! O AppRouter deve usar o VM do Riverpod.');
    });

    test('REGRESSÃO: AuthViewModel DEVE sincronizar estado inicial do repositório (Eliminação do Ponto Cego)', () async {
      // Simula o repositório já autenticando durante o boot da infra
      final preAuthRepo = FakeAuthRepository()..hasExistingSession = true;
      await preAuthRepo.tryRestoreSession(); 
      
      expect(preAuthRepo.currentStatus, isA<Authenticated>());

      final preAuthContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(preAuthRepo),
        ],
      );
      addTearDown(preAuthContainer.dispose);

      // No momento que o VM nasce, ele deve ler o estado "já autenticado"
      final authVM = preAuthContainer.read(authViewModelProvider);
      
      expect(authVM.status, isA<Authenticated>(),
        reason: 'ALERTA: O ViewModel falhou em ler o estado inicial do repositório. Risco de ficar preso no Splash!');
    });

    test('BLINDAGEM: AppRouter DEVE reagir a mudanças de estado subsequentes', () async {
      final authVM = container.read(authViewModelProvider);
      final router = container.read(appRouterProvider);

      expect(authVM.status, isA<Unauthenticated>());

      // Dispara login
      await fakeRepo.login();
      
      // Espera propagação do Stream
      await Future.delayed(Duration.zero);

      expect(authVM.status, isA<Authenticated>());
      expect(router.authViewModel.status, isA<Authenticated>(),
        reason: 'O Router não reagiu à mudança de status do ViewModel principal.');
    });

    test('BLINDAGEM: authInitializationProvider DEVE garantir a execução do init()', () async {
      fakeRepo.hasExistingSession = true;
      
      // O provider de inicialização deve disparar o restoreSession
      await container.read(authInitializationProvider.future);

      final authVM = container.read(authViewModelProvider);
      expect(authVM.status, isA<Authenticated>(),
        reason: 'O authInitializationProvider não chamou o restoreSessionUseCase corretamente.');
    });
  });
}
