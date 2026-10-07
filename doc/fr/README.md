# hdd-health-check

Cet outil Bash exécuté avec les droits root évalue la santé des HDD sous Debian/Ubuntu avec les données SMART et des contrôles en lecture seule. La version `v4.1.0` comprend le vérificateur et l’interface Web locale facultative, avec le code source et une archive Web Debian précompilée sur GitHub. Le service Web a été vérifié sur un NAS Debian avec un inventaire réel des disques et des paramètres de sécurité authentifiés, mais une évaluation complète sur de vrais HDD et la reprise après redémarrage de l’hôte restent à vérifier.

La durée de fonctionnement est une donnée d’usage et ne réduit pas seule le score de santé. Une propriété ATA proche du seuil ne déclenche une alerte que si le compteur brut d’erreurs est non nul. Les anciens résultats sans cette preuve restent en attente de vérification sans déduction. Les cartes de surveillance affichent la cause enregistrée.

## Multilingue

[English](../../README.md) | [简体中文](../../README.md) | [繁體中文(台灣)](../zh-TW/README.md) | [繁體中文(香港)](../zh-HK/README.md) | [हिन्दी](../hi/README.md) | [Español](../es/README.md) | [العربية](../ar/README.md) | **Français**

## Documentation

- Présentation du projet : [README](README.md)

- Justification de la conception : [DESIGN](DESIGN.md)

- Historique des versions : [LOG](LOG.md)

