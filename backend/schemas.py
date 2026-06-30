from pydantic import BaseModel, Field
from datetime import datetime
from typing import Dict, Optional

class PredictionResponse(BaseModel):
    """
    Pydantic schema for the crop disease prediction response.
    """
    crop: str = Field(..., description="The name of the crop (e.g. Jowar)")
    disease: str = Field(..., description="The name of the detected disease or 'healthy'")
    confidence: float = Field(..., description="The confidence percentage of the prediction (0.0 to 100.0)")
    description: str = Field(..., description="A brief description of the disease")
    symptoms: str = Field(..., description="Common symptoms of the disease")
    causes: str = Field(..., description="Root causes of the disease")
    treatment: str = Field(..., description="General treatment instructions")
    organic_treatment: str = Field(default="", alias="organic treatment", description="Organic treatment methods")
    chemical_treatment: str = Field(default="", alias="chemical treatment", description="Chemical treatment methods")
    prevention: str = Field(..., description="Preventive measures to avoid the disease")
    severity: str = Field(..., description="Severity level of the disease")
    reference: str = Field(..., description="Scientific reference sources")

    model_config = {
        "populate_by_name": True,
        "json_schema_extra": {
            "example": {
                "crop": "Jowar",
                "disease": "Rust",
                "confidence": 94.3,
                "description": "Sorghum rust is a common foliage disease...",
                "symptoms": "Small, raised reddish-brown pustules...",
                "causes": "Caused by the fungus Puccinia purpurea...",
                "treatment": "Apply foliar fungicides...",
                "organic treatment": "Use sulfur dusts or copper-based organic fungicides...",
                "chemical treatment": "Spray Mancozeb or Propiconazole...",
                "prevention": "Plant rust-resistant cultivars...",
                "severity": "MEDIUM",
                "reference": "CABI Plantwise Knowledge Bank"
            }
        }
    }

class ChatRequest(BaseModel):
    """
    Pydantic schema for the chatbot query request.
    """
    question: str = Field(..., description="The farmer's question")

    model_config = {
        "json_schema_extra": {
            "example": {
                "question": "What is the best way to prevent sorghum rust?"
            }
        }
    }

class ChatResponse(BaseModel):
    """
    Pydantic schema for the chatbot query response.
    """
    answer: str = Field(..., description="The matched FAQ answer")

    model_config = {
        "json_schema_extra": {
            "example": {
                "answer": "To prevent sorghum rust, plant resistant crop varieties..."
            }
        }
    }

class HistoryEntry(BaseModel):
    """
    Pydantic schema representing a single prediction history record.
    """
    id: int = Field(..., description="The unique database ID of the prediction record")
    timestamp: datetime = Field(..., description="Timestamp of the prediction")
    filename: str = Field(..., description="The name of the uploaded image file")
    crop: str = Field(..., description="The crop name")
    disease: str = Field(..., description="The detected disease name")
    confidence: float = Field(..., description="The prediction confidence percentage")
    image_path: str = Field(..., description="The saved image file path")

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "id": 1,
                "timestamp": "2026-06-29T22:31:06.123456",
                "filename": "rust1.jpeg",
                "crop": "Jowar",
                "disease": "Rust",
                "confidence": 98.8,
                "image_path": "uploads/20260629_223106_a1b2c3d4.jpeg"
            }
        }
    }

class StatsResponse(BaseModel):
    """
    Pydantic schema for the dashboard analytics/stats endpoint response.
    """
    total_predictions: int = Field(..., description="Total number of disease predictions made")
    most_common_disease: str = Field(..., description="The disease name that has been predicted most frequently")
    average_confidence: float = Field(..., description="The average confidence percentage across all predictions")
    latest_prediction: Optional[HistoryEntry] = Field(None, description="The most recent prediction record")
    prediction_count_by_disease: Dict[str, int] = Field(..., description="Count of predictions grouped by disease name")

    model_config = {
        "json_schema_extra": {
            "example": {
                "total_predictions": 42,
                "most_common_disease": "Rust",
                "average_confidence": 88.5,
                "latest_prediction": {
                    "id": 10,
                    "timestamp": "2026-06-29T22:31:06.123456",
                    "filename": "rust1.jpeg",
                    "crop": "Jowar",
                    "disease": "Rust",
                    "confidence": 98.8,
                    "image_path": "uploads/20260629_223106_a1b2c3d4.jpeg"
                },
                "prediction_count_by_disease": {
                    "Rust": 25,
                    "healthy": 10,
                    "Anthracnose": 7
                }
            }
        }
    }
