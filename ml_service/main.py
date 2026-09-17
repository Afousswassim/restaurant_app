import os
import joblib
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field

from database import fetch_client_orders, fetch_all_menu_items
from recommender import FoodRecommender

MODEL_DIR = os.path.join(os.path.dirname(__file__), 'models')
MODEL_FILE = os.path.join(MODEL_DIR, 'food_recommender.pkl')

app = FastAPI(
    title="Wassim Food ML Recommendation Service",
    description="Content-Based Machine Learning Recommendation Microservice for Wassim Food PFE",
    version="1.0.0"
)

# Global model instance
recommender_model: Optional[FoodRecommender] = None

def load_or_train_model() -> FoodRecommender:
    global recommender_model
    if recommender_model is not None:
        return recommender_model

    if os.path.exists(MODEL_FILE):
        try:
            recommender_model = joblib.load(MODEL_FILE)
            print(f"[ML Service] Loaded model binary from {MODEL_FILE}")
            return recommender_model
        except Exception as e:
            print(f"[ML Service] Warning: Error loading model file: {e}. Retraining...")

    print("[ML Service] Training new ML model instance...")
    items = fetch_all_menu_items()
    if not items:
        raise RuntimeError("Cannot train model: No menu items found in database")
    
    recommender_model = FoodRecommender()
    recommender_model.fit(items)
    
    os.makedirs(MODEL_DIR, exist_ok=True)
    try:
        joblib.dump(recommender_model, MODEL_FILE)
    except Exception as e:
        print(f"[ML Service] Warning: Could not save model binary: {e}")

    return recommender_model

@app.on_event("startup")
def startup_event():
    try:
        load_or_train_model()
    except Exception as e:
        print(f"[ML Service] Startup model init warning: {e}")


class PredictRequest(BaseModel):
    clientId: Optional[str] = Field(None, description="MongoDB Client ID")
    branchId: Optional[str] = Field(None, description="MongoDB Branch ID")
    goal: Optional[str] = Field(None, description="Nutrition goal (Healthy, High Protein, etc.)")
    budget: Optional[float] = Field(None, description="Maximum budget DH")
    people: Optional[int] = Field(1, description="Number of people")
    preference: Optional[str] = Field(None, description="Food preference (Burger, Pizza, etc.)")
    availableItems: Optional[List[Dict[str, Any]]] = Field(None, description="Optional available items list")

class RecommendationItemResponse(BaseModel):
    menuItemId: str
    score: float
    name: Optional[str] = None
    category: Optional[str] = None
    price: Optional[float] = None

class PredictResponse(BaseModel):
    success: bool
    model: str
    count: int
    recommendations: List[RecommendationItemResponse]

@app.get("/", tags=["Health"])
@app.get("/health", tags=["Health"])
def health_check():
    is_loaded = recommender_model is not None and recommender_model.is_fitted
    return {
        "status": "ok",
        "service": "wassim-food-ml-service",
        "version": "1.0.0",
        "model_loaded": is_loaded,
        "items_in_catalog": len(recommender_model.item_df) if is_loaded and recommender_model.item_df is not None else 0
    }

@app.post("/predict", response_model=PredictResponse, tags=["Prediction"])
def predict_recommendations(payload: PredictRequest):
    try:
        model = load_or_train_model()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"ML Model unavailable: {str(e)}"
        )

    orders = []
    if payload.clientId:
        try:
            orders = fetch_client_orders(payload.clientId)
        except Exception as e:
            print(f"⚠️ Warning: Failed to fetch user orders for {payload.clientId}: {e}")

    try:
        raw_predictions = model.predict(
            orders=orders,
            goal=payload.goal,
            preference=payload.preference,
            budget=payload.budget,
            branch_id=payload.branchId,
            top_n=15
        )

        formatted_recs = [
            RecommendationItemResponse(
                menuItemId=rec["menuItemId"],
                score=rec["score"],
                name=rec.get("name"),
                category=rec.get("category"),
                price=rec.get("price")
            )
            for rec in raw_predictions
        ]

        return PredictResponse(
            success=True,
            model="Content-Based Cosine Similarity",
            count=len(formatted_recs),
            recommendations=formatted_recs
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Prediction error: {str(e)}"
        )
