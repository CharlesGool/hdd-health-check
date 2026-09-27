---
name: project-log-fr
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: fr
---

# hdd-health-check — Journal

Ce document conserve les décisions historiques acceptées, les limites connues et l'historique des versions. Cette documentation décrit `v3.0.0`. Le tag source `v3.0.0` marque cette version majeure ; aucun GitHub Release n’est créé. L’utilisateur indique que l’ancien code `v2.2.0` a été exécuté sur une machine réelle, sans préciser le périphérique, l’environnement ou la portée des tests. La notation révisée n’a été validée que par des simulations isolées, pas sur un vrai disque dur.

## Multi-language

[English](../LOG.md) | [简体中文](../zh_cn/LOG.md) | [繁體中文](../zh_tw/LOG.md) | [繁體中文(香港)](../zh_hk/LOG.md) | [हिन्दी](../hi/LOG.md) | [Español](../es/LOG.md) | [العربية](../ar/LOG.md) | **Français**

- Cette étape ajoute le choix entre cinq groupes de disques et huit contrôles. La liste distingue SATA/NVMe et affiche la température relevée en arrière-plan ; les détails montrent le format déclaré par le périphérique. La compilation et les tests simulés des commandes, de la température et de la veille ont réussi ; la vérification sur le NAS reste à faire.

## Documentation

