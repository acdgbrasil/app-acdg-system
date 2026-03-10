# Qualidade — frontend (Conecta Raros)

Estrategia de testes, cobertura, acessibilidade e performance.

---

## 1. Estrategia de Testes

### 1.1 Piramide de Testes

```
         /\
        /  \       E2E (Integration)
       /    \      Poucos, lentos, validam fluxo completo
      /------\
     /        \    Widget Tests
    /          \   Medios, validam componentes isolados
   /------------\
  /              \  Unit Tests
 /                \ Muitos, rapidos, validam logica pura
/==================\
```

### 1.2 O Que Testar

| Camada | Tipo de Teste | Cobertura Alvo |
|--------|--------------|----------------|
| **ViewModel** | Unit test | 95%+ — toda logica de estado |
| **UseCase** | Unit test | 95%+ — toda logica de aplicacao |
| **Repository** | Unit test | 90%+ — cache, retry, error handling |
| **Service** | Unit test (mock HTTP) | 80%+ — parsing de responses |
| **BFF Domain** | Unit test | 95%+ — toda regra de negocio |
| **BFF Application** | Unit test | 95%+ — commands, queries, sync |
| **Atoms/Cells** | Widget test | 70%+ — renderiza corretamente |
| **Pages** | Widget test | 50%+ — fluxo principal |
| **E2E** | Integration test | Fluxos criticos (login, cadastro, sync offline) |

### 1.3 Naming Convention

```dart
group('PatientRegistrationViewModel', () {
  test('should emit loading state when registering patient', () { ... });
  test('should emit error state when patient already exists', () { ... });
  test('should queue action when offline', () { ... });
});
```

---

## 2. Cobertura

- **Meta global:** >= 85% de cobertura de linhas
- **ViewModels e UseCases:** >= 95%
- **BFF Domain:** >= 95%
- **Enforcement:** CI bloqueia PR abaixo da meta

---

## 3. Performance

### 3.1 Metricas Alvo

| Metrica | Web | Desktop |
|---------|-----|---------|
| First Paint | < 2s | N/A |
| Time to Interactive | < 3s | < 1s |
| Bundle size (WASM) | < 5MB initial | N/A |
| Memory usage | < 100MB | < 200MB |
| Jank (frames dropped) | < 1% | < 1% |

### 3.2 Otimizacoes

- Deferred loading para micro-apps (so carrega quando navega)
- ValueNotifier para rebuilds cirurgicos (nao rebuilda arvore inteira)
- Isar para cache local (evita requests desnecessarios)
- `const` constructors em todos os widgets estaticos
- Image caching e lazy loading

---

## 4. Acessibilidade

- Semantics em todos os widgets interativos
- Contraste minimo WCAG AA
- Navigation por teclado (desktop)
- Screen reader support (VoiceOver/TalkBack)
- Font scaling respeitado

---

## 5. Observabilidade

- Logs estruturados no BFF (nao no frontend)
- Error tracking: excepcoes nao capturadas reportadas ao BFF
- Offline queue monitoring: tamanho da queue visivel em modo dev
