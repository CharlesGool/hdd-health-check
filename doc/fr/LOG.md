---
name: project-log-fr
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: fr
---

# hdd-health-check — Journal

Ce document conserve les décisions historiques acceptées, les limites connues et l’historique des versions. La version majeure actuelle est `v4.0.0`. L’utilisateur indique avoir exécuté l’ancien code `v2.2.0` sur une machine réelle, sans préciser le périphérique, l’environnement ou la portée des tests. La notation révisée a fait l’objet de tests synthétiques et de vérifications Web sur un NAS Debian, mais d’aucune évaluation complète et contrôlée sur de vrais HDD.

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

2026-09-28. Branche `feat/standards-alignment`; la modification de normalisation vérifiée est validée localement. Aucune règle temporaire du projet n’a été trouvée.

- Suivi de l’installateur sur le NAS: le premier déploiement de `test-bf14ed5` a démarré le service, mais son contrôle de santé a reçu HTTP 403 parce que l’en-tête `X-HDD-CSRF` manquait. Le chemin d’erreur explicite `die` n’effectuait pas non plus le retour arrière; le service est resté actif et l’ancienne application disponible. Le commit `cd7d69b` a corrigé les deux problèmes. Une nouvelle installation de `test-cd7d69b` a passé le contrôle; le service est actif et activé sur `0.0.0.0:8765`. Les sauvegardes précédentes de l’application et de l’unité ont été conservées; le mot de passe Web correspondait à la sauvegarde précédente, et les répertoires `/var/lib/hdd-health` et `/var/log/disk-health` ont été conservés.
- Terminé: code déplacé vers `src/checker/` et `src/web/`, sortie générée vers `dist/web/`, point d’entrée CLI compatible conservé et chemins d’installation et de tests mis à jour. Les répertoires de langues et la navigation ont été normalisés. L’interface offre huit couleurs d’accent et les modes clair/sombre conservés séparément; la version ouvre Changelog.
- Sécurité: page distincte avec vérification du mot de passe administrateur valable cinq minutes et imposée par le serveur. La vérification renouvelle la session; une session admise seulement par IP ne peut ni lire ni modifier la liste d’autorisation ou le mot de passe. Le changement de mot de passe invalide toutes les sessions. L’admission IP dispose d’un interrupteur et n’accepte que les adresses exactes RFC 1918 IPv4 ou ULA IPv6; elle utilise le pair de la connexion et impose les contrôles Host/Origin ainsi qu’un en-tête du même domaine pour toute modification.
- Confidentialité et version: les réponses snapshot et SMART masquent les numéros de série; une requête authentifiée ne les révèle qu’après une action explicite et la vue les masque de nouveau à la fermeture. Les compilations sans tag utilisent `test-<sha>` et `/api/build` affiche le même identifiant.
- Comportement inclus: l’évaluation complète SSD/NVMe exécute SMART rapide, autotests court et long et analyse intégrale en lecture seule, sans échantillonnage de vitesse. Un lot complet sans anomalie obtient 100 points; les lectures lentes seules ne retirent aucun point. Les choix du lot dépendent des disques sélectionnés. Capacité et données écrites alternent entre unités décimales et binaires; un HDD en veille peut être réveillé individuellement.
- Vérifications: les tests Shell et Python, les contrôles de types et compilation Vue, les thèmes, la structure, le format documentaire, les liens locaux et le multilinguisme ont réussi. La syntaxe Shell, la compilation Python et `git diff --check` ont aussi réussi. La revue finale a attribué `test-archive-<package version>` aux archives source sans métadonnées Git. Chromium local a affiché Security Settings et les paramètres d’apparence en mode sombre à 390 px sans débordement horizontal; la navigation directe vers Changelog affichait d’abord v3.0.0. L’environnement isolé du navigateur a renvoyé le HTTP 503 attendu pour l’état des disques faute de processus vérificateur.
- NAS: `/api/build` correspondait à `test-cd7d69b`. Connexion, refus de l’accès non authentifié, vérification administrateur, renouvellement de session, lecture protégée de la liste d’autorisation et masquage des numéros de série de 13 disques ont réussi. La page Security Settings et le favicon ont répondu HTTP 200 sur le réseau local; les API ordinaires et protégées ont répondu 401 sans authentification. Chromium authentifié a affiché les commandes IP enregistrées et le formulaire de mot de passe à 390 px sans débordement. La session du navigateur a été fermée et le fichier local temporaire du mot de passe supprimé. Aucune analyse, modification de mot de passe ni redémarrage n’a été effectué. Cette installation de test n’est pas une version formelle.
- Restant: observer la reprise du service après un redémarrage et effectuer une évaluation complète et contrôlée sur de vrais HDD. La branche locale n’est pas encore publiée. Le point d’entrée compatible à la racine figure sous Limitations avec sa référence antérieure au déplacement.
- Préparation de la version: `v4.0.0` est la prochaine version formelle. Changelog couvre les commits après `v3.0.0`. Le commit de version, le tag, GitHub Release, l’instantané et la synchronisation Notion restent à faire. Le NAS conserve `test-cd7d69b` jusqu’à un autre déploiement.
- Récupération des traductions: les sept traductions des documents principaux sont en retard sur les mises à jour anglaises de Handoff et Commit History; `check-doc-difference.py` ne dispose donc pas d’une référence structurellement synchronisée pour cette version. Les documents concernés sont intégralement resynchronisés avec la source anglaise actuelle selon la règle de récupération documentée; les sept langues et la navigation protégée restent requises.
- Prochaine étape: terminer les traductions et les contrôles de publication, puis publier `v4.0.0` depuis `main`; planifier séparément le redémarrage et l’évaluation des HDD.

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

