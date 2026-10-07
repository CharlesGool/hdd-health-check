---
name: project-web-fr
description: Installation et utilisation de l’interface Web locale
metadata:
  version: "0.1.0"
  lang: "fr"
---

# Interface Web locale

L’interface Web affiche les résultats des disques locaux, l’historique récent des compteurs SMART, les tâches actives et une programmation configurable des contrôles rapides. Elle lance les contrôles choisis à l’aide de l’outil Bash existant. Elle ne présente pas les résultats partiels ou expirés comme un score actuel. Seul un lot d’évaluation complet et non expiré peut afficher un score numérique.

Les cartes des disques à surveiller affichent la cause enregistrée. La durée de fonctionnement seule ne réduit pas le score ; les anciennes alertes de seuil sans compteur brut passent en attente de vérification. Les confirmations utilisent une boîte de dialogue intégrée et le détail place le modèle au-dessus du chemin du périphérique.

## Multilingue

[English](../en/WEB.md) | [简体中文](../WEB.md) | [繁體中文(台灣)](../zh-TW/WEB.md) | [繁體中文(香港)](../zh-HK/WEB.md) | [हिन्दी](../hi/WEB.md) | [Español](../es/WEB.md) | [العربية](../ar/WEB.md) | **Français**

## Documentation

- Présentation du projet : [README](README.md)

- Justification de la conception : [DESIGN](DESIGN.md)

- Historique des versions : [LOG](LOG.md)

