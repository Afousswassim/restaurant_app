# 🤖 Wassim Food — Machine Learning Recommendation Microservice

Ce service est un microservice autonome de recommandation de nourriture basé sur le **Content-Based Filtering (Filtrage basé sur le contenu)**, développé en **Python** avec **FastAPI**, **scikit-learn**, **pandas** et **numpy**. Il s'intègre au backend **Node.js / Express** de l'application mobile Wassim Food.

---

## 📚 Table des Matières
1. [Pourquoi le Content-Based Filtering ?](#1-pourquoi-le-content-based-filtering-)
2. [Données Utilisées](#2-données-utilisées)
3. [Prétraitement & Feature Engineering](#3-prétraitement--feature-engineering)
4. [Encodage Textuel par TF-IDF](#4-encodage-textuel-par-tf-idf)
5. [Normalisation des Caractéristiques Numériques](#5-normalisation-des-caractéristiques-numériques)
6. [Calcul de Similarité Cosinus (Cosine Similarity)](#6-calcul-de-similarité-cosinus-cosine-similarity)
7. [Construction du Profil Utilisateur](#7-construction-du-profil-utilisateur)
8. [Gestion du Cold Start (Nouveaux Utilisateurs)](#8-gestion-du-cold-start-nouveaux-utilisateurs)
9. [Limites du Modèle](#9-limites-du-modèle)
10. [Évolution vers un Système Hybride](#10-évolution-vers-un-système-hybride)
11. [Guide de Démarrage et Déploiement](#11-guide-de-démarrage-et-déploiement)

---

## 1. Pourquoi le Content-Based Filtering ?

Pour un projet de commande de nourriture en phase initiale ou PFE :
- Les métadonnées des plats (`MenuItem`) sont extrêmement riches (prix, calories, protéines, glucides, lipides, catégories, tags).
- Le nombre d'utilisateurs et l'historique de commandes de départ sont limités (*Sparsity Problem*).
- Le **Filtrage Collaboratif** pur échouerait en raison du manque de matrice d'interaction dense.
- Le **Content-Based Filtering** permet d'obtenir des recommandations précises dès la première commande d'un client et garantit que chaque recommandation est explicable par rapport aux attributs des produits consommés.

---

## 2. Données Utilisées

Le modèle interroge directement la base de données MongoDB Atlas :

* **Catalogue Produit (`menu_items`)** :
  - `name`, `description` (Texte descriptif)
  - `category` (Burger, Pizza, Crepe, Dessert, Drinks)
  - `price` (Prix DH)
  - `calories`, `protein`, `carbs`, `fat` (Valeurs nutritionnelles)
  - `tags` (ex: `['high-protein', 'healthy', 'budget']`)
  - `rating` (Note moyenne du plat)
* **Historique des Commandes (`orders`)** :
  - `clientId` (ID de l'utilisateur)
  - `items[].menuItemId` et `items[].quantity` (Plats et quantités achetés)

---

## 3. Prétraitement & Feature Engineering

Chaque produit $p$ est transformé en un vecteur numérique $\vec{V}_p$ combinant deux sous-espaces vectoriels :

$$\vec{V}_p = \left[ \mathbf{W}_{\text{text}} \cdot \vec{T}_p \quad \vert \quad \vec{N}_p \right]$$

---

## 4. Encodage Textuel par TF-IDF

Le texte combiné (Nom + Description + Catégorie + Tags) est vectorisé via `TfidfVectorizer` :

$$\text{TF-IDF}(t, d, D) = \text{TF}(t, d) \times \log \left( \frac{\vert D \vert}{\vert \{d \in D : t \in d\} \vert} \right)$$

Cela permet d'accorder une importance statistique supérieure aux termes spécifiques et caractéristiques de chaque plat (ex: `crispy`, `truffle`, `veggie`).

---

## 5. Normalisation des Caractéristiques Numériques

Les attributs numériques (`price`, `calories`, `protein`, `carbs`, `fat`, `rating`) ont des échelles très différentes. Ils sont normalisés à l'aide de `StandardScaler` (z-score normalization) :

$$z = \frac{x - \mu}{\sigma}$$

---

## 6. Calcul de Similarité Cosinus (Cosine Similarity)

Le score d'appariement entre le vecteur profil d'un utilisateur $\vec{U}_c$ et un vecteur produit $\vec{V}_p$ est calculé par le produit scalaire normalisé :

$$\text{CosineSimilarity}(\vec{U}_c, \vec{V}_p) = \frac{\vec{U}_c \cdot \vec{V}_p}{\|\vec{U}_c\|_2 \|\vec{V}_p\|_2} = \frac{\sum_{i=1}^{n} U_{c,i} V_{p,i}}{\sqrt{\sum_{i=1}^{n} U_{c,i}^2} \sqrt{\sum_{i=1}^{n} V_{p,i}^2}}$$

Le résultat produit un score entre $0.0$ et $1.0$.

---

## 7. Construction du Profil Utilisateur

Lorsqu'un client a un historique de commandes, son profil vectoriel $\vec{U}_c$ est la **moyenne pondérée par les quantités** des vecteurs des produits qu'il a précédemment achetés :

$$\vec{U}_c = \frac{\sum_{i=1}^{k} q_i \cdot \vec{V}_{p_i}}{\sum_{i=1}^{k} q_i}$$

Ainsi, si un client commande fréquemment un produit (ex: *Burger Combo* $\times 3$), les caractéristiques de ce produit influencent davantage son vecteur de préférence.

---

## 8. Gestion du Cold Start (Nouveaux Utilisateurs)

Pour un utilisateur sans historique ou non connecté :
1. Le modèle construit un **profil synthétique explicite** à partir des choix du formulaire (`nutritionGoal`, `foodPreference`, `budget`).
2. Les choix textuels sont vectorisés par le même transformateur TF-IDF.
3. Les valeurs nutritionnelles cibles (ex: fort taux de protéine pour `High Protein`, faible taux de lipides pour `Healthy`) sont estimées et normalisées.
4. Si aucune donnée n'est transmise, le système s'appuie sur un profil moyen pondéré par la note globale (`rating`) et la disponibilité.

---

## 9. Limites du Modèle

- **Sur-spécialisation (*Filter Bubble*)** : Le modèle privilégie les plats très similaires à ceux déjà consommés.
- **Absence de recommandation collaborative** : Ne prend pas en compte les préférences partagées entre utilisateurs similaires (ex: *Les clients qui ont acheté X ont aussi aimé Y*).

---

## 10. Évolution vers un Système Hybride

Pour une version future post-PFE :
1. Combiner la similarité de contenu avec la **Décomposition en Valeurs Singulières (SVD)** ou le **Filtrage Collaboratif Implicite (Matrix Factorization)**.
2. Formule hybride de scoring :

$$\text{Score}_{\text{Hybride}} = \alpha \cdot \text{Score}_{\text{Content}} + (1 - \alpha) \cdot \text{Score}_{\text{Collaborative}}$$

---

## 11. Guide de Démarrage et Déploiement

### Lancement en Local
```bash
# 1. Créer l'environnement virtuel et installer les dépendances
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

# 2. Entraîner le modèle initial depuis MongoDB Atlas
python train.py

# 3. Demarrer le serveur FastAPI Uvicorn
uvicorn main:app --reload --port 8000
```

### Déploiement sur Render (Web Service)
- **Environment** : Python 3.10+
- **Build Command** : `pip install -r ml_service/requirements.txt && python ml_service/train.py`
- **Start Command** : `uvicorn ml_service.main:app --host 0.0.0.0 --port $PORT`
