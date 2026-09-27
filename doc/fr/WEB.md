---
name: web-guide-fr
description: Installation et utilisation de l’interface Web locale
metadata:
  version: "0.1.0"
  lang: fr
---

# Interface Web locale

L’interface Web affiche les résultats des disques locaux, l’historique récent des compteurs SMART, les tâches actives et une programmation configurable des contrôles rapides. Elle lance les contrôles choisis à l’aide de l’outil Bash existant. Elle ne présente pas les résultats partiels ou expirés comme un score actuel. Seul un lot d’évaluation complet et non expiré peut afficher un score numérique.

Les cartes des disques à surveiller affichent la cause enregistrée. La durée de fonctionnement seule ne réduit pas le score ; les anciennes alertes de seuil sans compteur brut passent en attente de vérification. Les confirmations utilisent une boîte de dialogue intégrée et le détail place le modèle au-dessus du chemin du périphérique.

## Prérequis

- Debian ou Ubuntu avec Python 3.10+, une version de Node.js compatible avec la version de Vite présente dans le dépôt, systemd et `systemd-run`.
- Les dépendances du vérificateur : `smartmontools`, `util-linux`, `coreutils` et, facultativement, `e2fsprogs` pour badblocks.
- La page Web utilise une connexion par mot de passe et l’API utilise une session. Ouvrez TCP 8765 uniquement sur un réseau local fiable ; HTTP ne chiffre pas le mot de passe.

## Installer l’interface Web depuis main

La branche `main` ne contient pas le dossier compilé `web/dist`. Sur un hôte Debian avec systemd, installez d’abord Node.js 20.19+ ou 22.12+ et npm, puis compilez l’interface et lancez l’installateur. Node.js est nécessaire uniquement pour la compilation.

```bash
git clone --branch main --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/web
npm ci
npm run build
cd ..
sudo bash deploy/install.sh
```

## Compilation et exécution

Après extraction de l’archive précompilée sur le NAS Debian, placez-vous dans le dossier extrait et lancez :

```bash
sudo bash deploy/install.sh
```

Après installation, ouvrez `http://<NAS-IP>:8765` et saisissez le mot de passe sur la page de connexion. Lisez-le avec `sudo cat /root/apps/hdd-health-check/web-password`. Les mises à jour conservent le mot de passe et sauvegardent l’ancienne application ; Node.js n’est pas nécessaire sur le NAS.

Depuis une copie de travail de confiance :

```bash
cd web
npm ci
npm run build
cd ..
sudo python3 web/server.py --port 8765
```

Ouvrez `http://127.0.0.1:8765`. Le processus Python sert l’interface compilée ; Node n’est pas nécessaire à l’exécution. La copie du code source et son répertoire `web/dist` doivent rester ensemble. `npm run dev` lance Vite sur un autre port local et transmet `/api` au service Python.

Pour un service permanent, utilisez le programme d’installation ci-dessus ; l’unité systemd nécessite le fichier de mot de passe qu’il crée.

