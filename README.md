# VHP — Apprendre la prévention incendie

Module de **formation** à la prévention incendie de la Zone de secours 4 (Vesdre-Hoëgne & Plateau).
Projet **autonome**, séparé de l'outil de visite/rapport (`VHP-outil-prevention`) : son propre service
worker et son propre cache → les mises à jour de l'outil ne l'interrompent plus, et il peut être
installé/partagé seul (PWA).

## Contenu
- `index.html` — l'application (cours + Anki + parcours guidé), données du cours **en JSON inline**.
- `cours-img/` — les images des pages de cours (mises en cache au runtime).
- `fonts/` — police Inter (hors-ligne).
- `icons/` — icônes PWA.
- `sw.js` — service worker dédié (cache `vhp-apprendre-v1`).
- `manifest.webmanifest` — manifeste PWA installable.

## Lancer en local
Servir le dossier en HTTP (le service worker est désactivé sur `localhost`, live-reload actif).

## Déployer
Pousser sur un dépôt + activer GitHub Pages (branche `main`, racine). Le lien « Quitter » renvoie vers
l'outil de prévention (`https://portugaeldante.github.io/VHP-outil-prevention/`).

> Hors-ligne : la page est en *network-first* ; les images de cours se mettent en cache au fil de la lecture.
