# ADR-015: Uso Mandatório do Padrão Command para Ações de UI

**Data:** 2026-03-13
**Status:** Aceito

## Contexto

O gerenciamento manual de estados de "carregamento" (busy) e "erro" nos ViewModels gerava muito boilerplate e inconsistência visual entre telas.

## Decisão

Implementar e usar obrigatoriamente a classe `Command` (do package `core`) para qualquer operação assíncrona iniciada pela UI.

## Consequências

- ViewModels ficam mais limpos (menos flags booleanas).
- UI reage de forma consistente via `ListenableBuilder` aos estados do comando.
- Redução drástica de bugs de concorrência (Commands bloqueiam re-execução automática enquanto rodam).

## Superseded by

Nenhum.
