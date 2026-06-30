import logging
import sys
from backend.utils.config import settings

def setup_logger(name: str = "crop_detection") -> logging.Logger:
    """
    Configures and returns a standardized logger instance for the application.
    
    Args:
        name (str): The name of the logger. Default is "crop_detection".
        
    Returns:
        logging.Logger: The configured logger instance.
    """
    logger = logging.getLogger(name)
    
    # Avoid duplicate handlers if logger is already configured
    if not logger.handlers:
        logger.setLevel(settings.LOG_LEVEL.upper())
        
        # Create console handler with format
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(settings.LOG_LEVEL.upper())
        
        formatter = logging.Formatter(
            '[%(asctime)s] %(levelname)s in %(module)s (%(filename)s:%(lineno)d): %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        
        # Do not propagate to root logger to avoid duplicate log lines
        logger.propagate = False
        
    return logger

# Shared logger instance
logger = setup_logger()
