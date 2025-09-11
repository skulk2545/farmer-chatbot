import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

class Chatbot:
    def __init__(self, faq_file):
        self.data = pd.read_csv(faq_file)
        self.questions = self.data["Question"].tolist()
        self.answers = self.data["Answer"].tolist()
        self.vectorizer = TfidfVectorizer()
        self.question_vectors = self.vectorizer.fit_transform(self.questions)

    def get_response(self, user_input):
        user_vec = self.vectorizer.transform([user_input])
        similarity = cosine_similarity(user_vec, self.question_vectors)
        idx = similarity.argmax()
        score = similarity[0][idx]
        if score < 0.2:  # threshold for unknown queries
            return "I am not sure, please consult your local agriculture officer."
        return self.answers[idx]
