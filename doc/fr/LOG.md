---
name: project-log-fr
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: fr
---

# hdd-health-check — Journal

Ce document conserve les décisions historiques acceptées, les limites connues et l'historique des versions. Cette documentation décrit `v3.0.0`. Le tag source `v3.0.0` marque cette version majeure ; aucun GitHub Release n’est créé. L’utilisateur indique que l’ancien code `v2.2.0` a été exécuté sur une machine réelle, sans préciser le périphérique, l’environnement ou la portée des tests. La notation révisée n’a été validée que par des simulations isolées, pas sur un vrai disque dur.

## Multilingue

[English](../LOG.md) | [简体中文](../zh-CN/LOG.md) | [繁體中文(台灣)](../zh-TW/LOG.md) | [繁體中文(香港)](../zh-HK/LOG.md) | [हिन्दी](../hi/LOG.md) | [Español](../es/LOG.md) | [العربية](../ar/LOG.md) | **Français**

## Documentation

- Présentation du projet : [README](README.md)

- Justification de la conception : [DESIGN](DESIGN.md)

- Historique des versions : [LOG](LOG.md)

- Avis relatifs aux tiers : [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Bogues

- [ ] L’utilisateur indique avoir testé v2.2.0 sur une machine réelle, sans préciser les appareils, l’environnement ni les tests effectués ; les tests d’exécution avec les droits root, d’installation de paquets et du comportement de systemd ne sont pas confirmés ; les vérifications de la version v1.0.0 précédente ne disposaient pas non plus d'un vrai disque dur ni de données SMART (syntaxe et aide seulement). Le script aurait été utilisé avant la normalisation initiale, ce qui ne remplace pas un test matériel contrôlé.
- [ ] La notation révisée par lots et le contrôle SMART/ATA/CRC final ne sont couverts que par des tests synthétiques, pas par une validation de ce code sur un vrai disque dur. La précision temporelle du journal d'autotest du micrologiciel et les reprises entre exécutions peuvent donner une couverture partielle/inconnue ; les anciennes erreurs ne peuvent pas être réattribuées automatiquement après réparation. Cette limite de validation matérielle reste signalée ; il reste recommandé de refaire les tests sur un disque dur autorisé.
- [ ] Les pondérations heuristiques de l'état des disques ne correspondent pas à des probabilités de panne calibrées ; la notation SAS/SCSI est moins éprouvée que la notation ATA et l'accès SMART direct via USB/RAID peut échouer. La gestion des températures propres aux fabricants est incomplète.
- [ ] Le service Web authentifié sur le réseau local et l’inventaire réel des disques ont été vérifiés sur un NAS Debian. Une évaluation complète sur de vrais HDD et la reprise après redémarrage restent à vérifier. Les anciens états v2.2 non conformes sont rejetés. L’export CSV n’est pas proposé.
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

## Passation

2026-09-28. Branche `feat/standards-alignment` ; cet arbre de travail local n’a pas encore été validé. Aucune règle temporaire du projet n’a été trouvée.

- Terminé : le code source a été réorganisé sous `src/checker/` et `src/web/`, la sortie Web générée déplacée vers `dist/web/`, le point d’entrée CLI de compatibilité à la racine conservé, les chemins de l’installateur et des tests actualisés, et les noms des répertoires de langues ainsi que la navigation documentaire normalisés. L’installation depuis les sources copie toujours les fichiers dans la structure de service Debian existante. L’interface propose désormais huit couleurs d’accent et les modes clair/sombre dans Paramètres, les conserve séparément et utilise un véritable lien Changelog dans la navigation supérieure.
- Sécurité : une page Security Settings dédiée a été ajoutée, avec une vérification du mot de passe administrateur valable cinq minutes et imposée par le serveur. Cette vérification renouvelle la session ; une session admise par IP seulement ne peut ni lire ni modifier la liste d’autorisation ou le mot de passe. Pendant cette période, le changement de mot de passe ne demande que le nouveau mot de passe et sa confirmation, et invalide toutes les sessions. L’admission IP dispose d’un interrupteur, n’accepte que les adresses exactes RFC 1918 IPv4 ou ULA IPv6, rejette les anciennes entrées interdites, utilise le pair de la connexion plutôt que les en-têtes de transfert fournis par le client, et contrôle le Host/Origin d’origine ainsi qu’un en-tête de requête du même domaine pour les modifications.
- Confidentialité et version : les réponses snapshot et SMART masquent désormais les numéros de série ; une requête authentifiée de révélation ne récupère le numéro complet qu’après une action explicite de l’utilisateur, et la vue l’efface lorsqu’il est masqué ou qu’elle se ferme. Le lien de version se trouve à côté du nom du projet et ouvre Changelog ; une compilation sans tag utilise le marqueur `test-<sha>` et expose la même valeur sur `/api/build`.
- Comportement non publié: L’évaluation complète SSD/NVMe exécute désormais le contrôle SMART rapide, les autotests court et long et une lecture intégrale en lecture seule, sans échantillonnage de vitesse. Un lot complet sans anomalie obtient 100 points ; les lectures lentes seules ne retirent aucun point. Les choix de contrôle groupé suivent les types de disques sélectionnés. Les valeurs de capacité et de données écrites sur SSD passent entre unités décimales et binaires ; un HDD en veille peut être réveillé individuellement depuis ses détails SMART. Les tests simulés ont réussi ; aucune évaluation intégrale de disques réels n’a été lancée pour cette mise à jour.
- Vérifications : le contrôle des types Vue et la compilation de production ont réussi. Tous les tests shell et Python Web ont réussi, y compris l’admission IP, l’expiration des droits, le renouvellement de session, le changement de mot de passe et la révélation et le masquage des numéros de série. Le contrôle des thèmes a validé les huit couleurs d’accent dans les deux modes. Les contrôles du multilinguisme, du format documentaire (zéro erreur, huit avertissements), des liens locaux et de la structure du projet ont réussi après le déplacement des artefacts du navigateur hors de la racine des sources. Chromium local a montré Security Settings et les réglages d’apparence adaptatifs en mode sombre à 390 px sans débordement horizontal ; l’accès direct à Changelog a affiché la section v3.0.0 en premier. L’environnement de navigateur isolé a renvoyé les réponses 503 attendues pour l’état des disques, car il ne dispose pas du processus de vérification.
- Reste à faire : examiner le diff final et tester le parcours de sécurité actualisé sur le NAS après autorisation du déploiement. Le point d’entrée de compatibilité à la racine figure avec sa référence antérieure au déplacement dans Limitations. Aucune mise à niveau du NAS, opération sur un disque réel ni vérification après redémarrage n’a été effectuée dans cet arbre de travail ; ces changements non validés n’ont pas été publiés.
- Prochaine étape : examiner la branche et décider de son déploiement sur le NAS pour vérifier Security Settings en conditions réelles.

## Bases historiques du code source

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

## Historique des modifications

### v3.0.0 — 2026-09-27

Cette version majeure ajoute au vérificateur de disques une interface Web persistante et authentifiée ainsi qu’un installateur Debian. Le service a été vérifié sur un NAS Debian avec 13 disques énumérés; une évaluation complète de vrais HDD et la reprise après redémarrage restent à vérifier. Le tag contient le code source; aucun GitHub Release ni interface précompilée n’a été publié.

#### Corrections après suivi du NAS

- Les cartes de disques s’organisent en une à quatre colonnes selon la largeur disponible, y compris avec le zoom du navigateur, en gardant les commandes visibles sans débordement horizontal.
- Les baisses ponctuelles de vitesse et les variations de moyenne des SSD/NVMe restent des informations de performance; les vraies erreurs de lecture continuent à retirer des points et les anciens résultats sont réinterprétés. La liste utilise des colonnes adaptatives et la carte du tableau de bord y mène.
- Pendant un autotest SMART de tous les disques, l’état Web lit l’enregistrement d’exécution et la fin récente du journal au lieu d’interroger chaque disque. La liste est mise à jour séparément et réutilise son dernier instantané réussi durant une lecture en arrière-plan.
- La température NVMe est colorée séparément de la notation. Les seuils du contrôleur sont utilisés s’ils existent, sinon les bandes visuelles 70/80 °C; la température seule ne retire aucun point. Les évaluations enregistrées restent inchangées jusqu’au contrôle suivant.
- Les champs enregistrés vides sont décodés correctement, et une vérification propre avec couverture partielle ne donne pas un code de sortie d’avertissement.
- Les quatre catégories du tableau de bord ont chacune une page et l’évaluation en un clic reste sur la page des disques.

#### Ajouté

- Service Web Python, interface Vue, contrôles rapides programmés, commandes de tâches, historique SMART et unité de déploiement. L’installateur configure l’accès LAN authentifié; le mode manuel reste limité à loopback.
- Connexion et déconnexion Web, liste IPv4 précise gérée par les visiteurs authentifiés dans Paramètres, cartes avec données matérielles et onglets SMART et contrôles distincts. Les changements sont rendus en Markdown.
- Version et vitesse négociée SATA, ou génération, largeur et débit PCIe NVMe lorsqu’ils sont connus; durée de fonctionnement affichable sous deux formes; lots pour SATA, HDD, SSD, NVMe ou tous avec les huit modules. La liste montre bus, support et température mise en cache; le détail SMART ne montre le format que lorsqu’il est rapporté. Seule une évaluation complète produit un score actuel; la notation SSD/NVMe n’est pas calibrée à part.
- Installateur Debian vérifiant les prérequis, installant les paquets apt manquants, déployant l’interface compilée et le service, et conservant une copie de retour arrière lors des mises à jour.
- Les instantanés `--json` réutilisent la notation composite Bash. `--no-install` empêche les installations automatiques pour les tâches Web. Les lancements conservent les états accepté, en cours et final; la carte Attention filtre les disques et les détails montrent les déductions, avec explication pour les anciens résultats sans cause.

#### Validation

- La compilation, les types UI, les tests shell de notation et d’état et les contrôles HTTP locaux d’authentification ont réussi. Le service LAN authentifié a été installé et vérifié sur un NAS Debian avec 13 disques. L’évaluation complète sur de vrais HDD et la reprise après redémarrage restent à vérifier.

### v1.0.0 — 2026-08-08

#### Added

- Contrôle initial de l'état des disques durs selon 12 dimensions : données du périphérique et de l'interface, capacité SMART et verdict global, attributs ATA ou compteurs de défauts et d'erreurs SAS, journaux d'erreurs et d'autotests, lancement d'autotests courts et longs, durée de vie et charge, erreurs d'E/S du noyau, détection des montages et de la lecture seule, test de performance facultatif `hdparm` en lecture seule et analyse `badblocks`.
- Score heuristique de 0 à 100 et quatre catégories avec codes de sortie du processus 0/1/2/3, détection automatique de l'accès direct SMART, sélection interactive ou par lots des disques et proposition d'installation par `apt` de `smartmontools` lorsqu'il manque.
- Les documents complets de conception et d’utilisation de v1.0.0 restent disponibles dans le tag Git `v1.0.0` (par exemple, `git show v1.0.0:DESIGN.md` et `git show v1.0.0:README.zh.md`) ; les anciennes commandes v1 ne constituent pas les instructions actuelles.

## Historique des commits

Historique complet de la branche principale : `git log main --stat`. `HEAD` désigne ce commit de passation.

- 2026-09-28 | `35f24e5` | `docs(handoff): record NAS Web update verification` | `git show 35f24e5`
- 2026-09-28 | `c60d602` | `fix(web): defer option watcher until labels initialize` | `git show c60d602`
- 2026-09-28 | `261247f` | `fix(web): initialize assessment scope before options` | `git show 261247f`
- 2026-09-28 | `f882a8d` | `docs: record SSD full assessment behavior` | `git show f882a8d`
- 2026-09-28 | `bfed16f` | `feat: assess SSDs with full read-only scan` | `git show bfed16f`
- 2026-09-27 | `97f775f` | `docs(handoff): record v3.0.0 tag publication` | `git show 97f775f`
- 2026-09-27 | `434ac7d` | `chore(release): prepare v3.0.0 source tag` | `git show 434ac7d`
- 2026-09-27 | `65acbd0` | `docs(install): point source install to main` | `git show 65acbd0`
- 2026-09-27 | `b963e06` | `docs(handoff): confirm source publication` | `git show b963e06`
- 2026-09-27 | `88474d2` | `feat(web): publish LAN dashboard and docs` | `git show 88474d2`
- 2026-09-24 | `a46b392` | `feat(scoring): improve batch assessment for v2.3.0` | `git show a46b392`
- 2026-09-24 | `3126bcc` | `docs: clarify public source and reported real-machine testing` | `git show 3126bcc`
- 2026-09-24 | `7e69fdd` | `feat!: integrate unreleased v2.2.0 HDD health checks` | `git show 7e69fdd`
- 2026-08-13 | `7b18ca7` | `docs(status): record v1.0.0 release completion` | `git show 7b18ca7`
- 2026-08-13 | `4e01f52` | `chore(release): v1.0.0 (clean history)` | `git show 4e01f52`
