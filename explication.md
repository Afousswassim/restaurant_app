# Architecture et Fonctionnement de l'Application Wassim Food

Document de synthèse technique décrivant l'architecture logicielle, le flux de données de bout en bout et l'interaction entre le Frontend Flutter et le Backend Node.js / Express / MongoDB de l'application **Wassim Food**.

---

## 1. Vue Générale de l'Architecture

L'application **Wassim Food** repose sur une architecture client-serveur moderne et découplée. Le frontend mobile et web (développé avec Flutter) communique avec un serveur d'API REST (développé en Node.js et Express.js), lequel s'appuie sur une base de données NoSQL (MongoDB Atlas).

### Schéma de l'Architecture Réelle du Projet

```
┌─────────────────────────────────────────────────────────────────┐
│                       FRONTEND FLUTTER                          │
│                                                                 │
│   [ Views / Screens ]  <--->  [ Widgets ]                       │
│            │                                                    │
│            ▼                                                    │
│   [ State Management / Providers ]                              │
│   (MenuProvider, CartProvider, ClientProvider, OrderProvider)   │
│            │                                                    │
│            ▼                                                    │
│   [ Client Services ]                                           │
│   (ApiService using package:http)                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
                     HTTP / REST (JSON)
                     Bearer JWT Header
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                  BACKEND NODE.JS / EXPRESS                      │
│                                                                 │
│   [ Entry Point / Server ]                                      │
│   (server.js & config/database.js)                              │
│            │                                                    │
│            ▼                                                    │
│   [ Web Services / Routes ]                                     │
│   (menu.js, cart.js, orders.js, clients.js, adminRoutes.js)     │
│            │                                                    │
│            ▼                                                    │
│   [ Middleware ]                                                │
│   (authMiddleware.js, clientAuth.js, errorHandler.js)           │
│            │                                                    │
│            ▼                                                    │
│   [ Controllers / Services ]                                    │
│   (menuController.js, orderController.js, aiFoodAssistant.js)   │
│            │                                                    │
│            ▼                                                    │
│   [ Models (Mongoose ORM/ODM) ]                                 │
│   (MenuItem.js, Order.js, Client.js, Branch.js)                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                       Mongoose Protocol
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                    BASE DE DONNÉES MONGODB                      │
│   Collections: menu_items, orders, clients, branches, etc.     │
└─────────────────────────────────────────────────────────────────┘
```

