import json
import os
import cv2
import numpy as np
import uuid
import datetime
from fastapi import APIRouter, File, UploadFile, HTTPException, status, Depends
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from sqlalchemy import func

from backend.schemas import PredictionResponse, ChatRequest, ChatResponse, HistoryEntry, StatsResponse
from backend.services.predictor import predictor_service
from backend.chatbot import chatbot_service
from backend.utils.config import settings
from backend.utils.logger import logger
from backend.database import get_db, PredictionHistory

router = APIRouter()

# Global variable for disease info cache
_disease_info: Dict[str, Any] = {}

def get_disease_info() -> Dict[str, Any]:
    """
    Loads disease information metadata from disease_info.json.
    Caching the data in memory to avoid repeated disk reads.
    
    Returns:
        Dict[str, Any]: A dictionary containing disease metadata.
    """
    global _disease_info
    if not _disease_info:
        path = settings.DISEASE_INFO_PATH
        if not os.path.exists(path):
            logger.error(f"disease_info.json not found at {path}")
            return {}
        try:
            with open(path, "r") as f:
                _disease_info = json.load(f)
            logger.info("Disease info metadata loaded successfully.")
        except Exception as e:
            logger.error(f"Error reading disease_info.json: {str(e)}")
            return {}
    return _disease_info

@router.post(
    "/predict",
    response_model=PredictionResponse,
    status_code=status.HTTP_200_OK,
    summary="Predict crop disease from leaf/panicle image",
    description="Upload an image of a jowar leaf or panicle to detect the disease."
)
async def predict(image: UploadFile = File(...), db: Session = Depends(get_db)) -> PredictionResponse:
    """
    Predicts jowar crop disease from an uploaded image.
    
    Args:
        image (UploadFile): The uploaded image file.
        db (Session): Database session injected by dependency.
        
    Returns:
        PredictionResponse: A Pydantic model with prediction and disease details.
        
    Raises:
        HTTPException: For unsupported file formats, processing errors, or database/model errors.
    """
    # 1. Validate file extension
    allowed_extensions = {".jpg", ".jpeg", ".png", ".webp"}
    filename = image.filename or "unknown"
    _, ext = os.path.splitext(filename.lower())
    if ext not in allowed_extensions:
        logger.warning(f"File {filename} rejected due to invalid extension {ext}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file extension {ext}. Supported types: {', '.join(allowed_extensions)}"
        )

    # 2. Read image bytes
    try:
        content = await image.read()
    except Exception as e:
        logger.error(f"Failed to read uploaded file: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to read the uploaded image file."
        )

    # 3. Decode image bytes to OpenCV format
    nparr = np.frombuffer(content, np.uint8)
    cv_img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if cv_img is None:
        logger.warning(f"Failed to decode image from upload: {filename}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Uploaded file is not a valid image or is corrupted."
        )

    # 4. Perform prediction
    try:
        disease_name, confidence_raw = predictor_service.predict(cv_img)
    except Exception as e:
        logger.error(f"Prediction service failure: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Inference engine failure: {str(e)}"
        )

    # 5. Fetch disease metadata
    disease_metadata = get_disease_info()
    info = disease_metadata.get(disease_name)
    if info is None:
        logger.warning(f"Metadata not found for disease: {disease_name}. Falling back to 'Unknown'.")
        info = disease_metadata.get("Unknown", {
            "description": "No information available.",
            "symptoms": "N/A",
            "causes": "N/A",
            "treatment": "N/A",
            "organic_treatment": "N/A",
            "chemical_treatment": "N/A",
            "prevention": "N/A",
            "severity": "UNKNOWN",
            "reference": "N/A"
        })

    # 6. Format confidence as percentage (e.g. 94.3)
    confidence_percentage = round(confidence_raw * 100, 1)

    # 7. Save uploaded image to disk
    os.makedirs(settings.UPLOADS_DIR, exist_ok=True)
    timestamp_str = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    unique_filename = f"{timestamp_str}_{uuid.uuid4().hex}{ext}"
    save_path = os.path.join(settings.UPLOADS_DIR, unique_filename)
    relative_image_path = f"uploads/{unique_filename}"

    try:
        with open(save_path, "wb") as buffer:
            buffer.write(content)
        logger.info(f"Saved prediction image to {save_path}")
    except Exception as e:
        logger.error(f"Failed to save prediction image to disk: {str(e)}")
        # Fallback path if saving fails
        relative_image_path = "uploads/failed_to_save.jpg"

    # 8. Save prediction history to SQLite database
    try:
        history_entry = PredictionHistory(
            filename=filename,
            crop="Jowar",
            disease=disease_name,
            confidence=confidence_percentage,
            image_path=relative_image_path
        )
        db.add(history_entry)
        db.commit()
        logger.info(f"Saved prediction to history with ID: {history_entry.id}")
    except Exception as e:
        logger.error(f"Failed to write prediction to history DB: {str(e)}")
        db.rollback()

    # 9. Construct and return response
    return PredictionResponse(
        crop="Jowar",
        disease=disease_name,
        confidence=confidence_percentage,
        description=info.get("description", ""),
        symptoms=info.get("symptoms", ""),
        causes=info.get("causes", ""),
        treatment=info.get("treatment", ""),
        organic_treatment=info.get("organic_treatment", info.get("organic treatment", "")),
        chemical_treatment=info.get("chemical_treatment", info.get("chemical treatment", "")),
        prevention=info.get("prevention", ""),
        severity=info.get("severity", "LOW"),
        reference=info.get("reference", "")
    )

