
import os
import sys
import asyncio
from fastapi import FastAPI, Depends
from fastapi.testclient import TestClient
from unittest.mock import MagicMock
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add project root to path
sys.path.append("/Users/cope/EnGardeHQ/production-backend")

# Setup DB connection
DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"
engine = create_engine(DATABASE_URL)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

# Mock user and tenant
mock_user = MagicMock()
mock_user.id = "user_123"
mock_user.email = "test@engarde.com"
mock_user.tenant_id = "f4185bad-e8d2-44a9-a16f-f5ab5f41a277" 

# Import the router and dependencies
from app.routers import campaign_spaces
from app.database import get_db
from app.routers.dashboard import get_current_tenant_id, get_current_user

# Create a test app
app = FastAPI()
app.include_router(campaign_spaces.router)

# Override dependencies
app.dependency_overrides[get_db] = override_get_db
app.dependency_overrides[get_current_user] = lambda: mock_user
app.dependency_overrides[get_current_tenant_id] = lambda: mock_user.tenant_id

client = TestClient(app)

def test_list_campaign_spaces():
    print("Testing list_campaign_spaces with limit=1000...")
    response = client.get("/api/campaign-spaces?limit=1000&tenant_id=f4185bad-e8d2-44a9-a16f-f5ab5f41a277")
    
    print(f"Status Code: {response.status_code}")
    if response.status_code != 200:
        print(f"Error Response: {response.text}")
    else:
        data = response.json()
        print(f"Success! Fetched {len(data['campaign_spaces'])} spaces.")

if __name__ == "__main__":
    test_list_campaign_spaces()