- Avis relatifs aux tiers : [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

- Guide de l’interface Web: [WEB](WEB.md)

## Prérequis

- Debian ou Ubuntu avec Python 3.10+, une version de Node.js compatible avec la version de Vite présente dans le dépôt, systemd et `systemd-run`.
- Les dépendances du vérificateur : `smartmontools`, `util-linux`, `coreutils` et, facultativement, `e2fsprogs` pour badblocks.
- Le service Web exige root. L’installateur Debian écoute sur le port IPv4 8765 et utilise une page de connexion et des sessions pour l’API. Ouvrez `http://<NAS-IP>:8765` depuis le même réseau local fiable; ne redirigez pas ce port vers Internet. HTTP sur le LAN ne chiffre pas le mot de passe. Un transfert de port local SSH reste possible pour un transport chiffré.

## Compilation et exécution

Le code Web UI actuel se trouve dans `src/web/` et ne suit pas le résultat généré `dist/web/`. Le tag historique `v3.0.0` conserve l’ancien agencement `web/`. Sur un hôte Debian avec systemd, installez Node.js 20.19+ ou 22.12+ et npm, construisez l’interface, puis lancez l’installateur :

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/src/web
npm ci
npm run build
cd ../..
sudo bash deploy/install.sh
```


Après extraction de l’archive précompilée sur le NAS Debian, placez-vous dans le dossier extrait et lancez :

```bash
sudo bash deploy/install.sh
```

Après installation, ouvrez `http://<NAS-IP>:8765` et saisissez le mot de passe généré. Lisez-le avec `sudo cat /root/apps/hdd-health-check/web-password`; l’installateur le conserve lors des mises à jour et seul root peut lire le fichier. Security Settings demande le mot de passe administrateur avant d’afficher la liste IP ou le formulaire de modification. Pendant les cinq minutes d’autorisation, entrez et confirmez un nouveau mot de passe de 12 à 128 caractères sans répéter l’ancien; ce changement invalide toutes les sessions. Si la page ne s’ouvre pas, vérifiez `sudo systemctl status hdd-health-web.service` et que le pare-feu autorise TCP 8765 depuis le LAN. L’installateur ne modifie pas le pare-feu.

Depuis une copie de travail de confiance :

```bash
cd src/web
npm ci
npm run build
cd ../..
sudo python3 src/web/server.py --port 8765
```

Ouvrez `http://127.0.0.1:8765`. Le processus Python sert l’interface compilée ; Node n’est pas nécessaire à l’exécution. La copie du code source et son répertoire `dist/web` doivent rester ensemble. `npm run dev` lance Vite sur un autre port local et transmet `/api` au service Python.

Pour un service permanent, utilisez le programme d’installation ci-dessus ; l’unité systemd nécessite le fichier de mot de passe qu’il crée.

Pour retirer le service Web, exécutez `sudo systemctl disable --now hdd-health-web.service`, supprimez son fichier d’unité installé, puis exécutez `sudo systemctl daemon-reload`. Examinez les contrôles transitoires encore actifs avant de supprimer la copie de travail. Conservez ou supprimez séparément l’état et les journaux conformément aux instructions de désinstallation de la CLI.

L’adresse `site-preview` de Codex ne sert que des fichiers statiques. Elle affiche l’interface et le journal des modifications intégré, mais ne dispose pas du backend `/api` pour afficher les disques ou lancer des vérifications. Pour les données réelles, ouvrez l’adresse du service Python. Depuis un autre ordinateur, exécutez-y `ssh -L 8765:127.0.0.1:8765 user@nas-host`, puis ouvrez `http://127.0.0.1:8765`.

L’installateur `deploy/install.sh` vérifie le système, installe l’application dans `/root/apps/hdd-health-check` et démarre `hdd-health-web.service`. Consultez ensuite son état avec `sudo systemctl status hdd-health-web.service`.

Avant de mettre à niveau, sauvegardez `/var/lib/hdd-health` avec la version correspondante du script. L’interface Web ne change pas la politique de migration de son état.

## Fonctionnement et limites

- Les contrôles rapides automatiques sont désactivés au départ. Une fois activés, ils s’exécutent toutes les 6 à 168 heures. Si aucun contrôle n’a encore été programmé, le premier démarre peu après l’activation. La programmation ne concerne que les disques rotatifs et lance les tâches au moyen d’une unité systemd transitoire.
- Les contrôles manuels se choisissent par disque. Un SSD peut recevoir le contrôle rapide, les autotests SMART court et long, la lecture intégrale seule et l’évaluation complète. Les contrôles par lot montrent l’union des modules compatibles; ceux réservés aux HDD ignorent les SSD sélectionnés. L’outil peut activer SMART ou lancer des autotests internes. Un arrêt sûr préserve la progression de surface, mais n’annule pas un autotest interne.
- `--no-install` empêche le service Web d’approuver l’installation de paquets au lancement des tâches. Installez séparément les dépendances manquantes. Le service n’accepte que des noms de contrôles prédéfinis et des périphériques alors répertoriés ; il ne passe pas par un shell pour construire les commandes.
- L’état privé reste dans `/var/lib/hdd-health` et les journaux dans `/var/log/disk-health`. `web-schedule.json`, `web-job.json`, les reçus terminés sous `web-job-history/` et la liste des adresses privées avec son interrupteur sous `web-access.json` y sont enregistrés avec des permissions restreintes. Le navigateur reçoit les résultats et l’historique en JSON de même origine.
- Le service installé se lie à toutes les interfaces IPv4, mais n’accepte qu’un Host correspondant à l’IP et au port de destination. Il vérifie Origin et exige une session par mot de passe ou une IP source admise. Les ressources statiques restent publiques pour charger la connexion. Seule une session administrateur ayant vérifié récemment son mot de passe peut consulter ou modifier la liste d’adresses privées et son interrupteur; l’accès par IP ne donne que le tableau de bord ordinaire. La déconnexion crée un cookie empêchant l’accès IP automatique jusqu’au prochain choix explicite. Sans TLS, une personne qui observe le trafic HTTP LAN peut lire le mot de passe. Utilisez un LAN fiable ou le tunnel SSH et fermez TCP 8765 vers Internet. La commande manuelle `python3 src/web/server.py` reste limitée à loopback sauf si `--bind` et `--password-file` sont fournis.
- Les commandes de l’interface sont disponibles dans les langues du projet. Les résumés détaillés des contrôles et les journaux des tâches en direct proviennent du vérificateur Bash chinois existant et restent actuellement en chinois dans toutes les langues de l’interface.

## API

`GET /api/auth` indique l’état de connexion ; `POST /api/auth/login`, `/api/auth/logout` et `/api/auth/ip-login` gèrent les sessions. `POST /api/auth/security-verify` vérifie le mot de passe administrateur, renouvelle le cookie de session et accorde une autorisation fixe de cinq minutes pour Security Settings. `POST /api/auth/change-password` exige cette autorisation et la concordance du nouveau mot de passe avec sa confirmation ; il remplace atomiquement le fichier appartenant à root et invalide les sessions existantes.

`GET` et `POST /api/access` exigent la même autorisation temporaire pour consulter ou modifier l’interrupteur et les adresses IPv4 RFC 1918 ou IPv6 locales uniques. `GET` et `POST /api/preferences` permettent à tout visiteur authentifié de lire et enregistrer la politique de réveil des disques au chargement de la page. `POST /api/disks/wake-on-visit` lance le réveil choisi en arrière-plan. `GET /api/disks/<device>/smart` lit les détails SMART à la demande sans réveiller un HDD en veille ; `POST /api/disks/<device>/wake`, authentifié, ne réveille qu’un disque rotatif actuellement énuméré.

`GET /api/snapshot` renvoie l’instantané structuré du vérificateur et `GET /api/status` la tâche active avec une fin bornée du journal. `GET /api/jobs/history` renvoie les résumés des tâches Web archivées ; `GET /api/jobs/history/<id>` renvoie une fin bornée du journal si celui-ci existe encore. Les tâches dont les reçus ont été supprimés ne peuvent pas être reconstituées de manière fiable. `GET /api/history/<device>` renvoie au plus 30 lignes SMART pour compatibilité ; `GET /api/history/samples` renvoie les échantillons de tous les disques énumérés. `DELETE /api/history/samples/<device>/<index>`, authentifié, retire un échantillon et peut modifier la prochaine base de comparaison si c’était le dernier. `DELETE /api/jobs/history/<id>` retire le reçu archivé et son journal.

`POST /api/disks/<device>/sleep` demande la veille ATA pour un HDD SATA énuméré uniquement et refuse pendant un contrôle ; des E/S normales peuvent le réveiller. `GET` et `POST /api/schedule` gèrent l’intervalle. `POST /api/jobs` lance un contrôle défini sur un périphérique énuméré. `POST /api/jobs/assess` accepte `scope` parmi `sata`, `hdd`, `ssd`, `nvme` ou `all`, et `module` parmi `quick`, `short`, `long`, `speed`, `surface`, `badblocks`, `iface` ou `full` ; il lance un lot pour les disques correspondants. `POST /api/jobs/stop` demande un arrêt sûr. Les routes API inconnues renvoient 404. La sortie `--json` du vérificateur est la source du score ; le service Web ne le recalcule pas.

## Interface et accès

En haut figurent Tableau de bord, Journal des mises à jour et Paramètres, dans cet ordre. Tableau de bord reste actif sur Disques, Attention, Tâches (y compris l’historique) et Contrôles planifiés. Le sélectionner depuis ces pages conserve la page actuelle ; depuis Paramètres ou le Journal, il ouvre `/disks`. Le logo en haut à gauche reste un lien vers `/disks`. Les quatre cartes ouvrent `/disks`, `/attention`, `/tasks` et `/schedule` ; l’évaluation en un clic reste sur Disques. Le Journal ouvre la page indépendante `/changelog`, également accessible directement.

La marque HDD Health en haut à gauche renvoie au tableau de bord des disques sur `/disks`. L’onglet du navigateur utilise l’icône du projet dans `src/web/public/favicon.svg`, incluse dans la version de production. Un lien de version adjacent à la marque ouvre l’historique des changements. Les compilations sans tag portent `test-<sha>` (avec `-dirty` si l’arbre est modifié), et `/api/build` indique la version intégrée à cette compilation. Les réponses par défaut d’instantané et de SMART ne transmettent que des numéros de série masqués; l’instantané public omet aussi l’identifiant interne du disque, qui peut contenir un numéro de série; une requête authentifiée distincte renvoie le numéro complet seulement après une action explicite. Il est effacé quand on le masque ou ferme le détail.

Paramètres propose la langue, huit couleurs d’accent et un commutateur clair/sombre, ainsi que la politique de veille. La couleur et le mode sont conservés indépendamment entre les rechargements. Une page Security Settings distincte regroupe la liste des IP admises, son interrupteur et le formulaire de changement du mot de passe. Sans autorisation récente, elle demande le mot de passe administrateur et accorde cinq minutes après vérification. Un visiteur admis par IP peut utiliser les contrôles ordinaires des disques et de veille, mais doit vérifier le mot de passe administrateur pour ouvrir les paramètres protégés. Pendant cette période, saisir et confirmer un nouveau mot de passe de 12 à 128 caractères ne nécessite pas de répéter l’ancien. Le changement invalide toutes les sessions. Par défaut, les HDD en veille y restent; on peut choisir de les réveiller un par un à l’ouverture. Le détail SMART masque le numéro de série jusqu’à actionner sa commande et le masque à nouveau à la fermeture.

La page principale permet de choisir séparément le groupe de disques (SATA, HDD, SSD, NVMe ou tous) et le contrôle (rapide, SMART court/long, vitesse, surface, badblocks, interface ou complet). Le serveur sélectionne les disques énumérés et exécute le contrôle choisi en arrière-plan. Seule une évaluation complète peut établir un score composite actuel ; les scores SSD/NVMe suivent encore des règles HDD. La liste distingue SATA SSD et NVMe SSD selon le support et le transport et relève la température en arrière-plan sans réveiller un HDD en veille. Les détails affichent le format uniquement si le périphérique le signale ; SATA ou NVMe ne suffisent pas à déduire M.2. Les données disponibles du lien SATA ou PCIe viennent de smartctl et Linux sysfs. Cliquez sur la durée de fonctionnement pour alterner entre heures et années/jours/heures.

La carte Attention filtre les disques avec avertissements ou erreurs. Les détails indiquent causes et points déduits ; un ancien résultat sans cause invite à relancer le contrôle. Tâches affiche la tâche active et son journal détaillé dépliable, avec un historique séparé des 30 tâches les plus récentes. À la fin, à l’arrêt ou en cas d’échec, le reçu quitte le panneau actif et est conservé dans web-job-history/ ; les résultats par disque et les journaux hôte restent. Les codes 1 et 2 indiquent un contrôle terminé avec problèmes.

La page principale additionne la capacité des disques physiques et l’espace utilisé sur les systèmes de fichiers montés, sans compter deux fois le même UUID. RAID et volumes non montés peuvent rendre ces valeurs non comparables. Le détail SMART affiche les écritures SSD issues du compteur NVMe standard ou des statistiques ATA à taille de secteur connue ; il ne devine pas l’unité des compteurs constructeur. L’allocation des pools ZFS reconnus compte aussi dans l’utilisation. Le bouton de capacité bascule entre TB et TiB ; un bouton distinct ouvre les détails.

Tâches conserve l’affichage de la tâche active et ajoute un historique séparé des 30 dernières tâches Web terminées, arrêtées ou échouées. La fin du journal détaillé est disponible si son fichier existe encore. Les nouveaux reçus sont conservés dans web-job-history/ ; les anciens reçus supprimés ne peuvent pas être reconstruits de manière fiable. Dashboard reste actif en haut des pages Disques, Attention, Tâches et Contrôles planifiés.

La ligne du disque prend le modèle pour titre et indique séparément le chemin `/dev/`; le détail affiche aussi `/dev/`. Un bouton dédié ouvre les détails. Le serveur lance un lot `<module> --rescan` et n’accepte pas de chemin de périphérique arbitraire du client. Seul le module `full` peut établir un score actuel. La page `/changelog` rend l’historique en Markdown. Les lectures de température utilisent `smartctl -n standby` pour ne pas réveiller les HDD endormis; l’option de réveil vérifie d’abord `-n standby`, puis lit les attributs avec `smartctl`.

## Évaluation et commandes SSD actuelles

Une évaluation complète SSD/NVMe exécute le contrôle SMART rapide, les autotests court et long, puis une lecture intégrale du disque. Elle omet l’échantillonnage de vitesse ; les lectures lentes seules ne retirent aucun point de santé. Un lot complet sans anomalie obtient 100 points ; les constats SMART ou les erreurs de lecture réelles peuvent réduire ce score indicatif. Si la sélection comprend un SSD, l’interface ne propose que le contrôle rapide, les autotests court et long, la lecture intégrale et l’évaluation complète. Un clic sur les valeurs de capacité ou de données écrites bascule entre unités décimales et binaires. Les détails SMART d’un HDD en veille proposent un bouton pour réveiller uniquement ce disque.