- Présentation du projet : [README](README.md)
- Conception : [DESIGN](DESIGN.md)
- Historique des versions : [LOG](LOG.md)
- Inventaire des composants tiers : [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Bugs

- [ ] L’utilisateur indique avoir testé v2.2.0 sur une machine réelle, sans préciser les appareils, l’environnement ni les tests effectués ; les tests d’exécution avec les droits root, d’installation de paquets et du comportement de systemd ne sont pas confirmés ; les vérifications de la version v1.0.0 précédente ne disposaient pas non plus d'un vrai disque dur ni de données SMART (syntaxe et aide seulement). Le script aurait été utilisé avant la normalisation initiale, ce qui ne remplace pas un test matériel contrôlé.
- [ ] La notation révisée par lots et le contrôle SMART/ATA/CRC final ne sont couverts que par des tests synthétiques, pas par une validation de ce code sur un vrai disque dur. La précision temporelle du journal d'autotest du micrologiciel et les reprises entre exécutions peuvent donner une couverture partielle/inconnue ; les anciennes erreurs ne peuvent pas être réattribuées automatiquement après réparation. Cette limite de validation matérielle reste signalée ; il reste recommandé de refaire les tests sur un disque dur autorisé.
- [ ] Les pondérations heuristiques de l'état des disques ne correspondent pas à des probabilités de panne calibrées ; la notation SAS/SCSI est moins éprouvée que la notation ATA et l'accès SMART direct via USB/RAID peut échouer. La gestion des températures propres aux fabricants est incomplète.
- [ ] Le service Web authentifié sur le réseau local et l’inventaire réel des disques ont été vérifiés sur un NAS Debian. Une évaluation complète sur de vrais HDD et la reprise après redémarrage restent à vérifier. Les anciens états v2.2 non conformes sont rejetés. L’export CSV n’est pas proposé.
- [x] La normalisation v1.0.0 a corrigé les instructions de clonage qui indiquaient le chemin inexistant `hdd-health-check-repo/main` ainsi que le mélange de caractères chinois traditionnels dans le README en chinois simplifié.

## Decisions

| Décisions | Motifs |
| --- | --- |
| 2026-08-12 : Séparer le projet local en une copie de travail Git et des instantanés distincts ; rejeter une structure locale à plat. | Les instantanés des anciennes versions devaient être séparés du code suivi. Le nom `main/` alors en usage était uniquement local et ne faisait jamais partie de la copie GitHub ; des tags et des instantanés `git archive` étaient prévus. |
| 2026-08-13 : Renommer le répertoire local `main/` en `repo/` ; corriger les chemins d'installation, les en-têtes bilingues et `.gitignore` ; exclure les chemins du miroir privé et des instantanés du statut public. Rejeter la validation sans modification des documents périmés déjà indexés. | La copie GitHub place le script à sa racine. Les anciennes commandes auraient échoué immédiatement après le clonage ; les chemins locaux et les erreurs de traduction n'avaient pas leur place dans la documentation publique. |
| 2026-08-13 : Ne pas simuler un test de publication sur un vrai disque dur à partir du disque virtuel disponible ; signaler la portée réduite de la validation. | Aucun matériel SMART utilisable ni `smartmontools` n'était disponible ; installer des paquets pour analyser un disque virtuel n'aurait pas testé la logique pour disques durs. |
| 2026-08-13 : Remplacer l'historique public v1.0.0 par un unique commit propre utilisant une identité noreply et un tag annoté, tout en conservant l'historique initial dans une archive privée renommée ; rejeter le recours à un push forcé sur l'ancien dépôt public ou la conservation de son commit intermédiaire remplacé. | Le commit public précédent contenait une adresse électronique personnelle dans les métadonnées Git. Les copies et forks existants ne sont pas migrés automatiquement et on ne peut garantir l'effacement de toute exposition antérieure des caches. Il s'agit d'un fait historique, non d'une autorisation de réécrire à nouveau l'historique. |
| Intégration actuelle : Adopter le comportement v2.2.0 fourni sans garanties de compatibilité avec la v1 et conserver la licence MIT existante. | Le nouveau script ajoute un état persistant et des tâches facultatives en arrière-plan ; `-w` est ignoré. Cette intégration ne constitue ni une publication, ni un tag, ni une validation matérielle. |

## Transmission - 2026-09-27

- Branche `main` : le tag annoté `v3.0.0` est publié sur le commit `434ac7d` ; le commit suivant consigne seulement la passation. Aucun GitHub Release ni interface précompilée n’a été créé.
- Terminé : une installation LAN authentifiée sur un NAS Debian a énuméré 13 disques ; le service a démarré et le navigateur a affiché disques, tâches, dialogues et mise en page adaptée. L’installateur a conservé le mot de passe et l’état de l’hôte. Le dernier contrôle de l’interface n’a lancé aucun scan ni redémarrage.
- Vérifications : types et compilation Vue, syntaxe shell, tests synthétiques du score et de l’état, authentification et tâches Web, lectures d’API et navigateur LAN ont réussi. L’évaluation complète sur un vrai HDD et la reprise après redémarrage restent non vérifiées. Les anciens avis sans preuve brute attendent une nouvelle vérification.
- Vérifications de version : la copie propre du tag et l’archive source ont été compilées et ont affiché `v3.0.0` ; la branche distante et le tag ont été vérifiés séparément. La copie locale `snapshots/v3.0.0` contient 87 fichiers source, sans `web/dist` précompilé.
- Suite : observer l’usage courant du NAS et une prochaine tâche Web terminée. Corriger plus tard les problèmes de structure du projet et de navigation multilingue. Aucune règle temporaire du projet trouvée.

## Historique des commits

Historique complet de la branche principale : `git log main --stat`. `HEAD` désigne ce commit de passation.

- 2026-09-27 | `HEAD` | `docs(handoff): record v3.0.0 tag publication` | `git show HEAD`
- 2026-09-27 | `434ac7d` | `chore(release): prepare v3.0.0 source tag` | `git show 434ac7d`
- 2026-09-27 | `65acbd0` | `docs(install): point source install to main` | `git show 65acbd0`
- 2026-09-27 | `b963e06` | `docs(handoff): confirm source publication` | `git show b963e06`
- 2026-09-27 | `88474d2` | `feat(web): publish LAN dashboard and docs` | `git show 88474d2`
- 2026-09-24 | `a46b392` | `feat(scoring): improve batch assessment for v2.3.0` | `git show a46b392`
- 2026-09-24 | `3126bcc` | `docs: clarify public source and reported real-machine testing` | `git show 3126bcc`
- 2026-09-24 | `7e69fdd` | `feat!: integrate unreleased v2.2.0 HDD health checks` | `git show 7e69fdd`
- 2026-08-13 | `7b18ca7` | `docs(status): record v1.0.0 release completion` | `git show 7b18ca7`
- 2026-08-13 | `4e01f52` | `chore(release): v1.0.0 (clean history)` | `git show 4e01f52`

## Changelog

### v3.0.0 — 2026-09-27

Cette version majeure ajoute au vérificateur de disques une interface Web persistante avec authentification et un installateur Debian. Le service Web a été vérifié sur un NAS Debian avec 13 disques ; une évaluation complète sur de vrais HDD et la reprise après redémarrage restent à vérifier. Le tag contient le code source ; aucun GitHub Release ni interface précompilée n’est publié.

Correctif NAS : pendant les autotests SMART, l’état Web n’interroge plus chaque disque en série ; la liste et l’état de la tâche se mettent à jour séparément. La température NVMe est colorée selon les seuils du périphérique et ne retire aucun point à elle seule. Les champs de problème vides et l’avertissement dû uniquement à une évaluation incomplète sont également corrigés.

La page principale permet une évaluation complète en un clic des disques SATA, HDD, SSD, NVMe ou de tous les disques. Le serveur sélectionne les disques énumérés et lance une seule tâche `full --rescan` en arrière-plan. Elle comprend les tests SMART courts/longs, des mesures de vitesse et une lecture complète ; elle peut durer des heures. Les scores SSD/NVMe emploient les règles HDD sans étalonnage distinct. La version et la vitesse SATA viennent de smartctl ; Linux sysfs fournit, si disponibles, la vitesse SATA ou la génération PCIe, la largeur et le débit du lien NVMe. Les valeurs absentes restent inconnues. Cliquez sur les heures de fonctionnement pour afficher aussi les années de 365 jours, jours et heures.

Cette mise à jour Web ajoute la connexion et la déconnexion sur la page, la liste IPv4 précise dans les paramètres, les détails des disques, les onglets SMART et contrôles, et le rendu Markdown des versions. La compilation locale et les tests de session, d’accès IP et de SMART simulé ont réussi ; la mise à jour du NAS et la vérification sur disque réel restent à faire.


Les baisses ponctuelles et les variations de vitesse moyenne des SSD/NVMe deviennent des informations de performance ; les vraies erreurs de lecture restent pénalisées et les anciens résultats sont réinterprétés. La liste des disques passe à trois, deux ou une colonne et la carte Disques du tableau de bord permet de s’y rendre directement.

- Les cartes des disques se réorganisent automatiquement sur une à quatre colonnes selon la largeur disponible, y compris lorsque le zoom du navigateur change, sans masquer les boutons ni créer de débordement horizontal.

#### Ajouté

- Service Web Python, interface Vue, contrôles programmés, commandes des tâches, historique SMART et unité systemd. L’installation autorise l’accès LAN avec authentification ; le mode manuel reste limité à la boucle locale.
- Les instantanés `--json` réutilisent la fonction de notation composite de Bash. `--no-install` bloque l’installation automatique des dépendances pour les tâches lancées depuis l’interface Web.

#### Validation

- La compilation et la vérification des types de l’interface, les tests shell d’état et de score, ainsi que les tests HTTP locaux d’authentification ont réussi. Le service LAN authentifié a été vérifié sur un NAS Debian avec 13 disques recensés; une évaluation complète sur de vrais HDD et la reprise après redémarrage restent à vérifier.

### v2.3.0 — 2026-09-24 (untagged source baseline)

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