- Avis relatifs aux tiers : [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Introduction

Le menu interactif ou l'interface en ligne de commande par lots sélectionne les disques, effectue une évaluation rapide fondée sur SMART, les montages et le journal du noyau, puis fournit un score heuristique de 0 à 100 et un niveau de risque. D'autres modules proposent des autotests SMART courts ou longs, une mesure de vitesse de lecture par échantillonnage, une analyse reprenable de la latence de lecture sur l'ensemble du disque avec revérification ciblée facultative par `badblocks`, une vérification intégrale en lecture seule par `badblocks` et un test de lecture de l'interface après réparation. L'évaluation complète exécute les contrôles rapide, court, long, de vitesse et de surface ; elle n'inclut ni le module `badblocks` intégral distinct ni celui de l'interface. Les résultats peuvent être réutilisés, comparés à l'historique des compteurs SMART et regroupés dans un rapport. Voir les [problèmes connus](LOG.md) et les [objectifs](DESIGN.md).

**La lecture seule concerne les données du disque cible, pas l'hôte.** Le programme écrit sur l'hôte des journaux, paramètres, données de progression et historiques ; il peut activer SMART, lancer des autotests internes au disque, lire des périphériques entiers sous charge soutenue, installer des paquets après confirmation et démarrer des unités systemd transitoires. Il ne remplace pas les sauvegardes. Aucune analyse de surface avec écriture destructive, aucun effacement ni aucune écriture dans le système de fichiers n'est implémenté.

L'évaluation complète répète SMART/ATA/CRC après les lectures prolongées. Le score global de 0 à 100 n'apparaît que si les contrôles rapide, court, long, de vitesse et de surface terminée appartiennent au même lot, sont complets et non expirés. Les résultats réutilisés, interrompus, expirés ou anciens restent visibles comme historiques, avec une catégorie partielle/inconnue ; consulter un rapport n'actualise pas la référence. Après réparation, vérifiez l'interface séparément puis reprenez l'évaluation complète pour obtenir un nouveau score ; la résolution n'efface pas les anciennes erreurs. Un premier total d'erreurs ATA de cause inconnue conserve une pénalité de 5 points pour risque non résolu lors des contrôles suivants, même après une évaluation complète. Une hausse retire 20 points ; un compteur stable n'est ni une nouvelle erreur ni une preuve de résolution. La vérification de l'interface seule n'attribue pas les anciennes erreurs ATA à une réparation. Les lectures lentes isolées appellent un nouveau test de performances, sans prouver la présence de secteurs défectueux ; les erreurs de lecture confirmées de surface retirent toujours 40 points. Sauvegardez les données avant de tester un disque suspect.

## Prérequis

- Minimum : droits root, Bash 4.3+, utilitaires Linux de périphériques blocs (`lsblk`, `blockdev`), `smartctl` (`smartmontools`), `dd` (`coreutils`) et `flock` ; Debian/Ubuntu est la plateforme visée. Les autres distributions déclenchent un avertissement ; l'installation automatique des dépendances utilise `apt-get`.
- Recommandé : `badblocks` (`e2fsprogs`) pour les vérifications de surface ; systemd avec `systemd-run` pour les tâches détachées. L'absence de paquets peut entraîner une proposition interactive de `apt-get update`/installation (ou une confirmation automatique avec `-y`). Vérifiez les dépendances avant une exécution sans surveillance. Aucun code tiers à version figée n'est inclus et aucun fichier de verrouillage des dépendances ne s'applique.
- Un vrai disque dur et l'accès SMART sont nécessaires pour évaluer son état réel. Les SSD/NVMe peuvent être inclus explicitement, mais le score conçu pour les disques durs n'est pas une évaluation calibrée des SSD/NVMe.

## Installation

### Installation rapide

Depuis une copie de travail fiable, lancez `sudo bash ./hdd-health-check.sh --help` pour consulter les options sans démarrer d'analyse. N'envoyez pas un script distant non vérifié directement à un shell root.

### Installation normale


Le checkout ci-dessous utilise le tag de version `v4.1.0`. La commande à la racine du dépôt reste un simple point d’entrée; son implémentation se trouve dans `src/checker/`.

```bash
git clone --branch v4.1.0 --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh src/checker/hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

Vérifiez et installez vous-même les paquets système requis avant toute analyse afin d'éviter la demande d'installation du script. Pour mettre à niveau une copie existante, sauvegardez d'abord les journaux de l'hôte souhaités ainsi que `${HDD_STATE_DIR:-/var/lib/hdd-health}` ; remplacez le script à partir d'une copie vérifiée, conservez ce répertoire d'état pour l'historique et la reprise, puis consultez `--help` et exécutez les contrôles choisis. L'analyse des données d'état v2.2 n'accepte que les champs connus ; des données d'état v2.2 antérieures non conformes peuvent être rejetées. Pour revenir en arrière, il faut restaurer le script précédent **et sa sauvegarde d'état correspondante** ; ne présumez pas qu'un état plus récent est rétrocompatible. Aucune compatibilité avec l'interface en ligne de commande v1 ni migration d'état v1 n'est garantie.

### Interface Web depuis le tag v4.1.0

Le tag source ne suit pas les fichiers générés de `dist/web`. Sur un hôte Debian avec systemd, installez Node.js 20.19+ ou 22.12+ et npm, construisez l’interface, puis lancez l’installateur. GitHub Release propose aussi une archive Web précompilée pour une installation sans Node.js sur le NAS:

```bash
git clone --branch v4.1.0 --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/src/web
npm ci
npm run build
cd ../..
sudo bash deploy/install.sh
```

L’installateur vérifie et installe les paquets d’exécution Debian manquants, démarre le service protégé par mot de passe sur le port LAN 8765 et ne lance aucune analyse de disque. Lisez le mot de passe généré avec `sudo cat /root/apps/hdd-health-check/web-password`. Node.js n’est nécessaire que pour construire l’interface. Consultez [WEB](WEB.md) pour les mises à jour, les limites de sécurité et le retour arrière.

## Conseils

N'exécutez l'outil que sur les disques que vous êtes autorisé à examiner ; une analyse soutenue en lecture peut ajouter une charge importante. Les commandes ci-dessous sont **des exemples, pas des instructions de validation pour cet environnement** :

```bash
sudo bash ./hdd-health-check.sh                 # terminal menu
sudo bash ./hdd-health-check.sh -a              # all rotational disks, default quick scan
sudo bash ./hdd-health-check.sh -d sdb -r quick,short
sudo bash ./hdd-health-check.sh -d sdb -r full -y
sudo bash ./hdd-health-check.sh -d sdb -r iface --duration 30 --detach
sudo bash ./hdd-health-check.sh --status
sudo bash ./hdd-health-check.sh --stop
```

`-d/--disk` accepte des noms de périphériques séparés par des virgules ; `-a/--all` sélectionne les disques mécaniques et `--include-ssd` étend la sélection. `-r/--run` accepte `quick,short,long,speed,surface,badblocks,iface,full` ; la valeur par défaut est `quick` et le mode par lots ajoute toujours un rapport. `--duration` fixe la durée du test d'interface en minutes (15 par défaut). `--rescan` recommence au lieu de réutiliser ou de reprendre les résultats antérieurs ; par défaut, le contrôle rapide est répété en mode par lots, les autres résultats sont réutilisés tant qu'ils sont valides et les analyses de surface interrompues reprennent. `-q/--quiet` supprime la sortie dans le terminal, **pas l'écriture des journaux** ; `-y/--yes` confirme automatiquement les demandes, y compris l'installation de paquets. `--detach` exige le mode par lots et la disponibilité de `systemd-run` ; la déconnexion du terminal pendant certaines longues tâches interactives peut également transférer leur exécution à systemd. `--stop` demande un arrêt sans perdre la progression de l'analyse de surface, mais n'annule **pas** les autotests SMART internes au disque. `-l/--log FILE` change le chemin du journal ; `HDD_LOG_DIR` et `HDD_STATE_DIR` remplacent les répertoires par défaut. `NO_COLOR` désactive les couleurs ; `HDD_NO_BG` désactive le transfert automatique des tâches interactives en arrière-plan. Les paramètres du menu sont enregistrés dans le répertoire d'état.

L'analyseur d'options associe aussi `-t short|long` à l'autotest correspondant, `-s` au test de vitesse et `-b` à badblocks ; **`-w/--wait` est ignoré** et n'attend pas la fin d'un test. Ces alias ne rétablissent pas le comportement de la v1. Consultez `--help` pour connaître les options du script installé.

Codes de sortie : `0` tout va bien ; `1` remarque/avertissement ; `2` danger ; `3` erreur d'exécution. Par défaut, les journaux sont écrits dans `/var/log/disk-health/hdd-health-<timestamp>.log` et l'état dans `/var/lib/hdd-health`. Les écritures sur l'hôte et les limites opérationnelles sont détaillées dans [DESIGN](DESIGN.md).

## Mise à niveau

Avec l’organisation actuelle du code source, mettez à jour le checkout, construisez l’interface dans `src/web`, puis lancez `sudo bash deploy/install.sh` depuis la racine du dépôt. L’installateur copie `src/checker/hdd-health-check.sh`, `src/web/server.py` et `dist/web` dans l’installation existante, conserve le mot de passe Web et garde des sauvegardes horodatées de l’application et de l’unité. Examinez les changements avant de le lancer en tant que root. Le tag historique `v3.0.0` conserve son ancienne organisation `web/` et ses propres instructions d’installation.

## Désinstallation

- Supprimez la copie de travail ou le script installé pour retirer la CLI tout en conservant les journaux et l’historique. La CLI n’installe aucun service systemd permanent ; si vous avez installé le service Web facultatif, arrêtez-le et désactivez-le d’abord comme indiqué dans [WEB](WEB.md). Vérifiez si des tâches transitoires sont actives avant de supprimer le script.
- Pour une suppression complète, arrêtez d'abord toute tâche et sauvegardez les données souhaitées, puis supprimez manuellement `HDD_STATE_DIR` configuré (`/var/lib/hdd-health` par défaut) et `HDD_LOG_DIR` configuré (`/var/log/disk-health` par défaut) après avoir vérifié leurs chemins et leur contenu. Cela efface les rapports, la progression, l'historique, les notes de réparation et les journaux ; ne supprimez jamais aveuglément un répertoire partagé ou redéfini. Les paquets installés via `apt-get` ne sont pas supprimés automatiquement.

## Remerciements

Les crédits du code et des polices tiers figurent dans [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md).

## Licence

MIT (SPDX: MIT) ; voir [LICENSE](../../LICENSE).

## Évaluation et commandes SSD actuelles

Une évaluation complète SSD/NVMe exécute le contrôle SMART rapide, les autotests court et long, puis une lecture intégrale du disque. Elle omet l’échantillonnage de vitesse ; les lectures lentes seules ne retirent aucun point de santé. Un lot complet sans anomalie obtient 100 points ; les constats SMART ou les erreurs de lecture réelles peuvent réduire ce score indicatif. Les commandes groupées présentent l’ensemble des contrôles pris en charge par les disques sélectionnés; les modules réservés aux HDD ignorent les SSD sélectionnés. Un clic sur les valeurs de capacité ou de données écrites bascule entre unités décimales et binaires. Les détails SMART d’un HDD en veille proposent un bouton pour réveiller uniquement ce disque.
