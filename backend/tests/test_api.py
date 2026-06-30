import os
import sys
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add project root to python path to resolve imports correctly
sys.path.append("f:/myprojects/cropdetection/jowar-disease-detection")

from backend.app import app
from backend.database import Base, get_db, PredictionHistory
from backend.schemas import PredictionResponse

# Create a temporary SQLite database file for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///backend/test_predictions.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    """
    Overrides the database dependency to use the test SQLite database.
    """
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

# Apply the dependency override to the FastAPI app
app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

@pytest.fixture(scope="module", autouse=True)
def setup_database():
    """
    Fixture that automatically initializes the database tables
    before running tests, and drops them afterward.
    """
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)
    try:
        if os.path.exists("backend/test_predictions.db"):
            os.remove("backend/test_predictions.db")
    except Exception:
        pass

def test_root_endpoint() -> None:
    """
    Verifies that the root API endpoint returns successfully.
    """
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "active"
    assert "version" in data

def test_predict_invalid_file_extension() -> None:
    """
    Verifies that uploading a file with an invalid extension returns a 400 error.
    """
    file_payload = {"image": ("test.txt", b"dummy text content", "text/plain")}
    response = client.post("/predict", files=file_payload)
    assert response.status_code == 400
    assert "Invalid file extension" in response.json()["detail"]

def test_predict_invalid_image_data() -> None:
    """
    Verifies that uploading an invalid image file returns a 422 error.
    """
    file_payload = {"image": ("test.png", b"not a real image data", "image/png")}
    response = client.post("/predict", files=file_payload)
    assert response.status_code == 422
    assert "not a valid image" in response.json()["detail"]

def test_predict_valid_image() -> None:
    """
    Verifies the end-to-end ML prediction endpoint using a real test image.
    Checks that response matches validation schema and database logging succeeds.
    """
    image_path = "f:/myprojects/cropdetection/jowar-disease-detection/dataset/test/Rust/rust1.jpeg"
    assert os.path.exists(image_path), f"Test image not found at {image_path}"
    
    with open(image_path, "rb") as f:
        file_payload = {"image": ("rust1.jpeg", f, "image/jpeg")}
        response = client.post("/predict", files=file_payload)
        
    assert response.status_code == 200
    data = response.json()
    
    # Verify response matches Pydantic response schema keys
    assert data["crop"] == "Jowar"
    assert data["disease"] == "Rust"
    assert data["confidence"] > 50.0
    assert "symptoms" in data
    assert "treatment" in data
    assert "organic treatment" in data
    assert "chemical treatment" in data

def test_chatbot_chat_endpoint() -> None:
    """
    Verifies the chatbot semantic matching endpoint responses.
    """
    payload = {"question": "What is the ideal soil type for Sorghum cultivation?"}
    response = client.post("/chat", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "answer" in data
    assert "loamy" in data["answer"].lower() or "soil" in data["answer"].lower()

def test_history_endpoint() -> None:
    """
    Verifies that the /history endpoint retrieves predictions logged during tests.
    """
    response = client.get("/history")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    # At least the 1 valid prediction from test_predict_valid_image should be present
    assert len(data) >= 1
    assert data[0]["disease"] == "Rust"
    assert "image_path" in data[0]

def test_stats_endpoint() -> None:
    """
    Verifies dashboard statistics compile correctly.
    """
    response = client.get("/stats")
    assert response.status_code == 200
    data = response.json()
    assert data["total_predictions"] >= 1
    assert data["most_common_disease"] == "Rust"
    assert data["average_confidence"] > 50.0
    assert "Rust" in data["prediction_count_by_disease"]
