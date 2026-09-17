import os
from typing import List, Dict, Any, Optional
from pymongo import MongoClient
from bson import ObjectId
from dotenv import load_dotenv


load_dotenv()

DEFAULT_MONGO_URI = "mongodb+srv://afousswassim:wassim10@cluster0.koafy.mongodb.net/food-delivery?appName=Cluster0"

_mongo_client_instance: Optional[MongoClient] = None

def get_mongo_client() -> MongoClient:
    global _mongo_client_instance
    if _mongo_client_instance is None:
        uri = os.getenv("MONGODB_URI", DEFAULT_MONGO_URI)
        _mongo_client_instance = MongoClient(uri, serverSelectionTimeoutMS=5000, connectTimeoutMS=5000)
    return _mongo_client_instance

def get_database():
    client = get_mongo_client()
    db = client.get_default_database()
    if db is None:
        db = client["food-delivery"]
    return db

def fetch_all_menu_items() -> List[Dict[str, Any]]:
    """Fetch all menu items from MongoDB 'menu_items' collection."""
    db = get_database()
    items = list(db["menu_items"].find({}))
    for item in items:
        item["_id"] = str(item["_id"])
        if "branchId" in item and item["branchId"] is not None:
            item["branchId"] = str(item["branchId"])
    return items

def fetch_client_orders(client_id: str, limit: int = 30) -> List[Dict[str, Any]]:
    """Fetch recent orders for a given client_id."""
    if not client_id:
        return []
    
    db = get_database()
    
    query_conditions = [{"clientId": client_id}]
    try:
        query_conditions.append({"clientId": ObjectId(client_id)})
    except Exception:
        pass

    orders = list(db["orders"].find({"$or": query_conditions}).sort("createdAt", -1).limit(limit))
    for order in orders:
        order["_id"] = str(order["_id"])
        if "clientId" in order and order["clientId"] is not None:
            order["clientId"] = str(order["clientId"])
    return orders

