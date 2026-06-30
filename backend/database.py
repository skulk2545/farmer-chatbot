import datetime
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from typing import Generator

from backend.utils.config import settings
from backend.utils.logger import logger

# Declare SQLAlchemy base
Base = declarative_base()

class PredictionHistory(Base):
    """
    SQLAlchemy model representing the prediction history database table.
    Stores metadata about crop disease detection requests.
    """
    __tablename__ = "prediction_history"

    id = Column(Integer, primary_key=True, autoincrement=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow, index=True)
    filename = Column(String(255), nullable=False)
    crop = Column(String(100), nullable=False)
    disease = Column(String(100), nullable=False)
    confidence = Column(Float, nullable=False)
    image_path = Column(String(500), nullable=False)

    def to_dict(self) -> dict:
        """
        Converts the database object into a Python dictionary.
        """
        return {
            "id": self.id,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
            "filename": self.filename,
            "crop": self.crop,
            "disease": self.disease,
            "confidence": self.confidence,
            "image_path": self.image_path
        }

# Create SQLite database engine
# For SQLite, check_same_thread=False is required for multi-threaded FastAPI requests
engine = create_engine(
    settings.DATABASE_URL,
    connect_args={"check_same_thread": False} if settings.DATABASE_URL.startswith("sqlite") else {}
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def init_db() -> None:
    """
    Initializes the database by creating all declared tables.
    """
    logger.info("Initializing SQLite database and creating tables...")
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database initialized successfully.")
    except Exception as e:
        logger.critical(f"Database initialization failed: {str(e)}")
        raise e

def get_db() -> Generator:
    """
    Dependency generator yielding a database session for requests,
    ensuring cleanup and session closure after use.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
