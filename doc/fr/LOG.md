# hdd-health-check — Journal

Ce document conserve les décisions historiques acceptées, les limites connues et l'historique des versions. Cette documentation décrit `v2.3.0`. Consultez GitHub Releases pour les versions étiquetées et les téléchargements. L’utilisateur indique que l’ancien code `v2.2.0` a été exécuté sur une machine réelle, sans préciser le périphérique, l’environnement ou la portée des tests. La notation révisée n’a été validée que par des simulations isolées, pas sur un vrai disque dur.

## Multi-language

[English](../LOG.md) | [简体中文](../zh_cn/LOG.md) | [繁體中文](../zh_tw/LOG.md) | [繁體中文（香港）](../zh_hk/LOG.md) | [हिन्दी](../hi/LOG.md) | [Español](../es/LOG.md) | [العربية](../ar/LOG.md) | **Français**

## Documentation

- Présentation du projet : [README](README.md)
- Conception : [DESIGN](DESIGN.md)
- Historique des versions : [LOG](LOG.md)
- Inventaire des composants tiers : [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Bugs

- [ ] L’utilisateur indique avoir testé v2.2.0 sur une machine réelle, sans préciser les appareils, l’environnement ni les tests effectués ; les tests d’exécution avec les droits root, d’installation de paquets et du comportement de systemd ne sont pas confirmés ; les vérifications de la version v1.0.0 précédente ne disposaient pas non plus d'un vrai disque dur ni de données SMART (syntaxe et aide seulement). Le script aurait été utilisé avant la normalisation initiale, ce qui ne remplace pas un test matériel contrôlé.
- [ ] La notation révisée par lots et le contrôle SMART/ATA/CRC final ne sont couverts que par des tests synthétiques, pas par une validation de ce code sur un vrai disque dur. La précision temporelle du journal d'autotest du micrologiciel et les reprises entre exécutions peuvent donner une couverture partielle/inconnue ; les anciennes erreurs ne peuvent pas être réattribuées automatiquement après réparation. Cette limite de validation matérielle reste signalée ; il reste recommandé de refaire les tests sur un disque dur autorisé.
- [ ] Les pondérations heuristiques de l'état des disques ne correspondent pas à des probabilités de panne calibrées ; la notation SAS/SCSI est moins éprouvée que la notation ATA et l'accès SMART direct via USB/RAID peut échouer. La gestion des températures propres aux fabricants est incomplète.
- [ ] Aucune sortie structurée JSON/CSV. Les données d'état v2.2 préexistantes non conformes sont rejetées ; des tests simulés isolés couvrent la détection et l'arrêt sécurisé des tâches avec un `TMPDIR` personnalisé ainsi que la progression de surface anormale.
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

### v2.3.0 — 2026-09-24

#### Changed

Cette version inclut l’intégration v2.2 jusque-là sans tag : résultats persistants par disque, historique des compteurs SMART, modules interactifs et par lots, analyses de surface reprenables en lecture seule, vérification de l’interface, tâches systemd transitoires facultatives et analyse plus sûre des états en tant que données. Elle ne préserve pas la compatibilité avec la CLI ou l’état v1 : `-w/--wait` est ignoré au lieu d’attendre ; sauvegardez l’état avant une mise à jour et restaurez l’état correspondant avec un ancien script. La notation révisée ci-dessous n’a été couverte que par des tests synthétiques, pas sur un vrai disque dur.

#### Fixed

- Reconnaît le premier enregistrement d’autotest SMART nouvellement terminé ; les enregistrements anciens, incomplets ou de type différent ne comptent pas comme un nouveau test terminé.
- Un lot complet associe sous un même marqueur les autotests SMART rapide, court et long, l'échantillonnage de vitesse et l'analyse de surface terminée ; il répète SMART/ATA/CRC à la fin. Seuls des résultats complets, valides et du même lot permettent un score global numérique. La réutilisation, l'interruption, l'expiration, l'ancien état sans marqueur et la vérification ultérieure de l'interface laissent les anciens résultats historiques/à revérifier et la catégorie globale partielle/inconnue ; consulter un rapport n'actualise pas la référence du contrôle rapide. La vérification d'interface consigne séparément si le problème est résolu ; elle ne réattribue pas les anciennes erreurs et ne rend pas actuel l'ancien lot. Un total ATA sans compteur antérieur conserve une pénalité de 5 points pour risque non résolu lors des contrôles et évaluations complètes ultérieurs, même si l'ancien état n'a pas de champ de risque. Une hausse retire 20 points ; la stabilité n'est ni une nouvelle erreur ni une preuve de réparation, et la vérification d'interface seule n'attribue pas les anciennes erreurs ATA à celle-ci. Les lectures lentes isolées invitent à revérifier les performances, pas à diagnostiquer des secteurs défectueux ; les échecs répétés de lecture de surface retirent toujours 40 points. Ces pondérations heuristiques ne sont pas des probabilités de panne.

### v2.2.0 — historique d’intégration sans tag (non publié)

#### Added

- Résultats persistants par disque, historique des compteurs SMART, notes de réparation et rapports ; menu interactif, mesures de lecture par échantillonnage, analyse reprenable de la latence de surface avec revérifications ciblées des blocs défectueux, vérification intégrale par `badblocks` en lecture seule, tests de lecture de l'interface sous charge et exécution facultative en arrière-plan via des unités systemd transitoires.

#### Changed

- Contrôles rapides exécutés par défaut en mode par lots, réutilisation des résultats selon leur durée de validité et `--rescan` ; `-r/--run` choisit les modules et `--status`/`--stop` gèrent une instance active. `-t short|long`, `-s` et `-b` correspondent à des modules ; `-w/--wait` est ignoré au lieu d'attendre. Ce nouveau comportement ne garantit pas la compatibilité de l'interface en ligne de commande v1.
- L’état et les journaux de l’hôte sont écrits séparément ; v2.2.0 ne préserve pas la compatibilité avec la CLI ni l’état de v1. Sauvegardez l’état de l’hôte avant toute mise à jour ; la restauration d’un ancien script exige aussi la restauration de la sauvegarde d’état correspondante. Les enregistrements d’état n’acceptent que les champs de données autorisés ; les enregistrements incompatibles peuvent être rejetés.

#### Fixed

- Rejet des enregistrements d’état exécutables ou mal formés et des entrées d’état sous forme de liens symboliques ; limitation des plans d’arrière-plan aux champs validés et au répertoire d’état privé, et validation des noms de périphériques et des chemins de journal et d’état pour limiter les manipulations de fichiers dangereuses.
- Un point de reprise d’analyse de surface invalide ou incomplet déclenche une nouvelle analyse au lieu de calculer la progression avec un dénominateur nul ; prise en charge d’un `TMPDIR` personnalisé pour détecter une instance active et l’arrêter sans risque.

L’utilisateur indique avoir testé v2.2.0 sur une machine réelle, sans préciser les appareils, l’environnement ni la portée des tests ; l’exécution en tant que root, l’installation de paquets et le comportement de systemd n’ont pas été confirmés indépendamment.


### v1.0.0 — 2026-08-08

#### Added

- Contrôle initial de l'état des disques durs selon 12 dimensions : données du périphérique et de l'interface, capacité SMART et verdict global, attributs ATA ou compteurs de défauts et d'erreurs SAS, journaux d'erreurs et d'autotests, lancement d'autotests courts et longs, durée de vie et charge, erreurs d'E/S du noyau, détection des montages et de la lecture seule, test de performance facultatif `hdparm` en lecture seule et analyse `badblocks`.
- Score heuristique de 0 à 100 et quatre catégories avec codes de sortie du processus 0/1/2/3, détection automatique de l'accès direct SMART, sélection interactive ou par lots des disques et proposition d'installation par `apt` de `smartmontools` lorsqu'il manque.
- Les documents complets de conception et d’utilisation de v1.0.0 restent disponibles dans le tag Git `v1.0.0` (par exemple, `git show v1.0.0:DESIGN.md` et `git show v1.0.0:README.zh.md`) ; les anciennes commandes v1 ne constituent pas les instructions actuelles.
