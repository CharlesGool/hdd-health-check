---
name: project-design-fr
description: Architecture, data model, and boundaries
metadata:
  version: "0.1.0"
  lang: fr
---

# hdd-health-check — Conception

Ce document décrit le comportement de `v4.0.0`, ses contraintes et les données d’état stockées sur l’hôte. Le tag `v4.0.0` marque la limite de cette version majeure. L’utilisateur indique avoir exécuté l’ancien code `v2.2.0` sur une machine réelle, sans préciser le périphérique, l’environnement ou la portée des tests. La notation révisée a fait l’objet de tests synthétiques et de vérifications Web sur un NAS Debian, mais d’aucune évaluation complète et contrôlée sur de vrais HDD.

La durée de fonctionnement est une donnée d’usage et ne réduit pas seule le score de santé. Une propriété ATA proche du seuil ne déclenche une alerte que si le compteur brut d’erreurs est non nul. Les anciens résultats sans cette preuve restent en attente de vérification sans déduction. Les cartes de surveillance affichent la cause enregistrée.

## Multilingue

[English](../DESIGN.md) | [简体中文](../zh-CN/DESIGN.md) | [繁體中文(台灣)](../zh-TW/DESIGN.md) | [繁體中文(香港)](../zh-HK/DESIGN.md) | [हिन्दी](../hi/DESIGN.md) | [Español](../es/DESIGN.md) | [العربية](../ar/DESIGN.md) | **Français**

## Documentation

- Présentation du projet : [README](README.md)

- Justification de la conception : [DESIGN](DESIGN.md)

- Historique des versions : [LOG](LOG.md)

