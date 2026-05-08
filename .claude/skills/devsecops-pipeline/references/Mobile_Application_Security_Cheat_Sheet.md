# Mobile Application Security Cheat Sheet (iOS / Flutter)

Resumo prático alinhado ao OWASP MASVS (Mobile Application Security Verification Standard) e MASTG. Foco em iOS Swift/SwiftUI e Flutter/Dart, que são as stacks usadas no nosso ambiente.

## 1. Storage de Dados Sensíveis

### iOS
- **Keychain** é o único lugar aceitável para tokens, senhas, chaves.
- Atributos de acessibilidade — escolha o mais restritivo que o caso permite:
  - `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — só acessível quando device está desbloqueado, não sai do device em backups.
  - `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` — acessível após primeiro unlock (background tasks).
  - **Nunca** use `kSecAttrAccessibleAlways*` — deprecated e expõe dados.
- `UserDefaults` é claro-texto em `Library/Preferences/*.plist`. Nunca para dados sensíveis.
- Arquivos sensíveis: use `URLFileProtection.complete` ou `.completeUntilFirstUserAuthentication`.
- Backups: marque arquivos sensíveis com `URLResourceKey.isExcludedFromBackupKey = true`.

### Flutter
- **`flutter_secure_storage`** — abstrai Keychain (iOS) e EncryptedSharedPreferences/Keystore (Android).
- Configure:
  - iOS: `IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device)`
  - Android: `AndroidOptions(encryptedSharedPreferences: true)`
- **Nunca** `SharedPreferences` plain para tokens.
- Cache HTTP: configure cliente para não persistir respostas autenticadas.

## 2. Comunicação em Rede

### iOS
- **App Transport Security (ATS)** estrito no `Info.plist`:
  ```xml
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key><false/>
  </dict>
  ```
- TLS 1.2+ é obrigatório. ATS já força.
- **Certificate pinning** para endpoints críticos (auth, financeiro): valide SPKI hash em `URLSessionDelegate`. Use TrustKit em produção.
- Nunca aceite `BadCertificateCallback` que retorne `true` cegamente.

### Flutter
- `BadCertificateCallback` deve validar SPKI/sha256 contra lista pinada.
- Pacotes recomendados: `dio` + `http_certificate_pinning` ou `ssl_pinning_plugin`.
- HTTP cleartext (sem TLS) deve estar bloqueado:
  - Android: `android:usesCleartextTraffic="false"` no `AndroidManifest.xml`.
  - iOS: ATS estrito (acima).

## 3. Autenticação e Autorização

- **Biometria** (Face ID / Touch ID / fingerprint) é uma camada de UX, não de identidade. Use `LocalAuthentication` (iOS) ou `local_auth` (Flutter) para *desbloquear* tokens guardados em Keychain — não para *substituir* auth no servidor.
- **Token de longa duração no device** deve ser refresh token, idealmente com binding ao device (DPoP, attestation).
- Tokens enviados em headers (`Authorization: Bearer ...`), nunca em URL.
- Após logout, `SecItemDelete` (iOS) ou `secureStorage.deleteAll()` (Flutter) — não confie em "expirar e esquecer".

## 4. Code Protection

- **Ofuscação**:
  - Flutter: `flutter build apk/ios --release --obfuscate --split-debug-info=./symbols`.
  - iOS: built-in via Swift compiler em release; remova símbolos em strip.
- **Debug detection**: detectar debugger anexado (`isatty(STDERR_FILENO)` em iOS, ou checks via Frida-detection libs) — não substitui defesa server-side, mas atrapalha o atacante casual.
- **Jailbreak / root detection** leve:
  - iOS: checar arquivos como `/Applications/Cydia.app`, sandboxes quebrados, ability to write fora do sandbox.
  - Android (Flutter via plugin): SafetyNet/Play Integrity, magisk hide checks.
- Trate qualquer detecção como sinal — degrade funcionalidade ou marque sessão como "untrusted" no backend. **Nunca** use detecção como única defesa.

## 5. WebViews e Deep Links

- WebViews:
  - iOS `WKWebView` (não `UIWebView`, deprecated).
  - Habilite apenas as features necessárias (`javaScriptEnabled`, `allowFileAccessFromFileURLs = false`).
  - Origens carregadas devem ser whitelisted.
- Deep links / Universal Links:
  - Valide o link recebido — não confie em `URL` para tomar ações sensíveis sem auth/confirmação.
  - Use Universal Links (iOS) e App Links (Android) — assinados pelo domínio.

## 6. Logs e Telemetria

- **Nunca** logue tokens, PII, senhas. Em iOS, OSLog tem `.private` para masking — use sempre que houver dado sensível na string.
- Em Flutter, configure `kReleaseMode` para silenciar `print()` e `debugPrint`.
- Crash reporters (Sentry, Crashlytics, Firebase): configure scrubbing de campos sensíveis.

## 7. Build e Distribuição

- **Code signing**:
  - iOS: distribuição via App Store Connect com certificado da organização.
  - Android: `play-app-signing` para que a Google guarde a chave de upload.
- **Symbol stripping** em release.
- **Sem chaves embedded**: `.env`, `Secrets.swift`, ou strings hardcoded são facilmente extraídos com `strings`/`Hopper`.
  - Para chaves que precisam estar no client (ex.: API keys públicas), trate como público — não como secret.
  - Para tokens curtos (assinados pelo backend), use refresh flow.

## 8. Permissões

- Peça apenas o mínimo necessário, no momento em que precisa (just-in-time).
- iOS: cada `NS*UsageDescription` precisa ter justificativa real ou a App Store rejeita.
- Flutter: declare permissões só quando usadas em release manifest.

## 9. Privacidade e LGPD

- Coleta de dados pessoais: explicite no opt-in, com base legal clara.
- Permissão de tracking (iOS ATT): `App Tracking Transparency` para uso de IDFA.
- Direito ao apagamento: implemente "deletar minha conta" *no app* — não só por suporte humano.
- Privacy Manifest (iOS 17+): obrigatório listar APIs sensíveis usadas.

## 10. Testing Mínimo

- **Unit tests** para fluxos de Keychain/secure storage.
- **Integration tests** simulando MITM (proxy intermediário) — verifique que cert pinning REJEITA cert falso.
- **Static analysis**: SwiftLint/SwiftFormat + Mobsf para Android.
- **MASTG checklist** rápido antes de release: storage, crypto, auth, network, code, resilience.

## Checklist Rápido de Release

- [ ] Tokens em Keychain/Secure Storage (não UserDefaults/SharedPreferences).
- [ ] ATS estrito (iOS) / `usesCleartextTraffic=false` (Android).
- [ ] Certificate pinning em endpoints críticos.
- [ ] Sem secrets hardcoded — `strings <bin>` deve ser inútil.
- [ ] Logs em release não vazam dados sensíveis.
- [ ] Permissões mínimas, com justificativa.
- [ ] Build com `--obfuscate` e symbols separados.
- [ ] Crash reporter com scrubbing.
- [ ] Privacy manifest preenchido (iOS 17+).

## Referências externas

- OWASP MASVS — https://mas.owasp.org/MASVS/
- OWASP MASTG — https://mas.owasp.org/MASTG/
- Apple Platform Security — https://support.apple.com/guide/security/
