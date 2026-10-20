#!/bin/bash
# Prérequis du TP1 : « serveur cible avec accès SSH par clé ».
# Crée l'utilisateur deploy, autorise la clé publique d'ansible-admin et donne sudo sans mot de passe.
# Tout le reste (Node.js, PM2, Nginx, application) est installé par le playbook Ansible.
set -e
CLE_ADMIN="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKaP+pUyYWhvOTVXqziMr1Q9yAxmjur2ew7XBPyTrnUp ansible-admin"

id deploy >/dev/null 2>&1 || useradd -m -s /bin/bash deploy
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
touch /home/deploy/.ssh/authorized_keys
grep -qxF "$CLE_ADMIN" /home/deploy/.ssh/authorized_keys || echo "$CLE_ADMIN" >> /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys

echo "deploy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/deploy
chmod 440 /etc/sudoers.d/deploy
visudo -cf /etc/sudoers.d/deploy

echo "Utilisateur deploy prêt sur $(hostname) (clé d'ansible-admin autorisée)"