- Avis relatifs aux tiers : [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Objectifs de conception

- Fournir un diagnostic rapide des disques durs à partir de l'état et des attributs SMART, des journaux d'erreurs et d'autotests SMART, des montages, des erreurs d'E/S du noyau et des tendances ; présenter un score heuristique et une catégorie permettant d'agir, pas une probabilité de panne.
- Proposer des autotests SMART internes au disque, courts ou longs et indépendants, des lectures brutes échantillonnées, des analyses reprenables de la latence de surface, des revérifications ciblées facultatives par `badblocks` en lecture seule, une vérification intégrale par `badblocks` en lecture seule et des tests de lecture de l'interface sous charge après réparation.
- Prendre en charge la sélection interactive, l'exécution par lots, la conservation des résultats, leur réutilisation et les rapports historiques ; permettre le transfert facultatif de longues tâches à des unités systemd transitoires.
- Exclure la récupération de données, `badblocks` en mode écriture, l’effacement sécurisé et la modification du système de fichiers. Le vérificateur Bash reste ponctuel ; un compagnon Web local facultatif fournit un contrôleur permanent et des contrôles rapides programmés. L’inclusion des SSD/NVMe est facultative, mais la notation conçue pour les HDD ne permet pas de diagnostiquer complètement ces périphériques. L’instantané JSON sert l’interface Web ; une notation SAS plus approfondie et une notation propre aux NVMe ne sont pas des objectifs implémentés.

## Architecture

L’implémentation du vérificateur se trouve dans `src/checker/hdd-health-check.sh` et la commande racine est son point d’entrée de compatibilité; elle énumère les disques avec `lsblk`.

Un seul script Bash 4.3+ recense les disques avec `lsblk`, choisit les cibles par menu ou ligne de commande, vérifie l'accès SMART avec `smartctl`, exécute les modules demandés et produit un rapport composite. Les attributs SMART ATA et les compteurs de défauts et d'erreurs SAS/SCSI suivent des voies de notation distinctes. Le contrôle rapide tient compte des montages et du journal du noyau ; les contrôles de vitesse, de surface et d'interface lisent directement le périphérique. Les résultats et l'identité de chaque périphérique sont conservés pour permettre leur réutilisation ultérieure. Les choix interactifs peuvent être transmis à un processus par lots au moyen d'un plan à champs restreints ; un verrou privé empêche l'exécution simultanée d'instances utilisant le même répertoire d'état. Une unité `systemd-run` transitoire gère les tâches détachées lorsqu'elle est disponible ; `--status` et `--stop` consultent l'instance enregistrée.

Un lot complet associe sous un même marqueur SMART rapide, les autotests court et long ainsi que l’analyse de surface terminée; les HDD nécessitent en plus l’échantillonnage de vitesse, contrairement aux SSD; il répète SMART/ATA/CRC à la fin. Seuls des résultats complets, valides et du même lot permettent un score global numérique. La réutilisation, l'interruption, l'expiration, l'ancien état sans marqueur et la vérification ultérieure de l'interface laissent les anciens résultats historiques/à revérifier et la catégorie globale partielle/inconnue ; consulter un rapport n'actualise pas la référence du contrôle rapide. La vérification d'interface consigne séparément si le problème est résolu ; elle ne réattribue pas les anciennes erreurs et ne rend pas actuel l'ancien lot. Un total ATA sans compteur antérieur conserve une pénalité de 5 points pour risque non résolu lors des contrôles et évaluations complètes ultérieurs, même si l'ancien état n'a pas de champ de risque. Une hausse retire 20 points ; la stabilité n'est ni une nouvelle erreur ni une preuve de réparation, et la vérification d'interface seule n'attribue pas les anciennes erreurs ATA à celle-ci. Les lectures lentes isolées invitent à revérifier les performances, pas à diagnostiquer des secteurs défectueux ; les échecs répétés de lecture de surface retirent toujours 40 points. Ces pondérations heuristiques ne sont pas des probabilités de panne.

Pour les SSD, les baisses ponctuelles des échantillons de vitesse et les variations de vitesse moyenne entre exécutions décrivent les performances et ne réduisent pas la note de santé ; les vraies erreurs de lecture restent pénalisées. Les anciens résultats sont interprétés de la même façon sans modifier leurs fichiers d’état. La liste Web répartit automatiquement les disques selon la largeur disponible dans le navigateur, jusqu’à six colonnes sur les écrans larges ; elle se réorganise quand le zoom change. La carte Disques du tableau de bord mène directement à cette liste. Le frontal de `src/web/` est compilé dans `dist/web/` ; `src/web/src/theme.css` définit des jetons sémantiques pour huit couleurs d’accent en modes clair et sombre. Paramètres conserve séparément la couleur et le mode dans le stockage du navigateur et les restaure avant le montage de Vue. Vite intègre la version de compilation et produit `version.json` pour `/api/build` ; Changelog affiche le fichier `doc/<lang>/LOG.md` approprié depuis les sources fournies.

## Contraintes de conception

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

Les contrôles eux-mêmes n’utilisent aucune API réseau. Le service Web local facultatif ajoute une API HTTP limitée à la boucle locale en mode manuel ; le programme d’installation permet l’accès depuis le réseau local avec authentification, tandis que `--json` fournit un instantané structuré en lecture seule qui utilise la même fonction de notation composite que le rapport du terminal. `--no-install` empêche l’installation de paquets lors des appels sans surveillance. L’architecture Web, la programmation et les limites de sécurité sont décrites dans [WEB](WEB.md). Les scripts peuvent utiliser les codes de sortie `0` sain, `1` attention, `2` danger, `3` erreur d’exécution ; voir [Conseils d’utilisation](README.md). Le code Web se trouve dans `src/web/` et son résultat généré dans `dist/web/`; l’installateur les copie dans l’agencement hôte existant.

La connexion Web crée un cookie de session HttpOnly de courte durée. La vérification de sécurité renouvelle le cookie et accorde cinq minutes d’autorisation; les requêtes modifiant l’état comportent un en-tête de même origine contre le CSRF. Une liste d’adresses privées activée peut dispenser de connexion par mot de passe pour les opérations ordinaires. Security Settings protège la liste, son interrupteur et le changement du mot de passe par une autorisation de cinq minutes accordée par le serveur après vérification du mot de passe administrateur. Une session admise uniquement par IP ne peut ni lire ni modifier ces réglages. Pendant cette période, le nouveau mot de passe et sa confirmation suffisent sans ressaisir l’ancien. Le changement termine toutes les sessions. Les détails SMART sont lus à l’ouverture d’un disque; leur verdict brut ne remplace pas le score composite. Les réponses par défaut d’instantané et de SMART ne transmettent que des numéros de série masqués; une requête authentifiée distincte renvoie le numéro complet seulement après une action explicite. Il est effacé quand on le masque ou ferme le détail.

La page principale permet de choisir séparément le groupe de disques (SATA, HDD, SSD, NVMe ou tous) et le contrôle (rapide, SMART court/long, vitesse, surface, badblocks, interface ou complet). Le serveur sélectionne les disques énumérés et exécute le contrôle choisi en arrière-plan. Seule une évaluation complète peut établir un score composite actuel; un SSD dont l’évaluation est complète et sans anomalie obtient 100 points sans échantillonnage de vitesse, et ce score n’est pas une probabilité de panne calibrée. La liste distingue SATA SSD et NVMe SSD selon le support et le transport et relève la température en arrière-plan sans réveiller un HDD en veille. Les détails affichent le format uniquement si le périphérique le signale ; SATA ou NVMe ne suffisent pas à déduire M.2. Les données disponibles du lien SATA ou PCIe viennent de smartctl et Linux sysfs. Cliquez sur la durée de fonctionnement pour alterner entre heures et années/jours/heures. Le serveur ajoute `--include-ssd` uniquement si nécessaire et lance un lot `<module> --rescan` pour les disques retenus. Les codes `1` et `2` désignent des contrôles terminés avec attention ou danger.

La carte des alertes filtre les disques avec avertissement ou erreur. Les détails indiquent les motifs et les points déduits ; un ancien résultat sans motif enregistré invite à relancer le contrôle. L’acceptation, l’exécution, la fin, l’arrêt ou l’échec de la tâche et la fin du journal restent visibles. Sans confirmation d’exécution ni état final après 15 secondes, l’état est signalé comme non confirmé. Les codes 1 et 2 indiquent un contrôle terminé avec des problèmes, non un échec du lancement.

## Évaluation et commandes SSD actuelles

Une évaluation complète SSD/NVMe exécute le contrôle SMART rapide, les autotests court et long, puis une lecture intégrale du disque. Elle omet l’échantillonnage de vitesse ; les lectures lentes seules ne retirent aucun point de santé. Un lot complet sans anomalie obtient 100 points ; les constats SMART ou les erreurs de lecture réelles peuvent réduire ce score indicatif. Si la sélection comprend un SSD, l’interface ne propose que le contrôle rapide, les autotests court et long, la lecture intégrale et l’évaluation complète. Un clic sur les valeurs de capacité ou de données écrites bascule entre unités décimales et binaires. Les détails SMART d’un HDD en veille proposent un bouton pour réveiller uniquement ce disque.
