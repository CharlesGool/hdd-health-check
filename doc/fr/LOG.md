# hdd-health-check — Journal

Ce document conserve les décisions historiques acceptées, les limites connues et l'historique des versions ; la v2.2.0 est intégrée localement mais n'a pas été publiée.

## Multi-language

[English](../LOG.md) | [简体中文](../zh_cn/LOG.md) | [繁體中文](../zh_tw/LOG.md) | [繁體中文（香港）](../zh_hk/LOG.md) | [हिन्दी](../hi/LOG.md) | [Español](../es/LOG.md) | [العربية](../ar/LOG.md) | **Français**

## Documentation

- Présentation du projet : [README](README.md)
- Conception : [DESIGN](DESIGN.md)
- Historique des versions : [LOG](LOG.md)
- Inventaire des composants tiers : [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Bugs

- [ ] Les tests d'intégration sur de vrais disques durs, avec droits root, installation de paquets et systemd restent à effectuer pour cette intégration ; les vérifications de la version v1.0.0 précédente ne disposaient pas non plus d'un vrai disque dur ni de données SMART (syntaxe et aide seulement). Le script aurait été utilisé avant la normalisation initiale, ce qui ne remplace pas un test matériel contrôlé.
- [ ] Les pondérations heuristiques de l'état des disques ne correspondent pas à des probabilités de panne calibrées ; la notation SAS/SCSI est moins éprouvée que la notation ATA et l'accès SMART direct via USB/RAID peut échouer. La gestion des températures propres aux fabricants est incomplète.
- [ ] Aucune sortie structurée JSON/CSV. Les données d'état v2.2 préexistantes non conformes sont rejetées ; des tests simulés isolés couvrent la détection et l'arrêt sécurisé des tâches avec un `TMPDIR` personnalisé ainsi que la progression de surface anormale ; le comportement réel de systemd et des disques durs reste non vérifié.
- [x] La normalisation v1.0.0 a corrigé les instructions de clonage qui indiquaient le chemin inexistant `hdd-health-check-repo/main` ainsi que le mélange de caractères chinois traditionnels dans le README en chinois simplifié.

## Decisions

| Décisions | Motifs |
| --- | --- |
| 2026-08-12 : Séparer le projet local en une copie de travail Git et des instantanés distincts ; rejeter une structure locale à plat. | Les instantanés des anciennes versions devaient être séparés du code suivi. Le nom `main/` alors en usage était uniquement local et ne faisait jamais partie de la copie GitHub ; des tags et des instantanés `git archive` étaient prévus. |
| 2026-08-13 : Renommer le répertoire local `main/` en `repo/` ; corriger les chemins d'installation, les en-têtes bilingues et `.gitignore` ; exclure les chemins du miroir privé et des instantanés du statut public. Rejeter la validation sans modification des documents périmés déjà indexés. | La copie GitHub place le script à sa racine. Les anciennes commandes auraient échoué immédiatement après le clonage ; les chemins locaux et les erreurs de traduction n'avaient pas leur place dans la documentation publique. |
| 2026-08-13 : Ne pas simuler un test de publication sur un vrai disque dur à partir du disque virtuel disponible ; signaler la portée réduite de la validation. | Aucun matériel SMART utilisable ni `smartmontools` n'était disponible ; installer des paquets pour analyser un disque virtuel n'aurait pas testé la logique pour disques durs. |
| 2026-08-13 : Remplacer l'historique public v1.0.0 par un unique commit propre utilisant une identité noreply et un tag annoté, tout en conservant l'historique initial dans une archive privée renommée ; rejeter le recours à un push forcé sur l'ancien dépôt public ou la conservation de son commit intermédiaire remplacé. | Le commit public précédent contenait une adresse électronique personnelle dans les métadonnées Git. Les copies et forks existants ne sont pas migrés automatiquement et on ne peut garantir l'effacement de toute exposition antérieure des caches. Il s'agit d'un fait historique, non d'une autorisation de réécrire à nouveau l'historique. |
| Intégration actuelle : Adopter le comportement v2.2.0 fourni sans garanties de compatibilité avec la v1 et conserver la licence MIT existante. | Le nouveau script ajoute un état persistant et des tâches facultatives en arrière-plan ; `-w` est ignoré. Cette intégration ne constitue ni une publication, ni un tag, ni une validation matérielle. |

## Changelog

### Unreleased — intégration v2.2.0 (sans date de publication)

#### Added

- Résultats persistants par disque, historique des compteurs SMART, notes de réparation et rapports ; menu interactif, mesures de lecture par échantillonnage, analyse reprenable de la latence de surface avec revérifications ciblées des blocs défectueux, vérification intégrale par `badblocks` en lecture seule, tests de lecture de l'interface sous charge et exécution facultative en arrière-plan via des unités systemd transitoires.

#### Changed

- Contrôles rapides exécutés par défaut en mode par lots, réutilisation des résultats selon leur durée de validité et `--rescan` ; `-r/--run` choisit les modules et `--status`/`--stop` gèrent une instance active. `-t short|long`, `-s` et `-b` correspondent à des modules ; `-w/--wait` est ignoré au lieu d'attendre. Ce nouveau comportement ne garantit pas la compatibilité de l'interface en ligne de commande v1.
- L'état et les journaux de l'hôte sont écrits séparément ; l'intégration v2.2.0 fournie restreint l'analyse des données d'état et des plans ainsi que la gestion des chemins et des périphériques. Aucun test d'intégration sur un vrai disque dur, avec droits root ou avec systemd n'a été effectué ici.

### v1.0.0 — 2026-08-08

#### Added

- Contrôle initial de l'état des disques durs selon 12 dimensions : données du périphérique et de l'interface, capacité SMART et verdict global, attributs ATA ou compteurs de défauts et d'erreurs SAS, journaux d'erreurs et d'autotests, lancement d'autotests courts et longs, durée de vie et charge, erreurs d'E/S du noyau, détection des montages et de la lecture seule, test de performance facultatif `hdparm` en lecture seule et analyse `badblocks`.
- Score heuristique de 0 à 100 et quatre catégories avec codes de sortie du processus 0/1/2/3, détection automatique de l'accès direct SMART, sélection interactive ou par lots des disques et proposition d'installation par `apt` de `smartmontools` lorsqu'il manque.
- Les documents complets de conception et d’utilisation de v1.0.0 restent disponibles dans le tag Git `v1.0.0` (par exemple, `git show v1.0.0:DESIGN.md` et `git show v1.0.0:README.zh.md`) ; les anciennes commandes v1 ne constituent pas les instructions actuelles.