### Rôle de chaque partie principale :
1. **Frontend Flutter (`lib/`)** : Gère l'interface utilisateur, la navigation, le mode sombre/clair, la capture des événements utilisateurs, la gestion de l'état réactif de l'application et la communication réseau vers l'API.
2. **REST API (HTTP / JSON)** : Sert de canal de communication sécurisé utilisant les verbes HTTP (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`) et transmettant des données structurées au format JSON.
3. **Backend Node.js / Express (`backend/`)** : Reçoit les requêtes HTTP, authentifie les utilisateurs via des jetons JWT, valide les corps de requêtes, exécute la logique métier de la restauration (calcul des totaux, application des coupons, attribution des points de fidélité, assistant IA) et interroge la base de données.
4. **Base de données MongoDB** : Assure la persistance des données sous forme de documents JSON/BSON dans des collections dédiées (`clients`, `orders`, `menu_items`, `branches`, `coupons`, `notifications`, `cart_items`).

---

## 2. Architecture Frontend Flutter

L'architecture du code source Flutter est organisée dans le dossier `lib/` selon le découpage fonctionnel suivant :

```
lib/
├── config/             # Configuration globale de l'application
│   └── app_config.dart # URL de base API (AppConfig.apiBaseUrl)
├── models/             # Classes de données métier (JSON Serializers)
│   ├── branch.dart, menu_item.dart, cart_item.dart, order.dart,
│   ├── client.dart, customer.dart, notification.dart, offer.dart,
│   └── category.dart, ai_recommendation.dart
├── services/           # Couche d'accès réseau aux services Web
│   └── api_service.dart # Classe ApiService gérant http.Client et JWT
├── providers/          # Couche de gestion d'état et contrôle applicatif
│   ├── menu_provider.dart, cart_provider.dart, client_provider.dart,
│   ├── order_provider.dart, branch_provider.dart, category_provider.dart,
│   ├── admin_provider.dart, notification_provider.dart, offers_provider.dart,
│   └── theme_provider.dart, ai_provider.dart
├── screens/            # Vues et écrans de l'interface utilisateur
│   ├── home_screen.dart, menu_screen.dart, cart_screen.dart,
│   ├── checkout_screen.dart, client_login_screen.dart,
│   ├── admin_dashboard_screen.dart, ai_food_assistant_screen.dart...
├── widgets/            # Composants graphiques réutilisables
│   ├── food_card.dart, app_drawer.dart, admin_stat_card.dart...
├── utils/              # Fonctions utilitaires et aides (SessionManager, Formats)
│   └── helpers.dart
├── data/               # Dossier réservé aux jeux de données locaux
└── main.dart           # Point d'entrée Flutter & injection MultiProvider
```

### Analyse détaillée des couches `lib/` :

#### A. `config/`
* **Responsabilité** : Stocke la configuration centralisée de l'application.
* **Exemple réél** : `AppConfig.apiBaseUrl` dans `lib/config/app_config.dart` définit l'adresse IP/URL du serveur Backend (`http://192.168.137.1:5000` ou Render) afin de permettre aux tests mobiles et web de pointer vers le même serveur.

#### B. `models/`
* **Responsabilité** : Définit les structures de données typées côté Dart avec constructeurs `fromJson` et méthodes `toJson` pour la sérialisation/désérialisation JSON.
* **Exemple réel** : `Branch.fromJson()` dans `lib/models/branch.dart` transforme la réponse JSON du serveur (`_id`, `name`, `deliveryFee`) en un objet Dart immutable.

#### C. `services/` (`ApiService`)
* **Responsabilité** : Constitue l'unique point d'accès HTTP entre Flutter et l'API Backend REST.
* **Exemple réel** : `lib/services/api_service.dart` contient la méthode privée `_makeRequest()` qui utilise le package `http`, applique le header `Authorization: Bearer <token>`, gère les délais de réponse (`timeoutDuration`), intercepte les codes d'erreur et convertit le corps JSON.

#### D. `providers/` (Gestion d'état et couche Contrôleur)
* **Responsabilité** : Les `Providers` étendent `ChangeNotifier`. Ils servent de couche intermédiaire de **contrôle et de gestion d'état** (State Management) :
  1. Stockage de l'état réactif (listes, indicateurs de chargement `isLoading`, messages d'erreur `error`).
  2. Appel des méthodes statiques de `ApiService`.
  3. Transformation et filtrage des données (ex: recherche textuelle, déduplication, filtrage par catégorie).
  4. Notification des vues graphiques via `notifyListeners()`.
  5. Sauvegarde locale des jetons d'authentification et sessions via `SharedPreferences`.

> **Note d'architecture** : Dans ce projet, les `Providers` jouent exactement le rôle de **Contrôleurs de présentation / State Controllers** dans le modèle architectural Flutter.

#### E. `screens/` & `widgets/`
* **Responsabilité** : Couche **VIEW**. Affiche l'interface graphique utilisateur (Material 3), s'abonne aux changements d'état via `Consumer<T>` ou `context.watch<T>()`, et déclenche des actions métier via `context.read<T>()`.
* **Exemple réel** : `MenuScreen` (`lib/screens/menu_screen.dart`) s'abonne à `MenuProvider` pour afficher la grille des plats (`FoodCard`).

---

## 3. Architecture Backend Node.js / Express

Le backend se situe dans le dossier `backend/` et applique la structure suivante :

