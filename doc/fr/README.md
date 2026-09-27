---
name: project-overview-fr
description: Project overview and usage
metadata:
  version: "0.1.0"
  lang: fr
---

# hdd-health-check

Cet outil Bash exécuté avec les droits root évalue l'état des disques durs sous Debian/Ubuntu à partir des données SMART et de contrôles du disque en lecture seule. La version principale est `v2.3.0` ; l’interface Web locale facultative décrite plus bas est un ajout de développement non publié. Consultez GitHub Releases pour les versions étiquetées et les téléchargements. L’utilisateur indique que l’ancien code `v2.2.0` a été exécuté sur une machine réelle, sans préciser le périphérique, l’environnement ou la portée des tests. La notation révisée n’a été validée que par des simulations isolées, pas sur un vrai disque dur.

La durée de fonctionnement est une donnée d’usage et ne réduit pas seule le score de santé. Une propriété ATA proche du seuil ne déclenche une alerte que si le compteur brut d’erreurs est non nul. Les anciens résultats sans cette preuve restent en attente de vérification sans déduction. Les cartes de surveillance affichent la cause enregistrée.

## Multi-language

[English](../../README.md) | [简体中文](../zh_cn/README.md) | [繁體中文](../zh_tw/README.md) | [繁體中文(香港)](../zh_hk/README.md) | [हिन्दी](../hi/README.md) | [Español](../es/README.md) | [العربية](../ar/README.md) | **Français**

## Documentation

