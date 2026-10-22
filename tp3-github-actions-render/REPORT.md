# Rapport – TP3 : CI/CD avec GitHub Actions et Render

**Nom :** Amal Jemli **Date :** 22/10/2026
**Dépôt :** https://github.com/Amal356/cicd-lab **Production :** https://cicd-lab-7t5s.onrender.com

## 1. Le pipeline, en mes mots

```
branche ─▶ git push ─▶ Pull Request ─▶ GitHub Actions « Verify » ─▶ ✅ ? ─▶ merge sur main
                              │                (npm ci + typecheck,           │
                              │                 tests, build)                 ▼
                              └─▶ Render : preview de la PR         CI relancée sur main ─▶ ✅
                                  (URL temporaire)                            │
                                                                              ▼
                                                     Render « After CI Checks Pass » ─▶ production
```

1. **On ne travaille jamais sur `main`.** Chaque changement part d'une branche (`feature/…`) et arrive par une Pull Request.
2. **La CI vérifie.** Le workflow `.github/workflows/ci.yml` lance le job **Verify** sur une machine propre (`ubuntu-latest`, Node 24) : `npm ci` puis `npm run verify` (`tsc --noEmit`, tests `node --test`, build `tsc`). C'est exactement la commande lancée en local avant chaque push : si elle passe chez moi, elle passe en CI.
3. **La règle impose.** Le ruleset **Protect main** (actif, sans contournement) exige une PR et le check **Verify** au vert. Une PR rouge ne peut pas être fusionnée, même par la propriétaire du dépôt ; push direct, force-push et suppression de `main` sont bloqués.
4. **Render livre.** Le service web (offre gratuite, Frankfurt) est relié au dépôt. Avec **Auto-Deploy : After CI Checks Pass**, Render attend que la CI soit verte sur le commit de `main` avant de construire (`npm ci && npm run build`) et de démarrer (`npm start`). Le health check `/api/health` valide le démarrage.
5. **La preview montre avant de fusionner.** Avec *Pull Request Previews : Automatic*, chaque PR obtient sa propre instance (`cicd-lab-pr-4-orh5.onrender.com`), supprimée à la fermeture de la PR.

## 2. Déroulement

| PR | Changement | Verify | Résultat |
|---|---|---|---|
| #1 | Ajout du workflow CI | ✅ 18 s | Fusionnée ; premier déploiement automatique |
| #2 | Phrase « Verified by GitHub Actions. Deployed on Render. » | ✅ 8 s, check **Required** | Fusionnée → CI sur `main` → Render *Deploy live* `c2d29f2` en ≈ 3 min, sans clic |
| #3 | Test `/api/version` écrit **avant** la route | ❌ 14 s (`404 !== 200`) | **Fusion bloquée** par le ruleset |
| #3 | + route `/api/version` | ✅ 9 s | Fusionnée → `{"version":"development"}` en production (`c766cf7`) |
| #4 | Phrase « Preview deployment » | ✅ | Preview en ligne, production inchangée ; preview supprimée après la fusion |

## 3. TP2 (Coolify + Forgejo) et TP3 (GitHub Actions + Render)

| | TP2 : PaaS auto-hébergé | TP3 : CI/CD + PaaS managé |
|---|---|---|
| Vérification avant déploiement | Aucune : un push déclenche un build, l'échec du build est le seul garde-fou | Tests, typage et build dans la PR ; déploiement seulement après une CI verte |
| Protection de `main` | Aucune | Ruleset : PR obligatoire, check **Verify** requis |
| Code cassé | Le build échoue, l'ancienne version reste en ligne | Il n'atteint jamais `main` |
| Test avant fusion | Impossible sans 2ᵉ environnement | Preview automatique par PR |
| Infrastructure | VM, Docker, Coolify, Forgejo à maintenir | Aucune |
| HTTPS / domaine | Nom local via le fichier `hosts`, pas de certificat | HTTPS et sous-domaine fournis |
| Limites | Ressources de la VM (≈ 0,5 Go pour Coolify) | Offre gratuite : mise en veille après inactivité (≈ 50 s au réveil), dépendance à GitHub et Render |

**Bilan :** le TP2 automatise le **déploiement** ; le TP3 automatise aussi la **décision** de déployer. La CI et le ruleset transforment « ça marche chez moi » en règle vérifiée à chaque changement.

## 4. Difficultés et solutions

| Problème | Solution |
|---|---|
| Le serveur avait Node 22 (utilisé par Jenkins), le TP demande Node 24 | Node 24 installé avec **nvm** pour l'utilisateur `amal` seulement ; Jenkins garde Node 22 |
| npm 11 affiche un avertissement sur les *install scripts* (esbuild) | Sans effet sur `npm ci` ni sur la CI ; avertissement laissé tel quel |
| Disque du serveur presque plein | Suppression des `node_modules` des anciens projets (≈ 2,5 Go libérés) |
| Message « Unauthorized » en créant le ruleset | Session GitHub expirée : page rechargée, ruleset recréé |
| Ruleset créé mais « does not target any resources » | Cible ajoutée : **Include default branch** (`main`) |
| Service Render gratuit endormi | Premier appel lent (≈ 50 s) ; normal sur l'offre gratuite |

## 5. Sécurité

- Le workflow n'a que `permissions: contents: read` : il ne peut rien modifier dans le dépôt.
- Aucun secret dans le dépôt ; le *Deploy Hook* de Render n'est ni affiché ni versionné.
- Bypass list vide : la règle s'applique aussi à l'administratrice.

## Captures

| Fichier | Contenu |
|---|---|
| `render-first-deploy.png` | Premier déploiement Render et `/api/health` |
| `actions-verify-pass.png` | Job Verify réussi |
| `render-auto-deploy.png` | Auto-Deploy : After CI Checks Pass |
| `ruleset-protect-main.png`, `ruleset-required-check.png` | Ruleset actif sur `main`, check Verify requis |
| `homepage-updated.png` | Page d'accueil modifiée par la PR #2 |
| `pr-failing-verify.png` | PR #3 : Verify ❌, fusion bloquée |
| `api-version.png` | `/api/version` en production |
| `preview-vs-production.png` | Preview de la PR #4 et production côte à côte |
