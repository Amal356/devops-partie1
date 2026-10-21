# DevOps & Cloud – Partie 1 : Déployer une application

**Étudiante :** Amal Jemli – Master DevOps et Cloud Computing
**Cours :** [Partie 1 – Déployer une application](https://docs.teknolabs.net/courses/devops-cloud/partie-1-deploiement-application/)

Ce dépôt regroupe les trois TP de la partie 1. Chaque TP a son dossier, avec son README, son rapport et ses captures.

| TP | Sujet | Outils | Dossier |
|---|---|---|---|
| TP1 | Déploiement d'un portfolio Next.js | Ansible, Semaphore UI, Nginx, PM2 | [tp1-ansible-semaphore](tp1-ansible-semaphore/) |
| TP2 | PaaS auto-hébergé et forge Git locale | Coolify, Forgejo, Traefik, webhook | [tp2-coolify-forgejo](tp2-coolify-forgejo/) |
| TP3 | CI/CD dans le cloud | GitHub Actions, Render | [tp3-github-actions-render](tp3-github-actions-render/) |

## Application déployée

Les trois TP déploient le même portfolio Next.js, issu du dépôt [Amal356/cv-devsecops](https://github.com/Amal356/cv-devsecops) (dossier `portfolio-next`), avec trois approches différentes :

- **TP1** : serveur configuré avec Ansible (infrastructure as code), exécution depuis Semaphore UI ;
- **TP2** : plateforme PaaS auto-hébergée (Coolify) déclenchée par un webhook Forgejo ;
- **TP3** : pipeline GitHub Actions et hébergement managé sur Render.

## Infrastructure locale

VM VirtualBox créées avec Vagrant, sur le réseau privé `192.168.56.0/24` :

| VM | IP | Utilisée dans |
|---|---|---|
| ansible-admin | 192.168.56.20 | TP1 (machine de contrôle Ansible) |
| docker-vm | 192.168.56.30 | TP1 (Semaphore UI) |
| tp1-server | 192.168.56.50 | TP1 (serveur cible) |
| coolify-vm | 192.168.56.70 | TP2 (Coolify + Forgejo) |