@router.get(
    "/history",
    response_model=List[HistoryEntry],
    status_code=status.HTTP_200_OK,
    summary="Get prediction history",
    description="Retrieve all previously logged crop disease predictions."
)
async def get_history(db: Session = Depends(get_db)) -> List[HistoryEntry]:
    """
    Retrieves all crop disease prediction logs from the SQLite database.
    
    Args:
        db (Session): The SQLAlchemy database session.
        
    Returns:
        List[HistoryEntry]: A list of all historical prediction records.
    """
    try:
        records = db.query(PredictionHistory).order_by(PredictionHistory.timestamp.desc()).all()
        return records
    except Exception as e:
        logger.error(f"Failed to fetch prediction history: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve history logs."
        )

@router.post(
    "/chat",
    response_model=ChatResponse,
    status_code=status.HTTP_200_OK,
    summary="Ask the Farmer Chatbot",
    description="Ask a farming-related question and get answers from our localized FAQ database."
)
async def chat(payload: ChatRequest) -> ChatResponse:
    """
    Processes a farmer's question and returns the semantically closest FAQ answer.
    
    Args:
        payload (ChatRequest): The Pydantic request body containing the question.
        
    Returns:
        ChatResponse: The Pydantic response containing the chatbot's answer.
    """
    try:
        answer = chatbot_service.get_answer(payload.question)
        return ChatResponse(answer=answer)
    except Exception as e:
        logger.error(f"Chat route processing failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Chatbot processing engine failed."
        )

@router.get(
    "/stats",
    response_model=StatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get application stats",
    description="Retrieve disease prediction statistics and analytics for the dashboard."
)
async def get_stats(db: Session = Depends(get_db)) -> StatsResponse:
    """
    Calculates disease detection statistics from the prediction history table.
    
    Args:
        db (Session): The SQLAlchemy database session.
        
    Returns:
        StatsResponse: Aggregated analytics results.
    """
    try:
        # 1. Total predictions count
        total_predictions = db.query(PredictionHistory).count()
        
        # Default response if no predictions exist
        if total_predictions == 0:
            return StatsResponse(
                total_predictions=0,
                most_common_disease="None",
                average_confidence=0.0,
                latest_prediction=None,
                prediction_count_by_disease={}
            )

        # 2. Average confidence calculation
        avg_conf_raw = db.query(func.avg(PredictionHistory.confidence)).scalar()
        average_confidence = round(float(avg_conf_raw), 1) if avg_conf_raw is not None else 0.0

        # 3. Latest prediction entry
        latest_prediction = db.query(PredictionHistory).order_by(PredictionHistory.timestamp.desc()).first()

        # 4. Count of predictions grouped by disease
        disease_counts_query = db.query(
            PredictionHistory.disease, 
            func.count(PredictionHistory.id)
        ).group_by(PredictionHistory.disease).all()
        
        prediction_count_by_disease = {disease: int(count) for disease, count in disease_counts_query}

        # 5. Most common disease search
        most_common_disease = max(prediction_count_by_disease, key=prediction_count_by_disease.get)

        return StatsResponse(
            total_predictions=total_predictions,
            most_common_disease=most_common_disease,
            average_confidence=average_confidence,
            latest_prediction=latest_prediction,
            prediction_count_by_disease=prediction_count_by_disease
        )
    except Exception as e:
        logger.error(f"Failed to calculate dashboard statistics: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to compile dashboard statistics."
        )
