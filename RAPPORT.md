# Rapport – TP1 : Ansible + Semaphore UI

**Nom :** Amal Jemli **Date :** 20/10/2026 **Dépôt :** https://github.com/Amal356/portfolio-deploy

## 1. Ce qui a été réalisé

Le playbook `site.yml` est découpé en quatre rôles (`common`, `nodejs`, `app`, `nginx`). Il prépare une VM Ubuntu 24.04 **vierge** (`tp1-server`, 192.168.56.50, créée avec Vagrant), installe Node.js 22 (NodeSource) et PM2, clone le portfolio Next.js ([cv-devsecops](https://github.com/Amal356/cv-devsecops), dossier `portfolio-next`) dans `/opt/portfolio`, le construit, le lance avec PM2 sur le port 3000 et l'expose sur le port 80 via un vhost Nginx généré par un template Jinja2. Toutes les valeurs (dépôt, version, port, nom d'hôte, utilisateur) sont dans `group_vars/all.yml`.

Le playbook est d'abord lancé en ligne de commande depuis la VM `ansible-admin`. L'exécution est ensuite confiée à **Semaphore UI** (v2.19.17, conteneur Docker sur `docker-vm`), avec : un projet, une clé SSH dédiée dans le Key Store, le dépôt GitHub, un inventaire statique, un groupe de variables, et le template **Deploy Portfolio** avec la variable de survey `app_version`.

## 2. Idempotence

| Exécution | ok | changed | failed | skipped |
|---|---|---|---|---|
| 1er déploiement (CLI) | 26 | 9 | 0 | 1 |
| 2e run (CLI) | 21 | **0** | 0 | 4 |
| Semaphore, run #1 (sans changement de code) | 22 | 1 | 0 | 3 |
| Semaphore, run #2 (après un commit) | 24 | 4 | 0 | 2 |

Le 2e run n'a rien modifié (`captures/idempotence.png`) :
- le cache apt n'est rafraîchi qu'une fois par heure (`cache_valid_time: 3600`) ;
- `npm ci` et `npm run build` ne s'exécutent que si le dépôt Git a changé ;
- PM2 n'est démarré que s'il ne gère pas déjà l'application ;
- les redémarrages (application, Nginx) passent exclusivement par des **handlers**.

Le `changed=1` du run Semaphore #1 est le rafraîchissement du cache apt : le précédent datait de plus d'une heure.

## 3. Redémarrage conditionnel

Une phrase a été ajoutée à la page d'accueil du portfolio (commit sur `cv-devsecops`), puis **Deploy Portfolio** a été relancé dans Semaphore :
- la tâche `git` passe en *changed* (`captures/10-semaphore-run2-git-changed.png`) ;
- cela déclenche `npm ci`, `npm run build` et le handler **RUNNING HANDLER [app : Redémarrer le portfolio]** (`captures/11-semaphore-run2-handler.png`) ;
- la nouvelle phrase est visible sur `http://192.168.56.50` (`captures/12-portfolio-mis-a-jour.png`).

Lors du run #1, sans nouveau commit, ce handler ne s'est pas exécuté.

## 4. Apport de Semaphore

- **Exécution sans poste de contrôle** : le déploiement se lance depuis un navigateur, sans Ansible ni clé SSH sur le poste de l'utilisateur.
- **Secrets centralisés** : la clé SSH est chiffrée dans le Key Store, avec une clé de chiffrement définie dans un fichier `.env` non versionné. Semaphore a **sa propre clé** (`semaphore_deploy`), distincte de celle d'`ansible-admin`, installée sur le serveur avec le module Ansible `authorized_key` : chacune peut être révoquée séparément.
- **Traçabilité** : historique des exécutions (Task #1, #2…), auteur, durée et logs complets.
- **Paramétrage** : la variable de survey `app_version` permet de choisir la branche ou le tag au lancement. Elle est passée en *extra var*, la priorité la plus haute dans Ansible.

## 5. Difficultés rencontrées et solutions

| Problème | Cause | Solution |
|---|---|---|
| `No module named 'debian'` sur la tâche du dépôt NodeSource | le module `deb822_repository` a besoin de la bibliothèque `python3-debian` sur le serveur cible | `python3-debian` ajouté aux paquets du rôle `common` |
| `--check --diff` impossible sur un serveur vierge | en simulation, rien n'est réellement installé ni cloné (dossier `/opt/portfolio/portfolio-next`, `npm`, Nginx absents) | tâches dépendantes ignorées en mode check (`when: not ansible_check_mode`, `ignore_errors: "{{ ansible_check_mode }}"`) |
| `npm ci` : `ECONNRESET` (coupure réseau) | téléchargement interrompu ; un `node_modules` incomplet aurait fait sauter `npm ci` au run suivant | 3 essais (`retries` / `until`) et test du fichier `node_modules/.package-lock.json`, écrit par npm seulement à la fin d'une installation réussie |
| Semaphore redémarre en boucle : `Unknown database dialect: bolt` | BoltDB n'est plus supporté par Semaphore 2.19 | base **SQLite** (`SEMAPHORE_DB_DIALECT: sqlite`), disponible depuis la v2.16 |
| Le portfolio est dans un sous-dossier du dépôt | `npm` et PM2 doivent être lancés dans `portfolio-next` | variables `app_dir` (clone) et `app_src_dir` (dossier de l'application) |
| Port SSH 2222 pris par une VM Vagrant, VM bloquée au réveil | conflit avec `ubuntu-server-26` ; VM restaurée depuis un état sauvegardé | ports SSH fixes dans les Vagrantfile (2201, 2202, 2203), `vagrant halt -f` puis `vagrant up` |

## 6. Conclusion

Le portfolio est déployé de façon reproductible sur un serveur vierge, en une commande ou en un clic. Le playbook est idempotent, et il ne reconstruit et ne redémarre l'application que lorsque le code change. Ansible décrit **l'état voulu** du serveur. Semaphore ajoute ce qui manque pour un usage en équipe : une interface web, des secrets centralisés, l'historique et le paramétrage des déploiements.
