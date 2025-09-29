import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from googletrans import Translator

class Chatbot:
    def __init__(self, faq_file):
        self.data = pd.read_csv(faq_file)
        self.questions = self.data["Question"].tolist()
        self.answers = self.data["Answer"].tolist()
        self.vectorizer = TfidfVectorizer()
        self.question_vectors = self.vectorizer.fit_transform(self.questions)
        self.translator = Translator()

    def detect_language(self, text):
        try:
            detected = self.translator.detect(text)
            return detected.lang
        except Exception:
            return 'en'

    def translate_to_en(self, text):
        try:
            translated = self.translator.translate(text, src='auto', dest='en')
            return translated.text
        except Exception:
            return text

    def translate_from_en(self, text, dest_lang):
        try:
            if dest_lang == 'en':  # no need to translate
                return text
            translated = self.translator.translate(text, src='en', dest=dest_lang)
            return translated.text
        except Exception:
            return text

    def get_response(self, user_input):
        # Detect user language
        user_lang = self.detect_language(user_input)

        # Translate to English for matching
        user_input_en = self.translate_to_en(user_input)

        # Vectorize and compute similarity
        user_vec = self.vectorizer.transform([user_input_en])
        similarity = cosine_similarity(user_vec, self.question_vectors)
        idx = similarity.argmax()
        score = similarity[0][idx]

        if score < 0.2:  # threshold for unknown queries
            response_en = "I am not sure, please consult your local agriculture officer."
        else:
            response_en = self.answers[idx]

        # Translate response back to user's language
        return self.translate_from_en(response_en, user_lang)
