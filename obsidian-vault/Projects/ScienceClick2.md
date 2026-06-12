# ScienceClick2

## Percorso

```text
/home/fausto/Software/ScienceClick2
```

## Descrizione

ScienceClick2 è una web app educativa Next.js / React / TypeScript per creare scene visuali etichettate e far esercitare gli studenti tramite drag-and-drop delle etichette sulle zone corrette dell'immagine.

## Convenzioni agenti

Leggere sempre:

```text
/home/fausto/Software/ScienceClick2/PROJECT.md
```

Punti importanti:

- per lavori sostanziali usare git worktree task-specifici;
- verifiche preferite: `npx tsc --noEmit`, `npm run lint`, `npm run build` quando fattibile;
- il servizio locale `butler.service` avvia l'app tramite `service_start.sh`.

## Preferenza orchestrazione Hermes

Fausto vuole Hermes come orchestratore su ScienceClick2:

1. Antigravity CLI implementa usando la skill/procedura `create-scene` quando pertinente.
2. Claude CLI valuta/revisiona.
3. Hermes riavvia `butler.service`.
4. Verificare orchestrazione e servizio, non fare review profonda del codice se non richiesta.

## Servizio locale

Vedi [[../System/Services#butlerservice]].
