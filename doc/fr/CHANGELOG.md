---
name: project-changelog-fr
description: 变更日志
metadata:
  version: "1.0.0"
  lang: "fr"
---

# 变更日志

## 多语言

[简体中文](../../README.md) | [English](../en/CHANGELOG.md) | [Español](../es/CHANGELOG.md)

## 文档

- 项目概览: [README](../../README.md)

- 设计思路: [DESIGN](DESIGN.md)

- 项目状态: [LOG](LOG.md)
- 历史记录: [HISTORY](HISTORY.md)
- 变更日志: [CHANGELOG](CHANGELOG.md)

- 第三方声明: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Historique des modifications

### v4.1.0 — 2026-09-29

Cette version actualise l’interface Web et les détails des disques. La précédente compilation de test a été vérifiée sur un NAS Debian recensant 13 disques ; la compilation officielle est vérifiée séparément avant publication.

#### Ajouté

- Les cartes des disques ouvrent des pages de détail complètes avec fil d’Ariane, navigation Retour, contrôles par disque, attributs SMART et explications. Les numéros de série restent masqués jusqu’à une révélation authentifiée ; la copie n’est possible qu’après cette révélation. Les détails SSD/NVMe affichent les lectures et écritures de l’hôte lorsque le périphérique fournit des compteurs aux unités connues.
- L’interface Web suit la référence visuelle commune pour la connexion, le Dashboard, les pages de fonction, les paramètres, la sécurité et l’historique des modifications. Elle ajoute des mises en page adaptatives, des commandes et icônes localisées, ainsi que des animations facultatives pour les pages et leur redimensionnement.

#### Modifié

- L’historique des modifications s’ouvre depuis l’écran de connexion avant authentification et affiche la version correspondante de la compilation. Les commandes du détail du disque utilisent un indicateur d’onglet mesuré ; un nouveau retour de copie relance son délai de disparition.
- L’unité de service du NAS maintient `/var/lib/hdd-health` au mode 700 après redémarrage. Lors des mises à jour, l’installateur continue de conserver l’application, l’unité et le mot de passe Web précédents.

#### Corrigé

- La largeur et la position du soulignement actif des onglets SMART et Checks ont été corrigées aux faibles largeurs et aux niveaux de zoom testés, y compris en RTL. Le retour visuel du détail du disque, l’explication des compteurs SMART et le nettoyage d’une animation de navigation interrompue ont été affinés.

#### Problèmes connus et validation

- L’animation au retour du détail du disque présente un problème signalé par l’utilisateur, dont la correction reste reportée. Une évaluation complète sur de vrais HDD, les animations dans de vrais navigateurs mobiles et la reprise du service après redémarrage de l’hôte restent à vérifier. Le score de santé est heuristique et ne représente pas une probabilité de panne calibrée.
- Le contrôle des types Vue, la compilation de production, les contrôles du projet et des traductions ainsi que les vérifications locales de mise en page dans Chromium ont réussi pour la compilation de test. Le déploiement de test sur NAS a passé les contrôles d’API authentifiée pour la version et la liste des disques, ainsi que les contrôles des deux soulignements dans le navigateur ; aucune analyse de disque, modification du mot de passe ou redémarrage n’a été effectué.

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

### v2.3.0 — 2026-09-24

#### Changed

Cette version inclut l’intégration v2.2 jusque-là sans tag : résultats persistants par disque, historique des compteurs SMART, modules interactifs et par lots, analyses de surface reprenables en lecture seule, vérification de l’interface, tâches systemd transitoires facultatives et analyse plus sûre des états en tant que données. Elle ne préserve pas la compatibilité avec la CLI ou l’état v1 : `-w/--wait` est ignoré au lieu d’attendre ; sauvegardez l’état avant une mise à jour et restaurez l’état correspondant avec un ancien script. La notation révisée ci-dessous n’a été couverte que par des tests synthétiques, pas sur un vrai disque dur.

#### Fixed

- Reconnaît le premier enregistrement d’autotest SMART nouvellement terminé ; les enregistrements anciens, incomplets ou de type différent ne comptent pas comme un nouveau test terminé.
- Un lot complet associe sous un même marqueur les autotests SMART rapide, court et long, l'échantillonnage de vitesse et l'analyse de surface terminée ; il répète SMART/ATA/CRC à la fin. Seuls des résultats complets, valides et du même lot permettent un score global numérique. La réutilisation, l'interruption, l'expiration, l'ancien état sans marqueur et la vérification ultérieure de l'interface laissent les anciens résultats historiques/à revérifier et la catégorie globale partielle/inconnue ; consulter un rapport n'actualise pas la référence du contrôle rapide. La vérification d'interface consigne séparément si le problème est résolu ; elle ne réattribue pas les anciennes erreurs et ne rend pas actuel l'ancien lot. Un total ATA sans compteur antérieur conserve une pénalité de 5 points pour risque non résolu lors des contrôles et évaluations complètes ultérieurs, même si l'ancien état n'a pas de champ de risque. Une hausse retire 20 points ; la stabilité n'est ni une nouvelle erreur ni une preuve de réparation, et la vérification d'interface seule n'attribue pas les anciennes erreurs ATA à celle-ci. Les lectures lentes isolées invitent à revérifier les performances, pas à diagnostiquer des secteurs défectueux ; les échecs répétés de lecture de surface retirent toujours 40 points. Ces pondérations heuristiques ne sont pas des probabilités de panne.

### v1.0.0 — 2026-08-08

#### Added

- Contrôle initial de l'état des disques durs selon 12 dimensions : données du périphérique et de l'interface, capacité SMART et verdict global, attributs ATA ou compteurs de défauts et d'erreurs SAS, journaux d'erreurs et d'autotests, lancement d'autotests courts et longs, durée de vie et charge, erreurs d'E/S du noyau, détection des montages et de la lecture seule, test de performance facultatif `hdparm` en lecture seule et analyse `badblocks`.
- Score heuristique de 0 à 100 et quatre catégories avec codes de sortie du processus 0/1/2/3, détection automatique de l'accès direct SMART, sélection interactive ou par lots des disques et proposition d'installation par `apt` de `smartmontools` lorsqu'il manque.
- Les documents complets de conception et d’utilisation de v1.0.0 restent disponibles dans le tag Git `v1.0.0` (par exemple, `git show v1.0.0:DESIGN.md` et `git show v1.0.0:README.zh.md`) ; les anciennes commandes v1 ne constituent pas les instructions actuelles.
