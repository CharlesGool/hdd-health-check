---
name: project-log-fr
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: "fr"
---

# hdd-health-check — Journal

Ce document conserve les décisions historiques acceptées, les limites connues et l’historique des versions. La version actuelle est `v4.1.0`. L’utilisateur indique avoir exécuté l’ancien code `v2.2.0` sur une machine réelle, sans préciser le périphérique, l’environnement ou la portée des tests. La notation révisée a fait l’objet de tests synthétiques et de vérifications Web sur un NAS Debian, mais d’aucune évaluation complète et contrôlée sur de vrais HDD.

## Multilingue

[English](../en/LOG.md) | [简体中文](../LOG.md) | [繁體中文(台灣)](../zh-TW/LOG.md) | [繁體中文(香港)](../zh-HK/LOG.md) | [हिन्दी](../hi/LOG.md) | [Español](../es/LOG.md) | [العربية](../ar/LOG.md) | **Français**

## Documentation

- Présentation du projet : [README](README.md)

- Justification de la conception : [DESIGN](DESIGN.md)

- Historique des versions : [LOG](LOG.md)

- Avis relatifs aux tiers : [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Dossiers

- [HISTORY](HISTORY.md)
- [CHANGELOG](CHANGELOG.md)

## Bogues

- [ ] L’utilisateur indique avoir testé v2.2.0 sur une machine réelle, sans préciser les appareils, l’environnement ni les tests effectués ; les tests d’exécution avec les droits root, d’installation de paquets et du comportement de systemd ne sont pas confirmés ; les vérifications de la version v1.0.0 précédente ne disposaient pas non plus d'un vrai disque dur ni de données SMART (syntaxe et aide seulement). Le script aurait été utilisé avant la normalisation initiale, ce qui ne remplace pas un test matériel contrôlé.
- [ ] La notation révisée par lots et le contrôle SMART/ATA/CRC final ne sont couverts que par des tests synthétiques, pas par une validation de ce code sur un vrai disque dur. La précision temporelle du journal d'autotest du micrologiciel et les reprises entre exécutions peuvent donner une couverture partielle/inconnue ; les anciennes erreurs ne peuvent pas être réattribuées automatiquement après réparation. Cette limite de validation matérielle reste signalée ; il reste recommandé de refaire les tests sur un disque dur autorisé.
- [ ] Les pondérations heuristiques de l'état des disques ne correspondent pas à des probabilités de panne calibrées ; la notation SAS/SCSI est moins éprouvée que la notation ATA et l'accès SMART direct via USB/RAID peut échouer. La gestion des températures propres aux fabricants est incomplète.
- [ ] Le service Web authentifié sur le réseau local et l’inventaire réel des disques ont été vérifiés sur un NAS Debian. Une évaluation complète sur de vrais HDD et la reprise après redémarrage restent à vérifier. Les anciens états v2.2 non conformes sont rejetés. L’export CSV n’est pas proposé.
- [x] Le soulignement de l’onglet actif dans le détail du disque dépassait l’onglet sélectionné sur une capture fournie par l’utilisateur après `test-771001c`. L’ancien indicateur agrandissait une ligne d’un pixel à partir d’une largeur de bouton entière. Il anime désormais directement la largeur fractionnaire mesurée du bouton ; les vérifications locales dans Chromium ont aligné l’indicateur sur les boutons SMART et Checks à faible largeur, y compris avec le zoom et en RTL. La configuration exacte du navigateur de la capture n’était pas disponible pour reproduire le problème.
- [ ] L’utilisateur signale un problème d’animation au retour du détail du disque et a demandé de le reporter. Le correctif du soulignement n’a pas modifié le code de cette animation.
- [x] La normalisation v1.0.0 a corrigé les instructions de clonage qui indiquaient le chemin inexistant `hdd-health-check-repo/main` ainsi que le mélange de caractères chinois traditionnels dans le README en chinois simplifié.

## Limitations

- Le service Debian installé conserve l’agencement hôte `/root/apps/hdd-health-check/web/` pour les mises à niveau ; le code source se trouve dans `src/web/` et le résultat généré dans `dist/web/`.

### Points d’entrée de compatibilité

Référence: `35f24e5`
Raison: Les commandes CLI et les instructions d’installation existantes invoquent le point d’entrée shell à la racine du dépôt ; l’implémentation se trouve maintenant sous `src/checker/`.
Limite de mise à jour: Conserver le répartiteur racine jusqu’à ce qu’une migration du chemin CLI, communiquée séparément, remplace la commande établie.

- `hdd-health-check.sh` -> `src/checker/hdd-health-check.sh`

## Décisions

| Décisions | Motifs |
| --- | --- |
| 2026-08-12 : Séparer le projet local en une copie de travail Git et des instantanés distincts ; rejeter une structure locale à plat. | Les instantanés des anciennes versions devaient être séparés du code suivi. Le nom `main/` alors en usage était uniquement local et ne faisait jamais partie de la copie GitHub ; des tags et des instantanés `git archive` étaient prévus. |
| 2026-08-13 : Renommer le répertoire local `main/` en `repo/` ; corriger les chemins d'installation, les en-têtes bilingues et `.gitignore` ; exclure les chemins du miroir privé et des instantanés du statut public. Rejeter la validation sans modification des documents périmés déjà indexés. | La copie GitHub place le script à sa racine. Les anciennes commandes auraient échoué immédiatement après le clonage ; les chemins locaux et les erreurs de traduction n'avaient pas leur place dans la documentation publique. |
| 2026-08-13 : Ne pas simuler un test de publication sur un vrai disque dur à partir du disque virtuel disponible ; signaler la portée réduite de la validation. | Aucun matériel SMART utilisable ni `smartmontools` n'était disponible ; installer des paquets pour analyser un disque virtuel n'aurait pas testé la logique pour disques durs. |
| 2026-08-13 : Remplacer l'historique public v1.0.0 par un unique commit propre utilisant une identité noreply et un tag annoté, tout en conservant l'historique initial dans une archive privée renommée ; rejeter le recours à un push forcé sur l'ancien dépôt public ou la conservation de son commit intermédiaire remplacé. | Le commit public précédent contenait une adresse électronique personnelle dans les métadonnées Git. Les copies et forks existants ne sont pas migrés automatiquement et on ne peut garantir l'effacement de toute exposition antérieure des caches. Il s'agit d'un fait historique, non d'une autorisation de réécrire à nouveau l'historique. |
| Intégration actuelle : Adopter le comportement v2.2.0 fourni sans garanties de compatibilité avec la v1 et conserver la licence MIT existante. | Le nouveau script ajoute un état persistant et des tâches facultatives en arrière-plan ; `-w` est ignoré. Cette intégration ne constitue ni une publication, ni un tag, ni une validation matérielle. |

## Transmission

[简体中文](../LOG.md#交接)
