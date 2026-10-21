# Rapport – TP2 : Coolify + Forgejo

**Nom :** Amal Jemli **Date :** 21/10/2026 **Dépôt :** https://github.com/Amal356/devops-partie1 (dossier `tp2-coolify-forgejo`)

## 1. Ce qui a été réalisé

Une VM Ubuntu 24.04 dédiée (`coolify-vm`, 192.168.56.70, 2 vCPU, 4 Go), créée avec Vagrant, héberge :

- **Coolify v4.4.7**, installé avec le script officiel (Docker 29.9.2, PostgreSQL, Redis, Sentinel et le proxy **Traefik v3.7**) ;
- **Forgejo 16**, lancé avec le `docker-compose.yml` fourni (web sur 3001, SSH sur 2222), base SQLite3 ;
- le **portfolio Next.js du TP1**, poussé dans le dépôt public `amal/portfolio` de Forgejo et déployé par Coolify avec son propre `Dockerfile` (build multi-étapes, port 3000).

Le portfolio est servi par Traefik sur `http://portfolio.coolify.local`, nom résolu par le fichier `hosts` de Windows. Un webhook Forgejo → Coolify redéploie l'application à chaque push sur `main`. Le rollback a été testé après un build volontairement cassé.

## 2. Déroulement des déploiements

| # | Source | Commit | Durée | Résultat |
|---|---|---|---|---|
| 1 | Manuel | `8cadce5` code du TP1 | 4 min 50 s | Success (premier build, téléchargement de toutes les dépendances npm) |
| 2 | Webhook (test de livraison) | `8cadce5` | 14 s | Success (image déjà construite pour ce commit) |
| 3 | Webhook (`git push`) | `33e178e` nouvelle phrase d'accueil | 1 min 26 s | Success (couche `npm ci` réutilisée depuis le cache Docker) |
| 4 | Webhook | `86e1755` erreur de syntaxe volontaire | 24 s | **Failed** : `next build` refuse le code, le site reste en ligne |
| 5 | Rollback | `8cadce5` | 7 s | Success : `Build step skipped`, l'image existante est relancée |
| 6 | Webhook | `1f1badd` `git revert` de l'erreur | — | Success : retour au contenu de `33e178e` |

## 3. Points clés observés

- **Construire avant de remplacer.** Coolify construit l'image, puis fait un *rolling update* (nouveau conteneur démarré, ancien supprimé). Quand le build échoue, le rolling update ne commence jamais : la version précédente continue de servir. Une erreur de code ne provoque donc pas de coupure.
- **Une image par commit.** Chaque image est taguée avec le SHA du commit (`1oid6…:8cadce52…`). Le rollback relance une image existante sans rebuild, d'où ses 7 secondes. Un webhook sur un commit déjà construit est tout aussi rapide (déploiement #2).
- **Rollback ≠ correction.** Le rollback change ce qui tourne, pas le dépôt : `main` contenait toujours le commit cassé, et le prochain push l'aurait reconstruit. La correction passe par `git revert`, qui annule l'erreur dans un nouveau commit et garde la trace de l'incident.
- **Webhook signé.** Forgejo envoie `X-Gitea-Signature`, un HMAC-SHA256 du contenu calculé avec le secret partagé. Coolify refuse un appel dont la signature ne correspond pas : connaître l'URL ne suffit pas pour déclencher un déploiement.
- **Ressources** (`docker stats`, au repos) : portfolio 40 Mio, Forgejo 151 Mio, pile Coolify ≈ 512 Mio. La plateforme consomme plus de dix fois la RAM de l'application qu'elle déploie, d'où les 4 Go recommandés.

## 4. Partie E – Comparaison des approches de déploiement

