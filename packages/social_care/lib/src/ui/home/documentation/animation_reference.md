Claro! Aqui vai o breakdown completo de todas as animações usadas:Claro! Aqui vai o mapa completo das animações usadas na implementação:Agora o detalhamento de cada uma:

---

**1. `slideIn` / `slideOut` — Painel lateral**

A animação principal. Quando o usuário clica num sobrenome, o painel de dados desliza da direita com `translateX(100%) → translateX(0)`. Usei a curva `cubic-bezier(0.4, 0, 0.2, 1)` que é a "standard easing" do Material Design — começa rápido e desacelera suavemente no final, dando sensação de peso físico. Duração de **350ms**, o sweet spot pra painéis: rápido o suficiente pra não irritar, lento o suficiente pra o olho acompanhar. O `slideOut` é o inverso exato, ativado quando `panelVisible` vira `false`.

**2. `fadeIn` — Overlay**

O fundo escuro (`rgba(38,29,17,0.05)`) aparece com fade de **300ms ease**, sincronizado com o slideIn mas levemente mais rápido. Isso cria um efeito de "camada" — o overlay chega antes do painel terminar de entrar, dando profundidade. No fechamento, o overlay faz fade-out via `transition: opacity 0.3s ease` em vez de keyframe, porque é mais simples de controlar com estado React.

**3. Hover na lista — fade de siblings**

Quando o mouse passa num sobrenome OU quando um está selecionado, os demais recebem `color: rgba(38,29,17,0.5)` com `transition: all 250ms ease`. O item ativo/hovered muda `fontWeight` de 500→700. Essa é a reprodução fiel do comportamento que vi na tela "Hover" do Figma — o nome destacado fica escuro e bold enquanto os outros desvanecem.

**4. Subtitle reveal — nome + membros**

O texto "Ana · 3 membros" que aparece ao lado do sobrenome usa uma **transição combinada**: `opacity 0→1` + `translateX(-8px → 0)` em **300ms ease**. O deslocamento horizontal de 8px cria um micro-slide que dá a sensação de que a informação "emerge" do sobrenome. Quando o hover sai, o texto volta pra `opacity: 0` e `translateX(-8px)`.

**5. FAB hover lift**

O botão "Novo cadastro" usa `translateY(-2px)` no hover com `box-shadow` que cresce de `0 4px 24px rgba(79,132,72,0.35)` pra `0 6px 32px rgba(79,132,72,0.45)`. A sombra crescendo junto com o lift cria ilusão de elevação física. Duração **200ms** — botões precisam de resposta instantânea.

**6. Circle buttons — background fill**

Os botões circulares (editar, fichas, fechar) no painel transitam o `background` de `transparent` pra `rgba(242,226,196,0.1)` no hover. O botão de fechar tem tratamento especial: ele vai pra `rgba(166,41,13,0.2)` — um tint vermelho sutil que comunica "ação destrutiva" sem ser agressivo. Tudo em **200ms ease**.

**7. Ficha rows — opacity**

As linhas da lista de fichas usam `transition: all 0.15s ease` na `opacity`. Fichas preenchidas ficam em `0.9`, pendentes em `0.5`, e qualquer uma vai pra `1.0` no hover. O **150ms** é a duração mais curta do sistema — itens de lista precisam de resposta ultra-rápida pra acompanhar o scroll do mouse.

**Detalhe de orquestração no fechamento:** quando o painel fecha, `panelVisible` vira `false` primeiro (dispara o slideOut), e um `setTimeout(350ms)` limpa o `selectedId` só depois que a animação termina. Se limpasse junto, o React desmontaria o componente instantaneamente e a animação seria cortada.