import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """
    Centralized configuration settings for the Crop Disease Detection Application.
    Loads configurations from environment variables or .env file.
    """
    # API Settings
    APP_NAME: str = "Crop Disease Detection API"
    APP_VERSION: str = "1.0.0"
    API_PREFIX: str = "/api/v1"
    
    # Model Settings
    MODEL_PATH: str = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "models",
        "jowar_model_best.h5"
    )
    CLASSES_PATH: str = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "models",
        "classes.json"
    )
    DISEASE_INFO_PATH: str = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "disease_info.json"
    )
    FAQ_PATH: str = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "faq.json"
    )
    CHATBOT_MODEL: str = "all-MiniLM-L6-v2"
    DATABASE_URL: str = "sqlite:///" + os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "predictions.db"
    )
    UPLOADS_DIR: str = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "uploads"
    )
    IMG_SIZE: int = 224
    
    # Logging level
    LOG_LEVEL: str = "INFO"

    # Settings config
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

# Instantiate settings singleton
settings = Settings()
