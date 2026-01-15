# Système de Vote Décentralisé (Evaluation Finale)

Ce projet est une App de vote complète réalisée avec **Foundry** et **Solidity**.
Il inclut un système de workflow (Enregistrement, Vote, Fin), une gestion des rôles (Admin, Founder, Withdrawer) et la distribution automatique de **NFTs ("Voter Pass")** aux participants.

## 🔗 Déploiement sur Sepolia (Testnet)

Le projet est déployé et vérifié sur le réseau Sepolia.

- **NFT Contract (Voter Pass)** : [`0x7a53Bae20AE13D30be19E5fB5f2F3d916E08Ec58`](https://sepolia.etherscan.io/address/0x7a53Bae20AE13D30be19E5fB5f2F3d916E08Ec58)
- **Transaction de Déploiement** : [`0xa2be37e3cd2ebd85d0b6398852689fcafd7ad5167eeaa8e413b73a1d5fc9ded9`](https://sepolia.etherscan.io/tx/0xa2be37e3cd2ebd85d0b6398852689fcafd7ad5167eeaa8e413b73a1d5fc9ded9)

## 🛠 Fonctionnalités

1. **Workflow Sécurisé** : 4 statuts (Register, Found, Vote, Completed).
2. **Rôles** :
   - `Admin` : Gère le workflow.
   - `Founder` : Finance les candidats.
   - `Withdrawer` : Récupère les fonds à la fin.
3. **Timer de Sécurité** : Le vote ne s'ouvre qu'1h après le lancement de la session.
4. **NFT Voting** : Chaque votant reçoit un NFT unique qui empêche le double vote.
5. **Vainqueur** : Fonction pour désigner le gagnant automatiquement.

## 🧪 Tests

Les tests ont été réalisés avec Foundry :
- Scénario complet (Nominal).
- Tests de sécurité (Permissions, Timer).
- Tests NFT.

Commande pour lancer les tests :
```bash
forge test