- Présentation du projet : [README](README.md)
- Conception et effets sur l'hôte : [DESIGN](DESIGN.md)
- Installation de l’interface Web locale et API : [WEB](WEB.md)
- Décisions, problèmes connus et historique des versions : [LOG](LOG.md)
- Inventaire des composants tiers : [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Introduction

Le menu interactif ou l'interface en ligne de commande par lots sélectionne les disques, effectue une évaluation rapide fondée sur SMART, les montages et le journal du noyau, puis fournit un score heuristique de 0 à 100 et un niveau de risque. D'autres modules proposent des autotests SMART courts ou longs, une mesure de vitesse de lecture par échantillonnage, une analyse reprenable de la latence de lecture sur l'ensemble du disque avec revérification ciblée facultative par `badblocks`, une vérification intégrale en lecture seule par `badblocks` et un test de lecture de l'interface après réparation. L'évaluation complète exécute les contrôles rapide, court, long, de vitesse et de surface ; elle n'inclut ni le module `badblocks` intégral distinct ni celui de l'interface. Les résultats peuvent être réutilisés, comparés à l'historique des compteurs SMART et regroupés dans un rapport. Voir les [problèmes connus](LOG.md#bugs) et les [objectifs](DESIGN.md#design-goals).

**La lecture seule concerne les données du disque cible, pas l'hôte.** Le programme écrit sur l'hôte des journaux, paramètres, données de progression et historiques ; il peut activer SMART, lancer des autotests internes au disque, lire des périphériques entiers sous charge soutenue, installer des paquets après confirmation et démarrer des unités systemd transitoires. Il ne remplace pas les sauvegardes. Aucune analyse de surface avec écriture destructive, aucun effacement ni aucune écriture dans le système de fichiers n'est implémenté.

L'évaluation complète répète SMART/ATA/CRC après les lectures prolongées. Le score global de 0 à 100 n'apparaît que si les contrôles rapide, court, long, de vitesse et de surface terminée appartiennent au même lot, sont complets et non expirés. Les résultats réutilisés, interrompus, expirés ou anciens restent visibles comme historiques, avec une catégorie partielle/inconnue ; consulter un rapport n'actualise pas la référence. Après réparation, vérifiez l'interface séparément puis reprenez l'évaluation complète pour obtenir un nouveau score ; la résolution n'efface pas les anciennes erreurs. Un premier total d'erreurs ATA de cause inconnue conserve une pénalité de 5 points pour risque non résolu lors des contrôles suivants, même après une évaluation complète. Une hausse retire 20 points ; un compteur stable n'est ni une nouvelle erreur ni une preuve de résolution. La vérification de l'interface seule n'attribue pas les anciennes erreurs ATA à une réparation. Les lectures lentes isolées appellent un nouveau test de performances, sans prouver la présence de secteurs défectueux ; les erreurs de lecture confirmées de surface retirent toujours 40 points. Sauvegardez les données avant de tester un disque suspect.

## Requirements

- Minimum : droits root, Bash 4.3+, utilitaires Linux de périphériques blocs (`lsblk`, `blockdev`), `smartctl` (`smartmontools`), `dd` (`coreutils`) et `flock` ; Debian/Ubuntu est la plateforme visée. Les autres distributions déclenchent un avertissement ; l'installation automatique des dépendances utilise `apt-get`.
- Recommandé : `badblocks` (`e2fsprogs`) pour les vérifications de surface ; systemd avec `systemd-run` pour les tâches détachées. L'absence de paquets peut entraîner une proposition interactive de `apt-get update`/installation (ou une confirmation automatique avec `-y`). Vérifiez les dépendances avant une exécution sans surveillance. Aucun code tiers à version figée n'est inclus et aucun fichier de verrouillage des dépendances ne s'applique.
- Un vrai disque dur et l'accès SMART sont nécessaires pour évaluer son état réel. Les SSD/NVMe peuvent être inclus explicitement, mais le score conçu pour les disques durs n'est pas une évaluation calibrée des SSD/NVMe.

## Install

### Quick Install

Depuis une copie de travail fiable, lancez `sudo bash ./hdd-health-check.sh --help` pour consulter les options sans démarrer d'analyse. N'envoyez pas un script distant non vérifié directement à un shell root.

### Normal Install

Ce clonage sélectionne le tag de la version v2.3.0, et non la branche de développement mobile `main`.

```bash
git clone --branch v2.3.0 --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

Vérifiez et installez vous-même les paquets système requis avant toute analyse afin d'éviter la demande d'installation du script. Pour mettre à niveau une copie existante, sauvegardez d'abord les journaux de l'hôte souhaités ainsi que `${HDD_STATE_DIR:-/var/lib/hdd-health}` ; remplacez le script à partir d'une copie vérifiée, conservez ce répertoire d'état pour l'historique et la reprise, puis consultez `--help` et exécutez les contrôles choisis. L'analyse des données d'état v2.2 n'accepte que les champs connus ; des données d'état v2.2 antérieures non conformes peuvent être rejetées. Pour revenir en arrière, il faut restaurer le script précédent **et sa sauvegarde d'état correspondante** ; ne présumez pas qu'un état plus récent est rétrocompatible. Aucune compatibilité avec l'interface en ligne de commande v1 ni migration d'état v1 n'est garantie.

## Installer l’interface Web depuis main

La branche `main` ne contient pas le dossier compilé `web/dist`. Sur un hôte Debian avec systemd, installez d’abord Node.js 20.19+ ou 22.12+ et npm, puis compilez l’interface et lancez l’installateur. Node.js est nécessaire uniquement pour la compilation. [WEB](WEB.md).

```bash
git clone --branch main --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/web
npm ci
npm run build
cd ..
sudo bash deploy/install.sh
```

## Conseils d'utilisation

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

Codes de sortie : `0` tout va bien ; `1` remarque/avertissement ; `2` danger ; `3` erreur d'exécution. Par défaut, les journaux sont écrits dans `/var/log/disk-health/hdd-health-<timestamp>.log` et l'état dans `/var/lib/hdd-health`. Les écritures sur l'hôte et les limites opérationnelles sont détaillées dans [DESIGN](DESIGN.md#data-design).

## Désinstallation

- Supprimez la copie de travail ou le script installé pour retirer la CLI tout en conservant les journaux et l’historique. La CLI n’installe aucun service systemd permanent ; si vous avez installé le service Web facultatif, arrêtez-le et désactivez-le d’abord comme indiqué dans [WEB](WEB.md). Vérifiez si des tâches transitoires sont actives avant de supprimer le script.
- Pour une suppression complète, arrêtez d'abord toute tâche et sauvegardez les données souhaitées, puis supprimez manuellement `HDD_STATE_DIR` configuré (`/var/lib/hdd-health` par défaut) et `HDD_LOG_DIR` configuré (`/var/log/disk-health` par défaut) après avoir vérifié leurs chemins et leur contenu. Cela efface les rapports, la progression, l'historique, les notes de réparation et les journaux ; ne supprimez jamais aveuglément un répertoire partagé ou redéfini. Les paquets installés via `apt-get` ne sont pas supprimés automatiquement.

## License

MIT (SPDX: MIT) ; voir [LICENSE](../../LICENSE).
