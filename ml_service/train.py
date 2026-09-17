import os
import sys
import joblib
from database import fetch_all_menu_items
from recommender import FoodRecommender

MODEL_DIR = os.path.join(os.path.dirname(__file__), 'models')
MODEL_FILE = os.path.join(MODEL_DIR, 'food_recommender.pkl')

def train_and_export_model():
    """
    Fetch catalog items from MongoDB, train the FoodRecommender pipeline,
    and export the model binary using joblib.
    """
    print("[Train] Fetching product catalog from MongoDB Atlas...")
    items = fetch_all_menu_items()
    
    if not items:
        print("[Train] Error: No menu items found in database. Cannot train model.")
        sys.exit(1)
        
    print(f"[Train] Found {len(items)} menu items. Building feature vectors...")
    recommender = FoodRecommender()
    recommender.fit(items)
    
    os.makedirs(MODEL_DIR, exist_ok=True)
    joblib.dump(recommender, MODEL_FILE)
    
    print(f"[Train] SUCCESS: Model trained and saved to: {MODEL_FILE}")
    print(f"   - Catalog items: {len(items)}")
    print(f"   - Feature matrix shape: {recommender.feature_matrix.shape if recommender.feature_matrix is not None else 'N/A'}")


if __name__ == '__main__':
    train_and_export_model()