### v4.0.0 — 2026-09-28

Cette version majeure met à jour le contrôleur Web local, son modèle de sécurité et l’organisation du code source. La compilation de test authentifiée a été vérifiée sur un NAS Debian avec 13 disques recensés. Une évaluation complète sur de vrais HDD et la reprise du service après redémarrage de l’hôte restent à vérifier.

#### Ajouté

- Les évaluations complètes SSD/NVMe exécutent SMART rapide, les autotests court et long ainsi qu’une analyse intégrale en lecture seule, sans échantillonnage de vitesse réservé aux HDD. Un lot complet sans anomalie obtient 100 points selon l’heuristique existante; les lectures lentes seules ne retirent aucun point, mais les erreurs de lecture et les constatations SMART peuvent encore le faire. Les commandes des lots mixtes proposent l’ensemble des contrôles pris en charge et excluent les SSD des modules réservés aux HDD.
- L’historique des tâches conserve les exécutions Web terminées, arrêtées et échouées séparément du dernier résultat par disque et des tendances des compteurs SMART. Le détail d’un disque peut mettre en veille un HDD SATA admissible ou réveiller individuellement un HDD endormi.
- Les paramètres proposent huit couleurs d’accent et les modes clair/sombre. La version près du nom du projet ouvre Changelog, et `/api/build` indique le même identifiant intégré. Les numéros de série restent masqués dans les réponses ordinaires et ne sont obtenus qu’après une action authentifiée de révélation.

#### Modifié

- Security Settings dispose d’une route distincte avec une vérification du mot de passe administrateur valable cinq minutes et imposée par le serveur. La vérification renouvelle la session; pendant cette période, le changement de mot de passe exige la nouvelle valeur et sa confirmation puis invalide toutes les sessions. L’admission IP sans mot de passe dispose d’un interrupteur et n’accepte que des adresses exactes RFC 1918 IPv4 ou ULA IPv6. Elle ne permet pas de lire ni de modifier les paramètres de sécurité. Les requêtes qui modifient des données exigent un en-tête du même domaine; les en-têtes de transfert fournis par le client ne déterminent pas l’adresse du pair.
- Le code source se trouve dans `src/checker/` et `src/web/`, avec les fichiers générés de l’interface dans `dist/web/`; le point d’entrée CLI à la racine et l’agencement installé sur le NAS restent compatibles. Les répertoires de langues utilisent les noms BCP-47. La vue des disques s’adapte à la largeur disponible et les quatre fonctions du tableau de bord disposent de pages dédiées.

#### Corrigé

- L’état des tâches reste réactif pendant les autotests de tous les disques, affiche distinctement les résultats SMART courts et longs et conserve des reçus historiques séparés. Les bandes de température NVMe sont corrigées et la température seule ou les variations de vitesse SSD ne réduisent pas le score. Les contrôles propres avec couverture partielle ne renvoient plus d’avertissement pour cette seule raison.
- L’installateur Debian inclut désormais l’en-tête requis dans son contrôle de santé authentifié et effectue un retour arrière si une erreur explicite survient après le début du remplacement des fichiers.

#### Validation

- Les tests Shell et Python, les contrôles de types Vue et la compilation de production, les contrôles documentaires et structurels et les essais locaux dans un navigateur ont réussi. Le déploiement de test sur NAS a passé les contrôles d’API authentifiée et de Security Settings dans le navigateur, y compris le masquage des numéros de série et l’affichage à 390 px sans débordement horizontal. Aucune analyse de disque, modification de mot de passe ni redémarrage n’a été réalisé pendant la préparation de cette version; le score de santé n’est pas une probabilité de panne calibrée.

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

Historique complet de la branche principale: `git log main --stat`. L’entrée `HEAD` désigne ce commit de passation.

- 2026-09-28 | intended | `chore(release): prepare v4.0.0` | this commit
- 2026-09-28 | `ebf6e39` | `docs(handoff): record NAS browser verification` | `git show ebf6e39`
- 2026-09-28 | `0b5f053` | `docs(handoff): record NAS installer and security verification` | `git show 0b5f053`
- 2026-09-28 | `cd7d69b` | `fix(deploy): verify authenticated service with CSRF header` | `git show cd7d69b`
- 2026-09-28 | `bf14ed5` | `feat(web): align project layout and security settings` | `git show bf14ed5`
- 2026-09-28 | `35f24e5` | `docs(handoff): record NAS Web update verification` | `git show 35f24e5`
- 2026-09-28 | `a6086ff` | `feat(web): unify history and add per-disk standby` | `git show a6086ff`
- 2026-09-28 | `f5f5dc7` | `docs(handoff): record SSD assessment deployment` | `git show f5f5dc7`
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
