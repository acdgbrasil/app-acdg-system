# Flutter Web Cache Strategy — Aprendizados e Decisões

> **Data:** 2026-04-14
> **Contexto:** Primeira simulação de deploy web (Docker prod) do Conecta Raros
> **Status:** Implementado e validado

---

## 1. O Problema

Ao fazer deploy de uma nova versão do Flutter Web (WASM), **usuários continuavam vendo a versão antiga** mesmo após:

- Hard reload (Ctrl+Shift+R)
- Limpeza de Service Worker e Cache API via JavaScript
- `ignoreCache: true` no Chrome DevTools Protocol
- `location.reload(true)` (deprecated, ignorado por todos os browsers)

O build novo existia no servidor (confirmado via `strings` no `.wasm`), mas o browser se recusava a buscá-lo.

---

## 2. Causa Raiz

### 2.1 Flutter NÃO faz content-hash nos nomes de arquivo

Diferente de bundlers como webpack/vite/esbuild, o Flutter Web gera **sempre os mesmos nomes**:

```
main.dart.wasm    ← mesmo nome em todo build
main.dart.mjs     ← mesmo nome em todo build
main.dart.js      ← mesmo nome em todo build
flutter_bootstrap.js
flutter.js
```

Não existe flag `--content-hash` no `flutter build web`. Issue aberta: [flutter#161615](https://github.com/flutter/flutter/issues/161615).

### 2.2 Headers `Cache-Control: immutable` em arquivos não-versionados

Nosso Caddyfile original aplicava:

```
@assets path_regexp \.(wasm|mjs|js|css|png|jpg|svg|ico|woff2?)$
header @assets Cache-Control "public, immutable, max-age=31536000"
```

O `immutable` diz ao browser: **"este arquivo NUNCA muda nesta URL — nem tente revalidar, nem com refresh explícito"**. Combinado com `max-age=31536000` (1 ano), o browser armazena no **HTTP disk cache** e serve de lá por até 1 ano sem contatar o servidor.

### 2.3 HTTP disk cache é inacessível por JavaScript

Existem 3 camadas de cache no browser:

```
┌─────────────────────────────────────────────┐
│  HTTP Disk Cache (browser-managed)          │  ← NÃO acessível por JS
│  Controlado por Cache-Control headers       │  ← Só Clear-Site-Data ou nova URL
├─────────────────────────────────────────────┤
│  Service Worker Cache Storage (Cache API)   │  ← Acessível via window.caches
├─────────────────────────────────────────────┤
│  Memory Cache (per-tab, efêmero)            │  ← Limpa ao fechar aba
└─────────────────────────────────────────────┘
```

`window.caches.delete()`, `serviceWorker.unregister()`, `localStorage.clear()` — **nenhum** atinge o HTTP disk cache. Mesmo `location.reload(true)` foi deprecated e ignorado.

### 2.4 Evidência forense

Usando Chrome DevTools MCP, confirmamos via `performance.getEntriesByType('resource')`:

| Arquivo | transferSize | Do cache? |
|---------|-------------|-----------|
| `main.dart.wasm` | 0 | Sim (disk cache) |
| `main.dart.mjs` | 0 | Sim (disk cache) |

E via `get_network_request`, o response tinha:
```
cache-control: public, immutable, max-age=31536000
date: Mon, 13 Apr 2026 12:29:52 GMT   ← de ONTEM
```

O browser nem fez request ao servidor — serviu direto do disk cache.

---

## 3. Impacto

- **Bug impeditivo para deploy:** qualquer atualização ficaria invisível para usuários existentes
- **Sem solução pelo usuário:** nem hard reload resolve `immutable`
- **Única saída manual:** limpar "Cached images and files" em chrome://settings ou aba anônima
- **Afetaria produção igualmente:** Cloudflare Tunnel não bypass o CDN edge cache

---

## 4. Estratégia Implementada (3 Camadas)

### Camada 1: Headers HTTP corretos (Server — Caddyfile)

**Princípio:** `immutable` só é seguro para arquivos com content-hash no nome (URL muda a cada build). Flutter não faz isso, então `.wasm/.mjs/.js` NUNCA devem ser `immutable`.

```caddy
# ✅ Fonts e imagens — filenames estáveis, conteúdo não muda
@immutable path_regexp \.(woff2?|png|jpg|jpeg|svg|ico|gif|css)$
header @immutable Cache-Control "public, immutable, max-age=31536000"

# ✅ Código Flutter — no-store (não no-cache!)
# no-store: browser NÃO armazena no disk cache
# no-cache: browser armazena MAS revalida (Cloudflare trata como "cache + revalidate")
@flutter_code path_regexp \.(wasm|mjs|js)$
header @flutter_code Cache-Control "no-store, must-revalidate"

# ✅ Entry points — nunca cachear
@entrypoints path / /index.html /version.json /flutter_bootstrap.js /manifest.json
header @entrypoints Cache-Control "no-store, must-revalidate"
```

**Por que `no-store` e não `no-cache`:**
- Cloudflare CDN (que fica na frente do Tunnel) trata `no-cache` como "cache + revalidate" quando Origin Cache Control está habilitado
- `.js` está na lista default de cache da Cloudflare (cacheado por 120min)
- `no-store` é o único directive que garante zero cache tanto no edge quanto no browser

### Camada 2: Cache busting no Flutter (Client — index.html)

**`entrypointUrl` com versão de build:**

```javascript
var buildVersion = "{{flutter_service_worker_version}}";
_flutter.loader.load({
  entrypointUrl: "main.dart.js?v=" + buildVersion,
  // ...
});
```

O token `{{flutter_service_worker_version}}` é substituído pelo Flutter em build time por um inteiro único. Cada build gera uma URL diferente → browser trata como recurso novo.

**Post-build sed no Dockerfile** para os `.wasm` e `.mjs`:

```dockerfile
RUN BUILD_AT=$(date +%s) && \
    cd apps/acdg_system/build/web && \
    sed -i "s|main\.dart\.mjs|main.dart.mjs?v=${BUILD_AT}|g" flutter_bootstrap.js && \
    sed -i "s|main\.dart\.wasm|main.dart.wasm?v=${BUILD_AT}|g" flutter_bootstrap.js && \
    sed -i "s|main\.dart\.js|main.dart.js?v=${BUILD_AT}|g" flutter_bootstrap.js
```

**`--pwa-strategy=none`** no build — elimina o Service Worker do Flutter, removendo uma camada de cache desnecessária.

### Camada 3: Version gate inteligente (Client + Server)

Para resolver o problema de **usuários que já têm entries `immutable` no disk cache** de deploys anteriores, implementamos um sistema de invalidação sob demanda.

**Fluxo:**

```
Usuário abre o app
  │
  ├─ JS busca /version.json (sempre fresh via cache: 'no-store')
  ├─ Compara com localStorage['acdg_app_version']
  │
  ├─ MATCH → Boot Flutter normalmente (overhead: ~100 bytes)
  │
  └─ MISMATCH (deploy novo detectado) →
       ├─ fetch('/cache-invalidate')
       │    └─ Caddy responde com Clear-Site-Data: "cache"
       │       └─ Browser APAGA todo HTTP disk cache do origin
       ├─ Limpa Service Worker caches (Cache API)
       ├─ Atualiza localStorage com versão nova
       └─ location.reload()
            └─ Tudo carrega fresh do servidor
```

**Endpoint Caddy:**

```caddy
handle /cache-invalidate {
    header Cache-Control "no-store"
    header Clear-Site-Data "\"cache\""
    respond "cache cleared" 200
}
```

**Version gate JS** (em `web/index.html`, antes do Flutter bootstrap):

```javascript
(async function() {
  try {
    var resp = await fetch('/version.json?t=' + Date.now(), { cache: 'no-store' });
    if (!resp.ok) return;
    var data = await resp.json();
    var deployed = data.version || '';
    var stored = localStorage.getItem('acdg_app_version');

    if (stored !== null && stored !== deployed) {
      await fetch('/cache-invalidate', { cache: 'no-store' });
      // ... limpa SW caches, atualiza localStorage, reload
    }

    if (stored === null) localStorage.setItem('acdg_app_version', deployed);
  } catch (e) { /* nunca bloquear boot */ }
})();
```

**Controle de versão:** bumpar `version:` no `pubspec.yaml` a cada deploy. Flutter gera `version.json` automaticamente.

---

## 5. Compatibilidade com Cloudflare

### Comportamento padrão do Cloudflare CDN

O CDN da Cloudflare fica na frente do Tunnel (não há bypass):

```
Browser → Cloudflare Edge (CDN + Cache) → Tunnel → Caddy → BFF
```

| Extensão | Cacheada por default? | Edge TTL default |
|----------|----------------------|-----------------|
| `.js` | **Sim** | 120 min |
| `.css` | Sim | 120 min |
| `.wasm` | **Não** (DYNAMIC) | N/A |
| `.mjs` | **Não** (DYNAMIC) | N/A |
| `.html` | Não | N/A |
| `.woff2`, `.png` | Sim | 120 min |

### Implicações

- `.js` é cacheado pelo Cloudflare por default → `no-cache` seria insuficiente (Cloudflare trata como "cache + revalidate"), por isso usamos `no-store`
- `.wasm` e `.mjs` não são cacheados por default → nosso `no-store` é belt-and-suspenders
- `immutable` é um directive de browser, não afeta o edge TTL da Cloudflare
- `Clear-Site-Data` funciona no browser, não no edge (o que é correto — queremos limpar o disk cache do usuário)

### Cache Rules recomendadas no Cloudflare Dashboard

1. **Bypass cache** para `*.html`, `*.js`, `*.wasm`, `*.mjs`
2. **Cache Everything + Edge TTL 1 ano** para fonts/imagens

---

## 6. O Que NÃO Funciona (Aprendizado)

| Técnica | Por que falha |
|---------|--------------|
| `location.reload(true)` | Deprecated, ignorado por todos os browsers |
| Hard reload (Ctrl+Shift+R) | `immutable` diz ao browser para pular revalidação mesmo em refresh explícito |
| `window.caches.delete()` | Só limpa Service Worker Cache Storage, NÃO o HTTP disk cache |
| `cache.delete()` no Service Worker | Mesmo — namespaces de cache separados |
| `Cache-Control: no-cache` nos arquivos já cacheados | Irrelevante — browser nem pergunta ao servidor durante o TTL do `immutable` |
| ETags / If-None-Match | Mesmo — nenhuma revalidação é enviada |
| Limpar localStorage/sessionStorage/IndexedDB | Nenhum desses é o HTTP disk cache |

---

## 7. Referências

### Issues Flutter

- [#161615](https://github.com/flutter/flutter/issues/161615) — Add hash fragment to web files (aberta)
- [#63500](https://github.com/flutter/flutter/issues/63500) — Web Cache invalidation based on Build Number
- [#106943](https://github.com/flutter/flutter/issues/106943) — Cached flutter-web service worker
- [#149031](https://github.com/flutter/flutter/issues/149031) — Web Cache invalidation based on pubspec.yaml version
- [#155240](https://github.com/flutter/flutter/issues/155240) — Flutter Web Cache problem
- [#164613](https://github.com/flutter/flutter/issues/164613) — Flutter Web Deployment: Cache Busting

### Artigos e documentação

- [Content-Hashed Caching for Flutter Web](https://chipsoffury.com/blog/flutter-web-cache-busting-strategy/)
- [Removing Flutter's Service Worker](https://chipsoffury.com/posts/why-we-removed-flutter-service-worker/)
- ["Please Clear Your Cache" — How I Fixed Flutter Web Caching](https://dev.to/adriengras/please-clear-your-cache-how-i-finally-fixed-flutter-web-caching-for-good-5dlj)
- [Clear-Site-Data — MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data)
- [Cache-Control — MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
- [Cloudflare Default Cache Behavior](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
- [Cloudflare Origin Cache Control](https://developers.cloudflare.com/cache/concepts/cache-control/)

---

## 8. Checklist de Deploy

Antes de cada deploy web:

- [ ] Bumpar `version:` no `pubspec.yaml` (o version gate depende disso)
- [ ] Verificar que `--pwa-strategy=none` está no comando de build
- [ ] Verificar que o `sed` de cache-busting roda após o `flutter build web`
- [ ] Após deploy, testar em browser COM cache antigo — deve auto-invalidar
- [ ] Após ~4 semanas de um deploy que mudou headers de cache, considerar remover medidas temporárias extras

---

## 9. Arquivos Modificados

| Arquivo | Mudança |
|---------|---------|
| `Caddyfile.prod` | Headers corretos + endpoint `/cache-invalidate` |
| `Caddyfile.dev` | Mesmos headers + endpoint |
| `Dockerfile.web` | `--pwa-strategy=none` + cache-busting `sed` + Caddyfile inline corrigido |
| `apps/acdg_system/web/index.html` | Version gate JS + `entrypointUrl` com `?v=` |
