from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
import uvicorn

from backend.routes import router as api_router
from backend.utils.config import settings
from backend.utils.logger import logger
from backend.services.predictor import predictor_service
from backend.database import init_db
from backend.chatbot import chatbot_service

from fastapi.middleware.cors import CORSMiddleware

# Initialize FastAPI App
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="REST API for Sorghum (Jowar) crop disease detection and farmer chatbot support.",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# Enable CORS for Flutter and web client integrations
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permits all origins for development and demo clients
    allow_credentials=True,
    allow_methods=["*"],  # Allows all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all request headers
)

# Global Startup event
@app.on_event("startup")
def startup_event():
    """
    Executes tasks required when the application starts up,
    such as initializing the database and pre-loading ML/NLP models.
    """
    logger.info("Starting Crop Disease Detection FastAPI application...")
    try:
        # Initialize database
        init_db()
        
        # Pre-load prediction resources (model and classes)
        predictor_service.load_resources()
        
        # Pre-load chatbot resources (model and embeddings)
        chatbot_service.load_resources()
        
        logger.info("Application startup check: All resources loaded successfully.")
    except Exception as e:
        logger.critical(f"Application startup failed: Unable to load resources: {str(e)}")

# Global Exception Handlers
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """
    Global handler for Pydantic validation errors.
    Formats errors cleanly for clients.
    """
    logger.warning(f"Request validation failed for path {request.url.path}: {exc.errors()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "Validation Error",
            "details": exc.errors()
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """
    Global handler for unhandled exceptions.
    Prevents leaking internal stack traces in production.
    """
    logger.error(f"Unhandled error occurred at {request.url.path}: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Internal Server Error",
            "message": "An unexpected error occurred. Please try again later."
        }
    )

# Root Endpoint
@app.get("/", tags=["Root"])
async def root():
    """
    Root endpoint returning basic information about the API service.
    """
    return {
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "active",
        "documentation": "/docs"
    }

# Include routers
# Versioned API routes
app.include_router(api_router, prefix=settings.API_PREFIX, tags=["v1"])
# Direct top-level routes (to maintain compatibility with Phase specifications)
app.include_router(api_router, tags=["compatibility"])

if __name__ == "__main__":
    uvicorn.run("backend.app:app", host="0.0.0.0", port=8000, reload=True)
