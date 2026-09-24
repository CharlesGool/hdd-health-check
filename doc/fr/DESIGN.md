# hdd-health-check — Conception

Ce document décrit le comportement, les contraintes et les données d'état stockées sur l'hôte dans le cadre de l'intégration v2.2.0. Le code source de v2.2.0 est disponible dans ce dépôt GitHub public. L’utilisateur indique l’avoir testé sur une machine réelle, sans préciser les appareils, l’environnement ni les tests effectués ; il n’existe ni tag v2.2.0 ni GitHub Release.

## Multi-language

[English](../DESIGN.md) | [简体中文](../zh_cn/DESIGN.md) | [繁體中文](../zh_tw/DESIGN.md) | [繁體中文（香港）](../zh_hk/DESIGN.md) | [हिन्दी](../hi/DESIGN.md) | [Español](../es/DESIGN.md) | [العربية](../ar/DESIGN.md) | **Français**

## Documentation

- Présentation du projet : [README](README.md)
- Conception : [DESIGN](DESIGN.md)
- Historique des versions : [LOG](LOG.md)
- Inventaire des composants tiers : [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Design Goals

- Fournir un diagnostic rapide des disques durs à partir de l'état et des attributs SMART, des journaux d'erreurs et d'autotests SMART, des montages, des erreurs d'E/S du noyau et des tendances ; présenter un score heuristique et une catégorie permettant d'agir, pas une probabilité de panne.
- Proposer des autotests SMART internes au disque, courts ou longs et indépendants, des lectures brutes échantillonnées, des analyses reprenables de la latence de surface, des revérifications ciblées facultatives par `badblocks` en lecture seule, une vérification intégrale par `badblocks` en lecture seule et des tests de lecture de l'interface sous charge après réparation.
- Prendre en charge la sélection interactive, l'exécution par lots, la conservation des résultats, leur réutilisation et les rapports historiques ; permettre le transfert facultatif de longues tâches à des unités systemd transitoires.
- Exclure la récupération de données, `badblocks` en mode écriture, l'effacement sécurisé, la modification du système de fichiers et tout démon de surveillance permanent. L'inclusion des SSD/NVMe est facultative, mais le score destiné aux disques durs n'est pas conçu pour diagnostiquer complètement ces périphériques. Les sorties structurées JSON/CSV, une notation SAS plus poussée et une notation spécifique aux NVMe ne sont pas des objectifs implémentés.

## Architecture

Un seul script Bash 4.3+ recense les disques avec `lsblk`, choisit les cibles par menu ou ligne de commande, vérifie l'accès SMART avec `smartctl`, exécute les modules demandés et produit un rapport composite. Les attributs SMART ATA et les compteurs de défauts et d'erreurs SAS/SCSI suivent des voies de notation distinctes. Le contrôle rapide tient compte des montages et du journal du noyau ; les contrôles de vitesse, de surface et d'interface lisent directement le périphérique. Les résultats et l'identité de chaque périphérique sont conservés pour permettre leur réutilisation ultérieure. Les choix interactifs peuvent être transmis à un processus par lots au moyen d'un plan à champs restreints ; un verrou privé empêche l'exécution simultanée d'instances utilisant le même répertoire d'état. Une unité `systemd-run` transitoire gère les tâches détachées lorsqu'elle est disponible ; `--status` et `--stop` consultent l'instance enregistrée.

## Design Constraints

- Les droits root et l'accès direct aux données SMART du matériel sont nécessaires pour un diagnostic utile. La détection des ponts USB/RAID est heuristique ; un échec d'accès direct est signalé, sans être interprété comme un état sain. La notation SAS est distincte et moins éprouvée que la notation ATA. Les températures et les seuils dépendent des données du fabricant.
- Toutes les lectures de surface et d'interface des périphériques sont dirigées vers `/dev/null` ; `badblocks` est appelé sans l'option destructive `-w`. **L'activation de SMART et les autotests peuvent modifier l'état du micrologiciel du disque** ; les chemins sur l'hôte sont accessibles en écriture. Il ne faut pas présenter l'exécution comme dépourvue de tout effet secondaire.
- Une sélection explicite et `--include-ssd` ne prouvent pas qu'il est sans risque de solliciter un périphérique. Une analyse de toute la surface peut prendre des heures ; les écritures effectuées par d'autres processus du système continuent. `--stop` ne met pas fin aux autotests exécutés dans le disque.
- Les données d'état et les plans sont analysés selon les champs autorisés et ne sont pas exécutés comme du code shell. Des données d'état existantes non conformes peuvent être rejetées. Le répertoire d'état sur l'hôte ne doit pas être un lien symbolique ; le script vérifie les liens symboliques des répertoires et des journaux de sortie, mais les utilisateurs doivent aussi protéger les chemins qu'ils choisissent.

## Data Design

`HDD_STATE_DIR` désigne par défaut `/var/lib/hdd-health` (créé avec le mode 700). Il contient `settings.conf` (durée de validité en jours, politique de réutilisation, parallélisme, taille des segments d'analyse, paramètres d'échantillonnage, inclusion des SSD et politique de revérification automatique), les fichiers de résultats `.env` par disque, l'historique des compteurs SMART `history.csv`, les journaux de réparation, les cartes et points de reprise des analyses de surface, l'historique des rapports et, éventuellement, des listes de blocs défectueux. Un fichier `.lock`, les données de l'instance active et des plans temporaires d'exécution en arrière-plan coordonnent l'exécution. Les valeurs par défaut comprennent une validité des résultats de sept jours, des segments de surface de 64 MiB et 24 échantillons de vitesse de 128 MiB chacun. Le menu permet d'enregistrer les paramètres ; `--rescan` prévaut sur la réutilisation. La suppression des résultats peut préserver l'historique des compteurs et des réparations ou l'effacer ; les utilisateurs peuvent choisir séparément de supprimer les anciens journaux.

`HDD_LOG_DIR` désigne par défaut `/var/log/disk-health` ; `-l/--log` sélectionne un journal individuel. Les journaux sont en texte brut et peuvent contenir des identifiants de périphériques, des informations sur l'hôte et le noyau ainsi que des données sur l'état des disques ; ils doivent être protégés. Un répertoire de travail temporaire est créé sous `/run` ou, à défaut, dans un répertoire temporaire. Ne présumez ni que le journal est la seule sortie persistante ni qu'il est possible de revenir à une version antérieure avec un répertoire d'état d'une version ultérieure sans sa sauvegarde correspondante.

## External Interfaces

| Interface | Responsabilités et effets |
| --- | --- |
| `lsblk`, `blockdev`, `/proc/mounts`, journal du noyau | Recensement des périphériques, géométrie, état des montages et erreurs d'E/S ; la visibilité dépend des droits sur l'hôte. |
| `smartctl` | Lit les diagnostics SMART ; peut activer SMART ou lancer des tests internes. La détection automatique des options d'accès direct est heuristique. |
| `dd`, `badblocks` | Lit directement les périphériques pour l'échantillonnage, la mise en charge de l'interface, l'analyse de la latence ou la recherche de blocs défectueux en lecture seule. Ces lectures peuvent solliciter du matériel dégradé. |
| `apt-get` | Propose d'installer les paquets manquants ; `-y` peut accepter automatiquement. Cela modifie les paquets de l'hôte et peut nécessiter un accès réseau. |
| `systemd-run` | Unité transitoire facultative pour les tâches détachées ; `--stop` demande l'arrêt du processus enregistré par le script, pas celui d'un autotest matériel. |

Les contrôles d'état eux-mêmes n'utilisent aucune API réseau. Les scripts et intégrations peuvent utiliser les codes de sortie `0` sain, `1` attention, `2` danger, `3` erreur d'exécution ; voir [Conseils d'utilisation](README.md#conseils-dutilisation). Il n'existe aucune API stable de sortie structurée.