```
backend/
├── config/
│   ├── database.js     # Connexion Mongoose à MongoDB Atlas
│   └── swagger.js      # Configuration OpenAPI 3.0 (swagger-ui-express)
├── models/             # Schémas et modèles de données Mongoose (MongoDB)
│   ├── Branch.js, MenuItem.js, CartItem.js, Order.js,
│   └── Client.js, Coupon.js, Notification.js, Category.js
├── middleware/         # Middleware de sécurité et gestion d'erreurs
│   ├── authMiddleware.js # Vérification JWT & rôles (requireAuth, requireAdmin)
│   ├── clientAuth.js     # Chaîne d'authentification client [requireAuth, requireClient]
│   └── errorHandler.js   # Middleware d'interception globale des erreurs HTTP
├── controllers/        # Logique métier et traitement des requêtes HTTP
│   ├── menuController.js, orderController.js, clientController.js,
│   ├── adminController.js, cartController.js, branchController.js,
│   └── aiController.js, offerController.js, couponController.js...
├── routes/             # Définition des endpoints REST et routage Express
│   ├── menu.js, orders.js, clients.js, cart.js, branches.js,
│   └── adminRoutes.js, offerRoutes.js, aiRoutes.js...
├── services/           # Modules de services algorithmiques dédiés
│   └── aiFoodAssistant.js # Algorithme d'intelligence artificielle pour recommandations
├── docs/openapi/       # Documentation Swagger OpenAPI (schemas & paths)
├── server.js           # Point d'entrée de l'application Express
└── package.json        # Dépendances Node.js
```

### Flux Backend Réel :
```
Requête HTTP (Flutter)
      │
      ▼
Routes Express (ex: routes/menu.js)
      │
      ▼
Middlewares (authMiddleware.js -> vérification du token JWT s'il est requis)
      │
      ▼
Controllers (ex: menuController.js -> validation des arguments)
      │
      ▼
Services Métier (ex: services/aiFoodAssistant.js si nécessaire)
      │
      ▼
Models Mongoose (ex: models/MenuItem.js -> requêtes à MongoDB)
      │
      ▼
Base de données MongoDB (collection menu_items)
```

---

## 4. Flux Complet des Données (Exemples Réels)

### Exemple 1 : Récupération du Menu d'une Succursale (`GET /menu/:branchId`)

```
[Utilisateur] -> Touche l'écran de sélection de branche dans Flutter
      │
 1. [View] MenuScreen (lib/screens/menu_screen.dart)
      │  Invoque loadMenu(branchId) dans son initState()
      ▼
 2. [Provider] MenuProvider (lib/providers/menu_provider.dart)
      │  Positionne _isLoading = true et appelle notifyListeners()
      ▼
 3. [Client Service] ApiService (lib/services/api_service.dart)
      │  Appelle ApiService.getMenuByBranch(branchId)
      │  _makeRequest('GET', '/menu/650000000000000000000001')
      ▼
 4. [REST API / Réseau] Requête HTTP GET vers http://192.168.137.1:5000/menu/650000000000000000000001
      │
      ▼
 5. [Express Route] routes/menu.js
      │  router.get('/:branchId', menuController.getMenuByBranch);
      ▼
 6. [Controller] menuController.getMenuByBranch (backend/controllers/menuController.js)
      │  Extrait branchId = req.params.branchId
      ▼
 7. [Model Mongoose] MenuItem (backend/models/MenuItem.js)
      │  Exécute MenuItem.find({ $or: [{ branchId: null }, { branchId }] })
      ▼
 8. [MongoDB] Collection `menu_items`
      │  Renvoie le curseur des documents JSON correspondants
      ▼
 9. [Controller / Response] menuController.js
      │  Renvoie res.status(200).json({ success: true, data: items })
      ▼
10. [Client Service] ApiService (lib/services/api_service.dart)
      │  Reçoit le corps JSON, vérifie success == true, désérialise chaque élément via MenuItem.fromJson()
      ▼
11. [Provider] MenuProvider (lib/providers/menu_provider.dart)
      │  Déduplique la liste, enregistre _menuItems, passe _isLoading = false et déclenche notifyListeners()
      ▼
12. [View / Rebuild] MenuScreen (lib/screens/menu_screen.dart)
      │  Le Consumer<MenuProvider> détecte la notification et re-dessine la grille des produits (FoodCard)
```

---

### Exemple 2 : Création d'une Commande Client (`POST /orders`)

