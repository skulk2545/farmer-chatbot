from flask import Flask, request, jsonify, render_template
from model import Chatbot

app = Flask(__name__)
bot = Chatbot("data/faq.csv")  # path to your dataset

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/get", methods=["POST"])
def get_bot_response():
    user_input = request.json["msg"]
    reply = bot.get_response(user_input)
    return jsonify({"reply": reply})

if __name__ == "__main__":
    app.run(debug=True)
