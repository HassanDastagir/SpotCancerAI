from flask import Flask, render_template, redirect, url_for, request, session, flash
import sqlite3
import os
from werkzeug.utils import secure_filename
from werkzeug.security import generate_password_hash, check_password_hash
from model_utils import load_model, predict_image
import cv2
import re

app = Flask(__name__)
app.secret_key = 'your_secret_key_here'

# Configure upload folder
UPLOAD_FOLDER = 'static/uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Load your trained model
MODEL_PATH = 'models/Final_Model.h5'
os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
model = load_model(MODEL_PATH)

# Ensure upload folder exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

def init_db():
    db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "users.db")
    with sqlite3.connect(db_path) as conn:
        conn.execute('''CREATE TABLE IF NOT EXISTS users (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        username TEXT UNIQUE,
                        email TEXT UNIQUE,
                        password TEXT,
                        is_admin BOOLEAN DEFAULT FALSE,
                        google_id TEXT)''')
        conn.execute('''CREATE TABLE IF NOT EXISTS patient_records (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        username TEXT,  
                        image_path TEXT,
                        result_class TEXT,
                        result_confidence REAL,
                        result_description TEXT,
                        analysis_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP)''')
        conn.execute('''CREATE TABLE IF NOT EXISTS contact_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            subject TEXT,
            message TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_read BOOLEAN DEFAULT FALSE
        )''')


def create_admin_user():
    admin_username = "admin"
    admin_email = "admin@spotcancerai.com"
    admin_password = "admin123"  # Change this in production
    with sqlite3.connect("users.db") as conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM users WHERE username=?", (admin_username,))
        if not cur.fetchone():
            hashed_password = generate_password_hash(admin_password)
            conn.execute(
                "INSERT INTO users (username, email, password, is_admin) VALUES (?, ?, ?, ?)",
                (admin_username, admin_email, hashed_password, True)
            )


init_db()
create_admin_user()


@app.route('/')
def index():
    return redirect(url_for('select_panel'))


@app.route('/select-panel')
def select_panel():
    return render_template('select_panel.html')


@app.route('/login', methods=['GET', 'POST'])
def login():
    panel = request.args.get('panel', 'user')

    if request.method == 'POST':
        identifier = request.form['identifier']
        password = request.form['password']

        # Special admin login check
        if panel == 'admin':
            if identifier == "39917" and password == "spotcancerai":
                session['username'] = "admin"
                session['is_admin'] = True
                return redirect(url_for('admin_dashboard'))
            else:
                flash("Invalid admin credentials", "danger")
                return redirect(url_for('login', panel='admin'))

        # Regular user login
        with sqlite3.connect("users.db") as conn:
            cur = conn.cursor()
            # Check if identifier is email
            if re.match(r"[^@]+@[^@]+\.[^@]+", identifier):
                cur.execute("SELECT * FROM users WHERE email=?", (identifier,))
            else:
                cur.execute("SELECT * FROM users WHERE username=?", (identifier,))

            user = cur.fetchone()
            if user and check_password_hash(user[3], password):
                session['username'] = user[1]
                session['is_admin'] = bool(user[4])
                if panel == 'admin' and not session['is_admin']:
                    flash("You don't have admin privileges", "danger")
                    return redirect(url_for('login'))
                if session['is_admin']:
                    return redirect(url_for('admin_dashboard'))
                return redirect(url_for('home'))
            else:
                flash("Invalid credentials", "danger")
    return render_template('login.html', panel=panel)


@app.route('/update-password', methods=['POST'])
def update_password():
    if 'username' not in session:
        return redirect(url_for('login'))

    current_password = request.form.get('current_password')
    new_password = request.form.get('new_password')
    confirm_password = request.form.get('confirm_password')

    if new_password != confirm_password:
        flash("New passwords don't match", "danger")
        return redirect(url_for('profile'))

    with sqlite3.connect("users.db") as conn:
        cur = conn.cursor()
        cur.execute("SELECT password, google_id FROM users WHERE username=?", (session['username'],))
        user = cur.fetchone()

        if user[1]:  # Google user (no current password needed)
            hashed_password = generate_password_hash(new_password)
            cur.execute("UPDATE users SET password=? WHERE username=?",
                        (hashed_password, session['username']))
            conn.commit()
            flash("Password updated successfully!", "success")
        else:
            if not check_password_hash(user[0], current_password):
                flash("Current password is incorrect", "danger")
                return redirect(url_for('profile'))

            hashed_password = generate_password_hash(new_password)
            cur.execute("UPDATE users SET password=? WHERE username=?",
                        (hashed_password, session['username']))
            conn.commit()
            flash("Password updated successfully!", "success")

    return redirect(url_for('profile'))

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        username = request.form['username']
        email = request.form['email']
        password = request.form['password']

        try:
            with sqlite3.connect("users.db") as conn:
                hashed_password = generate_password_hash(password)
                conn.execute(
                    "INSERT INTO users (username, email, password) VALUES (?, ?, ?)",
                    (username, email, hashed_password)
                )
                flash("Signup successful, please login!", "success")
                return redirect(url_for('login'))
        except sqlite3.IntegrityError as e:
            if "username" in str(e):
                flash("Username already exists!", "danger")
            elif "email" in str(e):
                flash("Email already exists!", "danger")
    return render_template('signup.html')


