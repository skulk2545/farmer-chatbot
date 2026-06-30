import os
import json
from typing import List, Dict, Any, Optional
from sentence_transformers import SentenceTransformer, util
import numpy as np

from backend.utils.config import settings
from backend.utils.logger import logger

class FarmerChatbot:
    """
    Farmer Chatbot service utilizing SentenceTransformers for local semantic search
    to match user questions with predefined FAQs.
    """
    def __init__(self) -> None:
        self.model: Optional[SentenceTransformer] = None
        self.faqs: List[Dict[str, str]] = []
        self.question_embeddings = None
        self.model_name: str = settings.CHATBOT_MODEL
        self.faq_path: str = settings.FAQ_PATH

    def load_resources(self) -> None:
        """
        Loads the SentenceTransformer model and precomputes FAQ embeddings.
        This is lazy-loaded to optimize performance.
        
        Raises:
            FileNotFoundError: If the FAQ JSON file is missing.
            Exception: For general errors during resource initialization.
        """
        if self.model is not None and len(self.faqs) > 0:
            return

        logger.info("Initializing chatbot resources...")

        # 1. Load FAQs
        if not os.path.exists(self.faq_path):
            error_msg = f"FAQ file not found at path: {self.faq_path}"
            logger.error(error_msg)
            raise FileNotFoundError(error_msg)

        try:
            with open(self.faq_path, "r") as f:
                self.faqs = json.load(f)
            logger.info(f"Loaded {len(self.faqs)} FAQs.")
        except Exception as e:
            logger.error(f"Failed to parse FAQ file: {str(e)}")
            raise e

        # 2. Load SentenceTransformer Model (downloads locally if not cached)
        try:
            logger.info(f"Loading SentenceTransformer model '{self.model_name}'...")
            self.model = SentenceTransformer(self.model_name)
            logger.info("SentenceTransformer model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load SentenceTransformer model: {str(e)}")
            raise e

        # 3. Precompute embeddings for all FAQ questions
        try:
            questions = [faq["question"] for faq in self.faqs]
            logger.info("Precomputing embeddings for FAQ questions...")
            self.question_embeddings = self.model.encode(questions, convert_to_tensor=True)
            logger.info("FAQ question embeddings precomputed successfully.")
        except Exception as e:
            logger.error(f"Failed to precompute FAQ embeddings: {str(e)}")
            raise e

    def get_answer(self, user_question: str) -> str:
        """
        Finds the best matching FAQ response using cosine similarity.
        
        Args:
            user_question (str): The question input by the farmer.
            
        Returns:
            str: The matched answer from the FAQ database.
        """
        if not user_question.strip():
            return "Please ask a valid question."

        try:
            self.load_resources()
        except Exception as e:
            logger.error(f"Chatbot failed to load resources: {str(e)}")
            return "Sorry, I am currently unable to load my chatbot brain. Please try again later."

        if self.model is None or self.question_embeddings is None:
            return "Sorry, the chatbot service is currently offline."

        try:
            # 1. Embed user question
            user_embedding = self.model.encode(user_question, convert_to_tensor=True)

            # 2. Compute Cosine Similarity
            similarities = util.cos_sim(user_embedding, self.question_embeddings)[0]

            # 3. Find the best match
            best_idx = int(np.argmax(similarities.cpu().numpy()))
            highest_score = float(similarities[best_idx].cpu().numpy())

            logger.info(f"Chatbot query: '{user_question}' -> Best match: '{self.faqs[best_idx]['question']}' (similarity: {highest_score:.4f})")

            # 4. Return response (apply a confidence threshold of 0.3 for relevance)
            if highest_score < 0.35:
                return "I'm sorry, I couldn't find a close match for your question in our database. Could you rephrase your question or ask about sorghum disease prevention, fertilizing, or watering?"

            return self.faqs[best_idx]["answer"]

        except Exception as e:
            logger.error(f"Error during chatbot matching: {str(e)}")
            return "An error occurred while processing your question. Please try again."

# Instantiate chatbot singleton
chatbot_service = FarmerChatbot()