```
[Utilisateur] -> Clique sur "Confirmer la commande" dans CheckoutScreen
      │
 1. [View] CheckoutScreen (lib/screens/checkout_screen.dart)
      │  Collecte l'adresse, le téléphone, le moyen de paiement et appelle OrderProvider.createOrder()
      ▼
 2. [Provider] OrderProvider (lib/providers/order_provider.dart)
      │  Lit la session et le panier actif, passe _isLoading = true, notifie la vue
      ▼
 3. [Client Service] ApiService.createOrder() (lib/services/api_service.dart)
      │  Formate le body JSON et effectue _makeRequest('POST', '/orders', body: {...})
      ▼
 4. [REST API / Network] Requête HTTP POST /orders avec Header Authorization: Bearer <token>
      │
      ▼
 5. [Express Route] routes/orders.js
      │  router.post('/', orderController.createOrder);
      ▼
 6. [Controller] orderController.createOrder (backend/controllers/orderController.js)
      │  - Vérifie la présence des champs obligatoires (customerName, phone, address, branch)
      │  - Lit la liste des CartItem associés au sessionId dans MongoDB
      │  - Calcule le sous-total, applique les offres et les frais de livraison
      ▼
 7. [Models & MongoDB Transactions]
      │  - Order.create({...}) -> Insère dans la collection `orders`
      │  - CartItem.deleteMany({ sessionId }) -> Vide le panier dans la collection `cart_items`
      │  - Client.findByIdAndUpdate(...) -> Incrémente les points de fidélité (loyaltyPoints)
      ▼
 8. [Response JSON]
      │  Renvoie res.status(201).json({ success: true, data: order })
      ▼
 9. [Client Service & Provider]
      │  ApiService transforme le JSON en objet Order via Order.fromJson()
      │  OrderProvider réinitialise l'état et CartProvider vide le panier local
      ▼
10. [View Navigation]
      │  CheckoutScreen redirige l'utilisateur vers OrderSuccessScreen (lib/screens/order_success_screen.dart)
```

---

## 5. Communication Frontend ↔ Backend

