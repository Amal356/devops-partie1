# Rapport — TP1 : Ansible + Semaphore UI

**Nom :** ……………… **Date :** ……………… **Dépôt :** https://github.com/<user>/portfolio-deploy

## 1. Ce qui a été réalisé

Un playbook `site.yml` découpé en quatre rôles (`common`, `nodejs`, `app`, `nginx`) prépare une VM Ubuntu 24.04, installe Node.js 22 et PM2, clone le portfolio dans `/opt/portfolio`, le construit, le lance sur le port 3000 et l'expose sur le port 80 via un vhost Nginx généré par un template Jinja2. Toutes les valeurs (dépôt, version, port, nom d'hôte) sont dans `group_vars/all.yml`. L'exécution a ensuite été confiée à Semaphore UI (projet, clé SSH, dépôt, inventaire, groupe de variables, template avec survey `app_version`).

## 2. Idempotence

| Exécution | ok | changed | failed |
|---|---|---|---|
| 1er run | … | … | 0 |
| 2e run | … | **0** | 0 |

Le 2e run n'a rien modifié car : le cache apt n'est rafraîchi qu'une fois par heure, `npm ci`/`build` ne s'exécutent que si le dépôt Git a changé, PM2 n'est démarré que s'il ne gère pas déjà l'application, et les redémarrages (appli, Nginx) passent exclusivement par des **handlers**. (cf. `captures/idempotence.png`)

## 3. Redémarrage conditionnel

Après un commit sur le portfolio et une relance dans Semaphore, la tâche `git` passe en *changed*, ce qui déclenche `npm ci`, `npm run build` et le handler `Redémarrer le portfolio`. Une relance sans nouveau commit n'exécute aucun handler. (cf. `captures/semaphore-run.png`)

## 4. Apport de Semaphore

- Exécution sans poste de contrôle : n'importe qui avec un compte lance le déploiement depuis le navigateur.
- Secrets (clé SSH) chiffrés dans le Key Store au lieu de traîner sur les postes.
- Historique et logs de chaque exécution, survey pour choisir la branche/tag.

## 5. Difficultés rencontrées et solutions

- …
- …

## 6. Conclusion

…
