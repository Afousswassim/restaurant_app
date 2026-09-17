import numpy as np
import pandas as pd
from typing import List, Dict, Any, Optional, Tuple
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import StandardScaler
from sklearn.metrics.pairwise import cosine_similarity

class FoodRecommender:
    """
    Content-Based Recommendation Engine for Wassim Food.
    Combines TF-IDF text vectorization and StandardScaler numerical feature normalization,
    and computes Cosine Similarity between user preference vectors and menu item feature vectors.
    """
    def __init__(self):
        self.tfidf = TfidfVectorizer(ngram_range=(1, 2), stop_words='english')
        self.scaler = StandardScaler()
        self.item_df: Optional[pd.DataFrame] = None
        self.feature_matrix: Optional[np.ndarray] = None
        self.item_id_map: Dict[str, int] = {}
        self.is_fitted = False

    def _prepare_text_feature(self, row: pd.Series) -> str:
        name = str(row.get('name', ''))
        description = str(row.get('description', ''))
        category = str(row.get('category', ''))
        tags_raw = row.get('tags', [])
        tags = ' '.join(tags_raw) if isinstance(tags_raw, list) else str(tags_raw)
        return f"{name} {description} {category} {tags}".lower()

    def fit(self, items: List[Dict[str, Any]]):
        """Fit TF-IDF and StandardScaler on the product catalog."""
        if not items:
            raise ValueError("Product catalog is empty")

        df = pd.DataFrame(items)
        df['_id_str'] = df['_id'].astype(str)
        self.item_df = df

        # Build ID mapping index
        self.item_id_map = {item_id: idx for idx, item_id in enumerate(df['_id_str'])}

        # 1. Text Feature Extraction (TF-IDF)
        text_corpus = df.apply(self._prepare_text_feature, axis=1)
        tfidf_matrix = self.tfidf.fit_transform(text_corpus).toarray()

        # 2. Numerical Feature Scaling
        num_cols = ['price', 'calories', 'protein', 'carbs', 'fat', 'rating']
        for col in num_cols:
            if col not in df.columns:
                df[col] = 0.0
            else:
                df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0.0)

        num_matrix = self.scaler.fit_transform(df[num_cols].values)

        # 3. Concatenate Text and Numerical Features
        # Weight text features slightly higher for category/flavor matching
        self.feature_matrix = np.hstack((tfidf_matrix * 1.5, num_matrix))
        self.is_fitted = True

    def build_user_profile_from_history(self, orders: List[Dict[str, Any]]) -> Optional[np.ndarray]:
        """
        Build a user feature profile vector by computing a quantity-weighted average
        of vectors of items purchased in past orders.
        """
        if not orders or not self.is_fitted or self.feature_matrix is None:
            return None

        purchased_counts: Dict[int, float] = {}

        for order in orders:
            items = order.get('items', [])
            for item in items:
                menu_item_id = str(item.get('menuItemId') or '')
                quantity = float(item.get('quantity') or 1)
                
                if menu_item_id in self.item_id_map:
                    idx = self.item_id_map[menu_item_id]
                    purchased_counts[idx] = purchased_counts.get(idx, 0.0) + quantity

        if not purchased_counts:
            return None

        # Weighted vector sum
        profile_vector = np.zeros(self.feature_matrix.shape[1])
        total_weight = 0.0

        for idx, count in purchased_counts.items():
            profile_vector += self.feature_matrix[idx] * count
            total_weight += count

        if total_weight > 0:
            profile_vector /= total_weight
            return profile_vector

        return None

    def build_cold_start_profile(
        self,
        goal: Optional[str] = None,
        preference: Optional[str] = None,
        budget: Optional[float] = None
    ) -> np.ndarray:
        """
        Build a synthetic preference vector for new users (Cold Start)
        based on explicit user input (nutrition goal, food preference, budget).
        """
        query_text = f"{preference or ''} {goal or ''}".strip().lower()
        
        # Text vector
        text_vec = self.tfidf.transform([query_text]).toarray() * 1.5

        # Target numerical feature estimates
        target_price = float(budget) if budget and budget > 0 else 50.0
        target_calories = 400.0
        target_protein = 20.0
        target_carbs = 45.0
        target_fat = 15.0
        target_rating = 4.8

        goal_norm = str(goal or '').lower()
        if 'high protein' in goal_norm:
            target_protein = 40.0
            target_calories = 550.0
        elif 'low calories' in goal_norm or 'healthy' in goal_norm:
            target_calories = 250.0
            target_fat = 5.0
        elif 'budget' in goal_norm:
            target_price = min(target_price, 40.0)

        num_vec = self.scaler.transform([[
            target_price, target_calories, target_protein, target_carbs, target_fat, target_rating
        ]])

        return np.hstack((text_vec, num_vec))[0]

    def predict(
        self,
        orders: Optional[List[Dict[str, Any]]] = None,
        goal: Optional[str] = None,
        preference: Optional[str] = None,
        budget: Optional[float] = None,
        branch_id: Optional[str] = None,
        top_n: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Generate recommendations ranked by Cosine Similarity score.
        """
        if not self.is_fitted or self.item_df is None or self.feature_matrix is None:
            raise ValueError("Model has not been fitted yet. Call fit() or load a saved model.")

        # 1. Obtain user vector (History > Synthetic Cold-Start > Default Catalog Vector)
        user_vector = self.build_user_profile_from_history(orders) if orders else None

        if user_vector is None:
            user_vector = self.build_cold_start_profile(goal=goal, preference=preference, budget=budget)

        # Reshape for sklearn cosine_similarity
        user_vector = user_vector.reshape(1, -1)

        # 2. Compute Cosine Similarity against all items
        similarities = cosine_similarity(user_vector, self.feature_matrix)[0]

        # 3. Filter and Sort Results
        results = []
        for idx, row in self.item_df.iterrows():
            item_branch = str(row.get('branchId', '')) if row.get('branchId') is not None else None
            
            # Optional branch filter in ML layer if provided
            if branch_id and item_branch and item_branch != 'null' and item_branch != branch_id:
                continue

            score = float(similarities[idx])
            # Normalize score to range [0.0, 1.0] for clean reporting
            norm_score = max(0.0, min(1.0, (score + 1.0) / 2.0 if score < 0 else score))

            results.append({
                'menuItemId': str(row['_id_str']),
                'name': str(row.get('name', '')),
                'category': str(row.get('category', '')),
                'price': float(row.get('price', 0)),
                'score': round(norm_score, 4)
            })

        # Sort descending by score
        results.sort(key=lambda x: x['score'], reverse=True)

        return results[:top_n]