* **Bibliothèque HTTP** : Le frontend utilise le package officiel Dart `package:http/http.dart`.
* **Centralisation des requêtes** : Toutes les requêtes sont encapsulées dans la méthode statique générique `ApiService._makeRequest()` dans `lib/services/api_service.dart`.
* **Construction des requêtes et Headers** :
  * `Content-Type: application/json`
  * `Accept: application/json`
  * `Authorization: Bearer <JWT_TOKEN>` (si un jeton d'authentification est disponible).
* **Gestion du Timeout** : Chaque requête réseau applique une limite stricte de 30 secondes (`.timeout(Duration(seconds: 30))`).
* **Traitement des réponses et erreurs** :
  * Si `statusCode` est compris entre 200 et 299 et que `jsonResponse['success'] == true`, la fonction retourne la propriété `data`.
  * Si la réponse HTTP contient un code d'erreur (ex: 400, 401, 403, 404, 500) ou si `success == false`, une exception Dart typée est levée (`throw Exception(message)`).
  * Les exceptions réseau (ex: absence de connexion `SocketException`, `ClientException`) sont interceptées pour afficher un message clair à l'utilisateur.

---

## 6. Authentification et Sécurité (JWT)

L'authentification s'appuie sur des jetons **JWT (JSON Web Tokens)** signés avec l'algorithme HMAC-SHA256 (`jsonwebtoken`).

```
┌─────────────────┐           POST /clients/login          ┌─────────────────┐
│ Flutter App     │ ─────────────────────────────────────> │ Backend Express │
│ (ClientProvider)│                                        │(clientController│
│                 │ <───────────────────────────────────── │ & Client Model) │
└────────┬────────┘      JSON { success: true, token }     └─────────────────┘
         │
 1. Stockage local du jeton
    SharedPreferences.setString('client_token', token)
 2. Ingestion par ApiService
    ApiService.setClientToken(token)
         │
         │           Requête ultérieure sécurisée (ex: GET /clients/profile)
         │           Header 'Authorization: Bearer <token>'
         └─────────────────────────────────────────────────> ┌─────────────────┐
                                                             │ authMiddleware  │
                                                             │  (jwt.verify)   │
                                                             └─────────────────┘
```

1. **Création du Token** : Lors du login (`clientController.login` ou `adminController.login`), le serveur génère un jeton JWT contenant l'identifiant utilisateur `userId` et son rôle (`client` ou `admin`) via `jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' })`.
2. **Stockage côté Frontend** : `ClientProvider` sauvegarde le jeton de manière persistante sur l'appareil à l'aide de `SharedPreferences` sous la clé `client_token`.
3. **Transmission automatique** : `ClientProvider` appelle `ApiService.setClientToken(token)`. Toute requête ultérieure émise par `ApiService._makeRequest()` injecte automatiquement le header `Authorization: Bearer <token>`.
4. **Vérification côté Backend** : Le middleware `backend/middleware/authMiddleware.js` intercepte la requête, extrait le token du header `Authorization`, vérifie sa validité avec `jwt.verify(token, JWT_SECRET)`, puis attache l'utilisateur décodé à `req.user` et `req.client`.

---

## 7. Tableau des Responsabilités de Chaque Couche

| Couche | Technologie / Fichiers | Responsabilité Majeure | Exemples Concrets du Projet |
| :--- | :--- | :--- | :--- |
| **View / Screens** | Flutter Material (`lib/screens/`) | Affichage de l'UI, gestion des formulaires et réactions visuelles. | `MenuScreen`, `CartScreen`, `CheckoutScreen`, `AdminDashboardScreen` |
| **Widgets** | Flutter Components (`lib/widgets/`) | Éléments visuels réutilisables dans plusieurs écrans. | `FoodCard`, `AppDrawer`, `AdminStatCard` |
| **Providers** | Flutter Provider (`lib/providers/`) | Gestion d'état réactif, logique de présentation, notification de l'UI (`notifyListeners`). | `MenuProvider.loadMenu()`, `CartProvider.addToCart()`, `ClientProvider.login()` |
| **Client Services** | Dart `package:http` (`lib/services/`) | Communication HTTP/REST directe, sérialisation et injection du JWT Header. | `ApiService.getBranches()`, `ApiService.createOrder()`, `ApiService._makeRequest()` |
| **REST API / Routes** | Express Router (`backend/routes/`) | Déclaration des routes HTTP, association des verbes et middlewares. | `routes/menu.js`, `routes/orders.js`, `routes/adminRoutes.js` |
| **Middleware** | Express Middleware (`backend/middleware/`) | Contrôle d'accès, vérification du JWT, validation des rôles (`admin`/`client`). | `authMiddleware.js` (`requireAuth`, `requireAdmin`), `clientAuth.js` |
| **Controllers** | Express Controllers (`backend/controllers/`) | Logique métier du serveur, traitement des paramètres HTTP, envoi des réponses JSON. | `menuController.js`, `orderController.js`, `adminController.js` |
| **Backend Services** | Node.js modules (`backend/services/`) | Services algorithmiques spécialisés et helpers métier. | `aiFoodAssistant.js` (`generateFoodAssistantPlan()`) |
| **Models** | Mongoose ORM (`backend/models/`) | Définition des schémas de données, règles d'intégrité et requêtes MongoDB. | `MenuItem.js`, `Order.js`, `Client.js`, `Branch.js` |
| **MongoDB** | MongoDB Atlas / NoSQL DB | Persistance physique des documents dans les collections. | Collections `menu_items`, `orders`, `clients`, `cart_items` |

---

## 8. Résumé du Schéma de Flux Global

```
┌─────────────────────────────────────────────────────────────┐
│                         UTILISATEUR                         │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Action UI / Tap)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER VIEW (Screen)                   │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Appelle la méthode métier)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    PROVIDER (State Controller)              │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Exécute la requête HTTP)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   CLIENT SERVICE (ApiService)               │
└──────────────────────────────┬──────────────────────────────┘
                               │ (HTTP Request JSON + Bearer JWT)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    REST API / EXPRESS ROUTES                │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Vérification sécurité & jeton)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        MIDDLEWARE                           │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Traitement métier)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        CONTROLLER                           │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Calculs complexes / Algorithme)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      BACKEND SERVICE                        │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Requête ORM/ODM)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                       MONGOOSE MODEL                        │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Requête BSON physique)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      BASE MONGODB ATLAS                     │
