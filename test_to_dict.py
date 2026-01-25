import sys
import os

# Add production-backend to path
backend_path = "/Users/cope/EnGardeHQ/production-backend"
if backend_path not in sys.path:
    sys.path.append(backend_path)

from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from app.models.campaign_space_models import CampaignSpace, CampaignAsset
from app.database import Base

DATABASE_URL = "postgresql://postgres:BTqoCVBmuTAIbtXCNauteEnyeAFHMzpo@switchback.proxy.rlwy.net:54319/railway"

def test_to_dict():
    engine = create_engine(DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    try:
        print("Fetching all campaign spaces...")
        spaces = db.query(CampaignSpace).all()
        print(f"Total spaces: {len(spaces)}")

        for space in spaces:
            try:
                # Eager load assets to mimic what to_dict would do
                _ = space.assets
                d = space.to_dict()
            except Exception as e:
                print(f"❌ Error in to_dict for space ID {space.id}: {e}")
                import traceback
                traceback.print_exc()
                # Continue checking others

        print("\nAll spaces checked.")
    finally:
        db.close()

if __name__ == "__main__":
    test_to_dict()