@app.route('/home')
def home():
    if 'username' not in session:
        return redirect(url_for('login'))
    return render_template('home.html', username=session['username'], active_page='home')


@app.route('/analyze', methods=['GET', 'POST'])
def analyze():
    if 'username' not in session:
        return redirect(url_for('login'))

    result = None
    filename = None
    error = None

    if request.method == 'POST':
        if 'image' not in request.files:
            flash('No file selected', 'warning')
            return redirect(request.url)

        file = request.files['image']
        if file.filename == '':
            flash('No selected file', 'warning')
            return redirect(request.url)

        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(filepath)

            # Basic image validation
            try:
                img = cv2.imread(filepath)
                if img is None:
                    flash('Invalid image file', 'danger')
                    os.remove(filepath)
                    return redirect(request.url)

                if img.shape[0] < 64 or img.shape[1] < 64:
                    flash('Image too small (min 64x64 pixels)', 'warning')
                    os.remove(filepath)
                    return redirect(request.url)
            except Exception as e:
                flash('Error processing image', 'danger')
                if os.path.exists(filepath):
                    os.remove(filepath)
                return redirect(request.url)

            # Get prediction
            result = predict_image(model, filepath)

            # Handle different result cases
            if result is None:
                error = "Error processing image"
                flash(error, "danger")
            elif 'error' in result:
                error = result['error']
                flash(error, "warning")
            elif 'class_id' in result and result['class_id'] != 'unknown':
                # Only save to DB if we have a valid skin condition prediction
                with sqlite3.connect("users.db") as conn:
                    conn.execute('''INSERT INTO patient_records 
                                  (username, image_path, result_class, result_confidence, result_description)
                                  VALUES (?, ?, ?, ?, ?)''',
                                (session['username'], filename, result['class'],
                                 result['confidence'], result['description']))
                flash("Analysis complete", "success")
            else:
                error = "The image doesn't appear to show human skin or the condition couldn't be determined"
                flash(error, "warning")

    return render_template('analyze.html',
                         username=session['username'],
                         active_page='analyze',
                         result=result,
                         filename=filename,
                         error=error)
def allowed_file(filename):
    return '.' in filename and \
        filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route('/patient_records')
def patient_records():
    if 'username' not in session:
        return redirect(url_for('login'))

    username = session['username']
    with sqlite3.connect("users.db") as conn:
        conn.row_factory = sqlite3.Row
        cur = conn.cursor()
        cur.execute("SELECT * FROM patient_records WHERE username=? ORDER BY analysis_date DESC", (username,))
        records = cur.fetchall()

    return render_template('patient_records.html',
                           username=username,
                           active_page='patient_records',
                           records=records)


@app.route('/delete_record/<int:record_id>', methods=['POST'])
def delete_record(record_id):
    if 'username' not in session:
        return redirect(url_for('login'))

    username = session['username']
    with sqlite3.connect("users.db") as conn:
        cur = conn.cursor()
        cur.execute("SELECT image_path FROM patient_records WHERE id=? AND username=?",
                    (record_id, username))
        record = cur.fetchone()

        if record:
            image_path = record[0]
            cur.execute("DELETE FROM patient_records WHERE id=? AND username=?",
                        (record_id, username))
            conn.commit()

            try:
                os.remove(os.path.join(app.config['UPLOAD_FOLDER'], image_path))
            except FileNotFoundError:
                pass

            flash("Record deleted successfully.", "success")
        else:
            flash("Record not found or you don't have permission to delete it.", "danger")

    return redirect(url_for('patient_records'))


@app.route('/delete_all_records', methods=['POST'])
def delete_all_records():
    if 'username' not in session:
        return redirect(url_for('login'))

    username = session['username']
    with sqlite3.connect("users.db") as conn:
        cur = conn.cursor()
        cur.execute("SELECT image_path FROM patient_records WHERE username=?", (username,))
        records = cur.fetchall()

        cur.execute("DELETE FROM patient_records WHERE username=?", (username,))
        conn.commit()

        for record in records:
            try:
                os.remove(os.path.join(app.config['UPLOAD_FOLDER'], record[0]))
            except FileNotFoundError:
                pass

        flash("All records deleted successfully.", "success")

    return redirect(url_for('patient_records'))