└─────────────────────────────────────────────────────────────┘
```

### Explication du chemin Aller-Retour de la donnée :
1. **Chemin Aller (Requête)** : L'utilisateur interagit avec l'écran Flutter (ex: ajout au panier). La vue transmet l'événement au `CartProvider`. Le Provider bascule son état local en chargement (`isLoading = true`), puis sollicite `ApiService`. `ApiService` construit la requête HTTP REST, y adjoint les entêtes JSON et le jeton JWT, et l'envoie via le réseau. La route Express intercepte la requête, la fait passer par les middlewares de sécurité (`authMiddleware.js`), puis la transmet au contrôleur (`cartController.js`). Le contrôleur valide les arguments et exécute la commande via le modèle Mongoose (`CartItem.js`) qui écrit le document dans MongoDB Atlas.
2. **Chemin Retour (Réponse)** : MongoDB retourne le document mis à jour à Mongoose, qui le transmet au contrôleur. Le contrôleur encapsule le résultat dans une réponse JSON structurée (`{ success: true, data: ... }`). `ApiService` reçoit la réponse HTTP, valide le code de statut (200 OK), désérialise le JSON en objets Dart typés via `CartItem.fromJson()`, et les retourne au `CartProvider`. Enfin, `CartProvider` met à me jour son état local et appelle `notifyListeners()`, ce qui force la Vue Flutter (`CartScreen`) à se re-dessiner instantanément pour afficher le nouveau contenu du panier à l'utilisateur.

---

## 9. Relation avec le Diagramme d'Architecture du Rapport de PFE

Dans le cadre du rapport de projet de fin d'études (PFE), l'architecture implémentée correspond exactement aux blocs концепtuels suivants :

```
      FRONTEND FLUTTER                        BACKEND EXPRESS & MONGODB
┌──────────────────────────┐                ┌──────────────────────────┐
│         1. VIEW          │                │     1. WEB SERVICES      │
│  (Screens & Widgets)     │                │     (Express Routes)     │
└────────────┬─────────────┘                └────────────┬─────────────┘
             │                                           │
             ▼                                           ▼
┌──────────────────────────┐                ┌──────────────────────────┐
│      2. CONTROLLER       │                │ 2. CONTROLLERS/SERVICES  │
│  (ChangeNotifierProv.)   │                │ (Controllers & Services) │
└────────────┬─────────────┘                └────────────┬─────────────┘
             │                                           │
             ▼                                           ▼
┌──────────────────────────┐                ┌──────────────────────────┐
│   3. CLIENT SERVICES     │                │        3. MODELS         │
│      (ApiService)        │                │    (Mongoose & MongoDB)  │
└──────────────────────────┘                └──────────────────────────┘
```

### Correspondance exacte :
* **Côté Frontend Flutter** :
  1. **VIEW** = Dossiers `lib/screens/` et `lib/widgets/` (Interface utilisateur graphique).
  2. **CONTROLLER** = Dossier `lib/providers/` (Classes `ChangeNotifier` gérant l'état et la logique de présentation).
  3. **CLIENT SERVICES** = `lib/services/api_service.dart` (Client réseau HTTP effectuant les appels vers le serveur).

* **Côté Backend Node.js** :
  1. **WEB SERVICES** = Dossier `backend/routes/` et `server.js` (Exposition des points d'accès REST et middlewares).
  2. **CONTROLLERS / SERVICES** = Dossiers `backend/controllers/` et `backend/services/` (Logique applicative et algorithmique).
  3. **MODELS** = Dossier `backend/models/` et MongoDB (Modélisation de données Mongoose et persistance physique).

---

## 10. Correspondance Synthétique avec l'Architecture du Projet

Pour conclure et résumer la chaîne d'exécution pour votre rapport :

### Frontend Flutter :
$$\text{VIEW (Screens/Widgets)} \longrightarrow \text{CONTROLLER (Providers)} \longrightarrow \text{CLIENT SERVICES (ApiService)}$$

### Backend Node.js / Express / MongoDB :
$$\text{WEB SERVICES (Routes/Middleware)} \longrightarrow \text{CONTROLLERS / SERVICES} \longrightarrow \text{MODELS (Mongoose)} \longrightarrow \text{MongoDB Atlas}$$