Pour retirer le service Web, exécutez `sudo systemctl disable --now hdd-health-web.service`, supprimez son fichier d’unité installé, puis exécutez `sudo systemctl daemon-reload`. Examinez les contrôles transitoires encore actifs avant de supprimer la copie de travail. Conservez ou supprimez séparément l’état et les journaux conformément aux instructions de [désinstallation de la CLI](README.md#désinstallation).

L’adresse `site-preview` de Codex ne sert que des fichiers statiques. Elle affiche l’interface et le journal des modifications intégré, mais ne dispose pas du backend `/api` pour afficher les disques ou lancer des vérifications. Pour les données réelles, ouvrez l’adresse du service Python. Depuis un autre ordinateur, exécutez-y `ssh -L 8765:127.0.0.1:8765 user@nas-host`, puis ouvrez `http://127.0.0.1:8765`.

## Fonctionnement et limites

- Les contrôles rapides automatiques sont désactivés au départ. Une fois activés, ils s’exécutent toutes les 6 à 168 heures. Si aucun contrôle n’a encore été programmé, le premier démarre peu après l’activation. La programmation ne concerne que les disques rotatifs et lance les tâches au moyen d’une unité systemd transitoire.
- Les contrôles manuels se choisissent disque par disque. Les contrôles approfondis sont réservés aux disques rotatifs ; un SSD explicitement répertorié ne peut recevoir qu’un contrôle rapide. L’outil peut quand même activer SMART ou démarrer des autotests internes du disque. Un arrêt sécurisé conserve la progression du balayage de surface, mais n’annule pas un autotest interne.
- `--no-install` empêche le service Web d’approuver l’installation de paquets au lancement des tâches. Installez séparément les dépendances manquantes. Le service n’accepte que des noms de contrôles prédéfinis et des périphériques alors répertoriés ; il ne passe pas par un shell pour construire les commandes.
- Le répertoire privé d’état reste `/var/lib/hdd-health` et les journaux restent dans `/var/log/disk-health` par défaut. `web-schedule.json` est enregistré dans le répertoire d’état avec les permissions 600. Le navigateur reçoit les résultats et l’historique récent par des points de terminaison JSON de même origine.
- Le service vérifie Host et Origin. L’API exige une session par mot de passe ou une adresse IPv4 source autorisée. Seule une session par mot de passe peut modifier la liste. Ne publiez pas le port sur Internet.
- Les commandes de l’interface sont disponibles dans les langues du projet. Les résumés détaillés des contrôles et les journaux des tâches en direct proviennent du vérificateur Bash chinois existant et restent actuellement en chinois dans toutes les langues de l’interface.

## API

`GET /api/snapshot` renvoie l’instantané structuré des disques produit par le vérificateur. `GET /api/status` renvoie l’état de la tâche active. `GET /api/history/<device>` renvoie jusqu’à 30 lignes de compteurs SMART. `GET` et `POST /api/schedule` gèrent l’intervalle des contrôles rapides. `POST /api/jobs` lance un contrôle prédéfini sur un périphérique répertorié ; `POST /api/jobs/stop` demande un arrêt sécurisé. Les routes API inconnues renvoient 404. La sortie `--json` du vérificateur est la source des scores ; le service Web ne les recalcule pas.

Lorsque SMART confirme la veille, la liste et les détails indiquent En veille ; une lecture en cours indique Lecture, et un échec de lecture reste inconnu. La politique est enregistrée dans `/var/lib/hdd-health/web-preferences.json` et désactivée par défaut. Tout utilisateur authentifié peut modifier la liste IP et la politique ; le changement de mot de passe exige le mot de passe actuel.

## Interface and access

En haut figurent Tableau de bord, Journal des mises à jour et Paramètres, dans cet ordre. Tableau de bord reste actif sur Disques, Attention, Tâches (y compris l’historique) et Contrôles planifiés. Le sélectionner depuis ces pages conserve la page actuelle ; depuis Paramètres ou le Journal, il ouvre `/disks`. Le logo en haut à gauche reste un lien vers `/disks`. Les quatre cartes ouvrent `/disks`, `/attention`, `/tasks` et `/schedule` ; l’évaluation en un clic reste sur Disques. Le Journal ouvre la page indépendante `/changelog`, également accessible directement.

La marque HDD Health en haut à gauche renvoie au tableau de bord des disques sur `/disks`. L’onglet du navigateur utilise l’icône du projet dans `web/public/favicon.svg`, incluse dans la version de production.

Paramètres regroupe l’apparence, la liste IPv4 précise sans mot de passe, la politique de veille et le mot de passe de connexion. Toute personne ayant accédé à la page peut modifier la liste IP et la politique. Le formulaire de changement de mot de passe apparaît aussi après un accès par IP ; le serveur vérifie le mot de passe actuel. Par défaut, les HDD en veille restent endormis ; on peut choisir de les réveiller un par un à l’ouverture pour lire leur température. Les détails comportent des onglets SMART et contrôles ; les mises à jour sont rendues en Markdown sur une page séparée.

La page principale permet de choisir séparément le groupe de disques (SATA, HDD, SSD, NVMe ou tous) et le contrôle (rapide, SMART court/long, vitesse, surface, badblocks, interface ou complet). Le serveur sélectionne les disques énumérés et exécute le contrôle choisi en arrière-plan. Seule une évaluation complète peut établir un score composite actuel ; les scores SSD/NVMe suivent encore des règles HDD. La liste distingue SATA SSD et NVMe SSD selon le support et le transport et relève la température en arrière-plan sans réveiller un HDD en veille. Les détails affichent le format uniquement si le périphérique le signale ; SATA ou NVMe ne suffisent pas à déduire M.2. Les données disponibles du lien SATA ou PCIe viennent de smartctl et Linux sysfs. Cliquez sur la durée de fonctionnement pour alterner entre heures et années/jours/heures.

La carte Attention filtre les disques avec avertissements ou erreurs. Les détails indiquent causes et points déduits ; un ancien résultat sans cause invite à relancer le contrôle. Tâches affiche la tâche active et son journal détaillé dépliable, avec un historique séparé des 30 tâches les plus récentes. À la fin, à l’arrêt ou en cas d’échec, le reçu quitte le panneau actif et est conservé dans `web-job-history/` ; les résultats par disque et les journaux hôte restent. Les codes 1 et 2 indiquent un contrôle terminé avec problèmes.

La page principale additionne la capacité des disques physiques et l’espace utilisé sur les systèmes de fichiers montés, sans compter deux fois le même UUID. RAID et volumes non montés peuvent rendre ces valeurs non comparables. Le détail SMART affiche les écritures SSD issues du compteur NVMe standard ou des statistiques ATA à taille de secteur connue ; il ne devine pas l’unité des compteurs constructeur. L’allocation des pools ZFS reconnus compte aussi dans l’utilisation. Le bouton de capacité bascule entre TB et TiB ; un bouton distinct ouvre les détails.

Tâches conserve l’affichage de la tâche active et ajoute un historique séparé des 30 dernières tâches Web terminées, arrêtées ou échouées. La fin du journal détaillé est disponible si son fichier existe encore. Les nouveaux reçus sont conservés dans `web-job-history/` ; les anciens reçus supprimés ne peuvent pas être reconstruits de manière fiable. Dashboard reste actif en haut des pages Disques, Attention, Tâches et Contrôles planifiés.
