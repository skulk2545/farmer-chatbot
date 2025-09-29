from flask import Flask, request, jsonify, render_template, redirect, url_for, session, flash
import sqlite3
import os
from model import Chatbot
from googletrans import Translator

app = Flask(__name__)
app.secret_key = "supersecretkey"  # needed for sessions

DB_NAME = "users.db"
bot = Chatbot("data/faq.csv")
translator = Translator()

# ---------- Database Setup ----------
def init_db():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS users
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  username TEXT UNIQUE,
                  password TEXT,
                  location TEXT,
                  crop TEXT,
                  soil_type TEXT)''')
    conn.commit()
    conn.close()

init_db()

# ---------- User Model ----------
class User:
    def __init__(self, id, username, password, location, crop, soil_type):
        self.id = id
        self.username = username
        self.password = password
        self.location = location
        self.crop = crop
        self.soil_type = soil_type

# ---------- Routes ----------
@app.route("/")
def home():
    if "user_id" in session:
        return redirect(url_for("chat"))
    return redirect(url_for("login"))

@app.route("/signup", methods=["GET", "POST"])
def signup():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]
        location = request.form["location"]
        crop = request.form["crop"]
        soil_type = request.form["soil_type"]

        try:
            conn = sqlite3.connect(DB_NAME)
            c = conn.cursor()
            c.execute("INSERT INTO users (username, password, location, crop, soil_type) VALUES (?, ?, ?, ?, ?)",
                      (username, password, location, crop, soil_type))
            conn.commit()
            conn.close()
            flash("Signup successful! Please log in.", "success")
            return redirect(url_for("login"))
        except sqlite3.IntegrityError:
            flash("Username already exists. Try another one.", "danger")
            return redirect(url_for("signup"))

    return render_template("signup.html")

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        conn = sqlite3.connect(DB_NAME)
        c = conn.cursor()
        c.execute("SELECT * FROM users WHERE username=? AND password=?", (username, password))
        row = c.fetchone()
        conn.close()

        if row:
            user = User(row[0], row[1], row[2], row[3], row[4], row[5])
            session["user_id"] = user.id
            session["username"] = user.username
            flash("Login successful!", "success")
            return redirect(url_for("chat"))
        else:
            flash("Invalid username or password", "danger")
            return redirect(url_for("login"))

    return render_template("login.html")

@app.route("/chat")
def chat():
    if "user_id" not in session:
        flash("Please log in first.", "warning")
        return redirect(url_for("login"))
    return render_template("index.html", username=session["username"])

@app.route("/logout")
def logout():
    session.clear()
    flash("You have been logged out.", "info")
    return redirect(url_for("login"))

@app.route("/get", methods=["POST"])
def get_bot_response():
    if "user_id" not in session:
        return jsonify({"reply": "⚠ Please log in first."})

    data = request.json
    user_input = data.get("msg", "")
    lang = data.get("lang", "en")

    # Translate user input to English
    translated_input = translator.translate(user_input, src=lang, dest="en").text

    # Get bot response in English
    reply_en = bot.get_response(translated_input)

    # Translate reply back to user's language
    reply = translator.translate(reply_en, src="en", dest=lang).text

    return jsonify({"reply": reply})

# ---------- Run App ----------
if __name__ == "__main__":
    app.run(debug=True)