@app.route('/admin/dashboard')
def admin_dashboard():
    if 'username' not in session or not session.get('is_admin'):
        return redirect(url_for('login'))

    with sqlite3.connect("users.db") as conn:
        conn.row_factory = sqlite3.Row
        cur = conn.cursor()

        # Get users
        cur.execute("SELECT * FROM users")
        users = cur.fetchall()

        # Get patient records (without image paths)
        cur.execute(
            "SELECT username, analysis_date, result_class, result_confidence FROM patient_records ORDER BY analysis_date DESC LIMIT 10")
        records = cur.fetchall()

        # Get messages
        cur.execute("SELECT * FROM contact_messages ORDER BY created_at DESC LIMIT 5")
        messages = cur.fetchall()

    return render_template('admin_dashboard.html',
                           users=users,
                           records=records,
                           messages=messages,
                           username=session['username'])

@app.route('/admin/message/<int:message_id>')
def view_message(message_id):
    if 'username' not in session or not session.get('is_admin'):
        return redirect(url_for('login'))

    with sqlite3.connect("users.db") as conn:
        conn.row_factory = sqlite3.Row
        # Mark as read
        conn.execute("UPDATE contact_messages SET is_read = TRUE WHERE id = ?", (message_id,))
        # Get the message
        cur = conn.cursor()
        cur.execute("SELECT * FROM contact_messages WHERE id = ?", (message_id,))
        message = cur.fetchone()
        conn.commit()

    return render_template('view_message.html',
                        message=message,
                        username=session['username'])


@app.route('/admin/delete-user/<int:user_id>', methods=['POST'])
def delete_user(user_id):
    if 'username' not in session or not session.get('is_admin'):
        return redirect(url_for('login'))

    with sqlite3.connect("users.db") as conn:
        cur = conn.cursor()
        cur.execute("SELECT image_path FROM patient_records WHERE username IN (SELECT username FROM users WHERE id=?)",
                    (user_id,))
        records = cur.fetchall()

        for record in records:
            try:
                os.remove(os.path.join(app.config['UPLOAD_FOLDER'], record[0]))
            except FileNotFoundError:
                pass

        cur.execute("DELETE FROM patient_records WHERE username IN (SELECT username FROM users WHERE id=?)", (user_id,))
        cur.execute("DELETE FROM users WHERE id=?", (user_id,))
        conn.commit()

    flash("User deleted successfully", "success")
    return redirect(url_for('admin_dashboard'))


@app.route('/logout')
def logout():
    session.pop('username', None)
    session.pop('is_admin', None)
    session.pop('google_token', None)
    flash("Logged out successfully.", "info")
    return redirect(url_for('select_panel'))


@app.route('/contact', methods=['GET', 'POST'])
def contact():
    if 'username' not in session:
        return redirect(url_for('login'))

    if request.method == 'POST':
        subject = request.form['subject']
        message = request.form['message']

        with sqlite3.connect("users.db") as conn:
            conn.execute(
                "INSERT INTO contact_messages (username, subject, message) VALUES (?, ?, ?)",
                (session['username'], subject, message)
            )
            conn.commit()

        flash("Your message has been sent to admin!", "success")
        return redirect(url_for('contact'))

    return render_template('contact.html',
                           username=session['username'],
                           active_page='contact')

@app.route('/profile')
def profile():
    if 'username' not in session:
        return redirect(url_for('login'))

    with sqlite3.connect("users.db") as conn:
        conn.row_factory = sqlite3.Row
        cur = conn.cursor()
        cur.execute("SELECT * FROM users WHERE username=?", (session['username'],))
        user = cur.fetchone()

    return render_template('profile.html',
                           username=session['username'],
                           active_page='profile',
                           user=user)


@app.route('/forgot-password', methods=['GET', 'POST'])
def forgot_password():
    if request.method == 'POST':
        identifier = request.form['identifier']
        new_password = request.form['new_password']
        confirm_password = request.form['confirm_password']

        if new_password != confirm_password:
            flash("Passwords don't match!", "danger")
            return redirect(url_for('forgot_password'))

        with sqlite3.connect("users.db") as conn:
            cur = conn.cursor()
            # Check if identifier is email
            if re.match(r"[^@]+@[^@]+\.[^@]+", identifier):
                cur.execute("SELECT * FROM users WHERE email=?", (identifier,))
            else:
                cur.execute("SELECT * FROM users WHERE username=?", (identifier,))

            user = cur.fetchone()

            if user:
                hashed_password = generate_password_hash(new_password)
                cur.execute("UPDATE users SET password=? WHERE id=?", (hashed_password, user[0]))
                conn.commit()
                flash("Password updated successfully! You can now login.", "success")
                return redirect(url_for('login'))
            else:
                flash("User not found!", "danger")

    return render_template('forgot_password.html')

if __name__ == '__main__':
    app.run(debug=True)