| Critère | TP1 : Ansible + Semaphore | TP2 : Coolify + Forgejo | TP3 : GitHub Actions + Render |
|---|---|---|---|
| Type | Configuration de serveur (IaC) | PaaS auto-hébergé | CI/CD + PaaS managé |
| Ce qu'on écrit | Playbook, rôles, templates | Rien côté plateforme (Dockerfile de l'app) | Workflow YAML |
| Exécution de l'app | PM2 + Nginx directement sur l'OS | Conteneur Docker derrière Traefik | Conteneur/service géré par Render |
| Déclenchement | Manuel (CLI ou bouton Semaphore) | Automatique (webhook sur push) | Automatique (push GitHub) |
| Rollback | Relancer le playbook sur une version (`app_version`), avec rebuild | Un clic, image existante, ≈ 7 s | Un clic sur un déploiement précédent |
| HTTPS / domaine | À configurer (Nginx, Certbot) | Automatique avec un vrai domaine (Let's Encrypt via Traefik) | Automatique (sous-domaine fourni) |
| Infrastructure à maintenir | Serveur cible + machine de contrôle | La VM, Docker, Coolify et Forgejo | Aucune |
| Coût / dépendance | Gratuit, aucun fournisseur | Gratuit, aucun fournisseur | Offre gratuite limitée, dépend de GitHub et Render |
| Contrôle et transparence | Maximal : chaque étape est écrite | Moyen : la plateforme décide du build et du routage | Faible sur l'hébergement |
| Courbe d'apprentissage | La plus forte (Ansible, Linux) | Faible (interface web) | Moyenne (syntaxe des workflows) |

**Bilan :** Ansible convient pour maîtriser précisément la configuration d'un serveur et la rendre reproductible ; Coolify apporte l'expérience d'un PaaS (push = déploiement, rollback instantané) en gardant les données et l'infrastructure chez soi ; la solution managée supprime toute maintenance d'infrastructure, en échange d'une dépendance à des services externes.

## 5. Difficultés rencontrées et solutions

| Problème | Cause | Solution |
|---|---|---|
| IP `192.168.56.10` de l'énoncé déjà utilisée | VM `web1` d'un TP précédent | VM sur `192.168.56.70`, port SSH fixe 2205 |
| Coolify affiche des URL en `197.244.100.129` (domaine `sslip.io`, URL de webhook) | Coolify détecte l'IP publique de la box, injoignable depuis le réseau privé | Domaine remplacé par `portfolio.coolify.local` ; webhook configuré avec `192.168.56.70` |
| Proxy signalé « Attention required » | Le proxy lancé par l'installateur n'était pas encore géré par l'interface | **Start Proxy** sur le serveur `localhost` |
| « Invalid repository URL » | Espaces invisibles collés avant `http://` | URL retapée au clavier, suffixe `.git` |
| Domaine proposé en `https` et variante `www` ajoutée | Réglages par défaut de Coolify | Protocole `http` (pas de certificat possible pour un nom local), entrée `www` supprimée |
| Badge « DNS mismatch » | Coolify interroge le DNS public, qui ne connaît pas `portfolio.coolify.local` | Sans effet : le nom est résolu par le fichier `hosts` du poste |
| Accès refusé au fichier `hosts` | PowerShell non administrateur | `Start-Process powershell -Verb RunAs` |
| Adresses de clonage SSH fausses dans Forgejo | Port SSH 22 proposé par défaut | Port SSH `2222` dans l'assistant (port publié par Docker) |
| `docker` refusé pour l'utilisateur `vagrant` | `vagrant` n'est pas dans le groupe `docker` | Commandes Docker lancées avec `sudo` |
| Premier build long (4 min 50 s) | Connexion lente pendant `npm ci` | Les builds suivants réutilisent le cache Docker (1 min 26 s) |

## 6. Sécurité

- Mots de passe (Coolify, Forgejo) et secret du webhook non versionnés ; le secret est copié sans être affiché.
- Inscriptions Forgejo désactivées : seul l'administrateur crée des comptes.
- `/data/coolify/source/.env` contient les clés de l'instance : à sauvegarder hors du serveur, jamais dans Git.
- Mot de passe Git conservé en mémoire seulement (`credential.helper cache`, 2 h), jamais écrit sur disque.

## 7. Conclusion

Le cycle complet d'un PaaS a été mis en place sans aucun service externe : forge Git, build d'image, routage par nom de domaine, déploiement automatique sur push, résistance à un build cassé et rollback en quelques secondes. Coolify masque Docker et Traefik derrière une interface simple ; les logs de déploiement et les labels Traefik générés permettent néanmoins de comprendre ce qu'il fait réellement.
