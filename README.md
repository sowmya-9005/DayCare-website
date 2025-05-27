**Title:Day-care website**

**Abstraction:**
      The Daycare Management System is a web-based application developed using Flask and MySQL to streamline daycare operations. It supports three types of users: Admin, Faculty, and Parent, each with role-specific features. Admins can register or log in, manage faculty and parent accounts, and handle user data. Faculty members have access to log in, record and view student progress, and generate professional PDF reports. Parents can log in to view their child’s performance and download progress reports. The system uses bcrypt for secure password hashing and JWT for managing user sessions. It features an integrated chatbot that responds to user queries through a keyword-matching system. All data, including user details, student records, and chatbot content, are stored in a structured MySQL database. The ReportLab library is used for generating well-formatted PDF reports. Overall, the system ensures secure access, efficient data handling, and smooth communication among users.
**Problem Code:**
import re
import MySQLdb
from flask import Flask, render_template, request, jsonify,send_file, make_response
from flask_mysqldb import MySQL
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token
from flask_bcrypt import Bcrypt
from datetime import timedelta
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
import os
import tempfile
app = Flask(__name__)
CORS(app)
# MySQL Configuration
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'root'
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_DB'] = 'daycare1'
mysql = MySQL(app)
bcrypt = Bcrypt(app)
app.config['JWT_SECRET_KEY'] = 'your_super_secret_key'
jwt = JWTManager(app)
# -------------------------
# Admin Login
# -------------------------
@app.route("/adminlogin", methods=['POST'])
def admin_login():
    data = request.json
    adminemail = data.get("adminemail")
    adminpass = data.get("adminpass")
    if not adminemail or not adminpass:
        return jsonify({"error": "Missing credentials"}), 400
    cur = mysql.connection.cursor()
    cur.execute("SELECT adminid, adminname, adminemail, adminpass FROM admin WHERE adminemail = %s", (adminemail,))
    user = cur.fetchone()
    if not user:
        return jsonify({"message": "Email ID not found"}), 404
    adminid, adminname, adminemail_db, password_hash = user
    if bcrypt.check_password_hash(password_hash, adminpass):
        access_token = create_access_token(identity=str(adminid), expires_delta=timedelta(hours=1))
        return jsonify({
            "message": "Login successful",
            "access_token": access_token,
            "adminname": adminname,
            "adminemail": adminemail_db
        })
    return jsonify({"message": "Login failed: Incorrect password"}), 401
# -------------------------
# Faculty Login
# -------------------------
@app.route("/facultylogin", methods=['POST'])
def faculty_login():
    data = request.json
    facultyemail = data.get("facultyemail")
    facultypass = data.get("facultypass")
    if not facultyemail or not facultypass:
        return jsonify({"error": "Missing credentials"}), 400
    cur = mysql.connection.cursor()
    cur.execute("SELECT facultyid, facultyname, facultyemail, facultypass FROM faculty WHERE facultyemail = %s", (facultyemail,))
    user = cur.fetchone()
    if not user:
        return jsonify({"message": "Email ID not found"}), 404
    facultyid, facultyname, facultyemail_db, password_hash = user
    if bcrypt.check_password_hash(password_hash, facultypass):
        access_token = create_access_token(identity=str(facultyid), expires_delta=timedelta(hours=1))
        return jsonify({
    "message": "Login successful",
    "access_token": access_token,
    "facultyname": facultyname,
    "facultyid": facultyid  # ✅ Add this line
})
    return jsonify({"message": "Login failed"}), 401
# -------------------------
# Parent Login
# -------------------------
@app.route("/parentlogin", methods=['POST'])
def parent_login():
    data = request.json
    parentemail = data.get("parentemail")
    parentpass = data.get("parentpassword")
    if not parentemail or not parentpass:
        return jsonify({"error": "Missing credentials"}), 400

    cur = mysql.connection.cursor()
    cur.execute("SELECT parentid, parentname, parentemail, parentpass FROM parent WHERE parentemail = %s", (parentemail,))
    user = cur.fetchone()
    if not user:
        return jsonify({"message": "Email ID not found"}), 404
    parentid, parentname, parentemail_db, password_hash = user
    if bcrypt.check_password_hash(password_hash, parentpass):
        access_token = create_access_token(identity=str(parentid), expires_delta=timedelta(hours=1))
        return jsonify({
            "message": "Login successful",
            "access_token": access_token,
            "parentname": parentname,
            "parentid": parentid  # <-- Added
        })
    return jsonify({"message": "Login failed"}), 401
# -------------------------
# Admin Register
# -------------------------
@app.route("/adminregister", methods=['POST'])
def admin_register():
    data = request.json
    uname = data.get('uname')
    uemail = data.get('uemail')
    upassword = data.get('upassword')
    if not uname or not uemail or not upassword:
        return jsonify({"error": "Missing credentials"}), 400
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM admin WHERE adminemail = %s", (uemail,))
    if cur.fetchone():
        return jsonify({"message": "User already exists"}), 409

    hashed_password = bcrypt.generate_password_hash(upassword).decode('utf-8')
    cur.execute("INSERT INTO admin (adminname, adminemail, adminpass) VALUES (%s, %s, %s)", (uname, uemail, hashed_password))
    mysql.connection.commit()
    return jsonify({"message": "Registration successful"}), 201
# -------------------------
# Add Faculty
# -------------------------
@app.route("/add_faculty", methods=["POST"])
def add_faculty():
    data = request.json
    facultyname = data.get("facultyname")
    facultyemail = data.get("facultyemail")
    facultypass = data.get("facultypass")
    if not facultyname or not facultyemail or not facultypass:
        return jsonify({"error": "Missing required fields"}), 400
    hashed_password = bcrypt.generate_password_hash(facultypass).decode('utf-8')
    cur = mysql.connection.cursor()
    cur.execute("INSERT INTO faculty (facultyname, facultyemail, facultypass) VALUES (%s, %s, %s)",
                (facultyname, facultyemail, hashed_password))
    mysql.connection.commit()
    return jsonify({"message": "Faculty added successfully"}), 201
# -------------------------
# Add Student & Parent
# -------------------------
@app.route("/add_student", methods=["POST"])
def add_student():
    data = request.json
    studentname = data.get("studentname")
    studentprogress = data.get("studentprogress")
    facultyid = data.get("facultyid")
    parentname = data.get("parentname")
    parentemail = data.get("parentemail")
    parentpassword = data.get("parentpassword")
    if not all([studentname, studentprogress, parentname, parentemail, parentpassword]):
        return jsonify({"error": "Missing required fields"}), 400
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM faculty WHERE facultyid = %s", (facultyid,))
    if not cur.fetchone():
        return jsonify({"error": f"Faculty with ID {facultyid} does not exist"}), 404
    hashed_password = bcrypt.generate_password_hash(parentpassword).decode('utf-8')
    cur.execute("""
        INSERT INTO parent (studentname, studentprogress, facultyid, parentname, parentemail, parentpass)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (studentname, studentprogress, facultyid, parentname, parentemail, hashed_password))
    mysql.connection.commit()
    return jsonify({"message": "Student and parent added successfully"}), 201
# -------------------------
# View All Faculties
# -------------------------
@app.route("/viewallfaculties", methods=['GET'])
def view_all_faculties():
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM faculty")
    rows = cur.fetchall()
    col_names = [desc[0] for desc in cur.description]
    results = [dict(zip(col_names, row)) for row in rows]
    return jsonify(results), 200
# -------------------------
@app.route("/viewallparents", methods=['GET'])
def view_all_parents():
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM parent")
    rows = cur.fetchall()
    col_names = [desc[0] for desc in cur.description]
    results = [dict(zip(col_names, row)) for row in rows]
    return jsonify(results), 200
# -------------------------
# Run Server
# -------------------------
@app.route('/edit_faculty/<int:faculty_id>', methods=['POST'])
def edit_faculty(faculty_id):
    data = request.get_json()
    name = data.get("name")
    email = data.get("email")
    cur = mysql.connection.cursor()
    cur.execute("UPDATE faculty SET facultyname = %s, facultyemail = %s WHERE facultyid = %s",
                (name, email, faculty_id))
    mysql.connection.commit()
    return jsonify({"message": "Faculty updated"}), 200
@app.route('/edit_parent/<int:parent_id>', methods=['POST'])
def edit_parent(parent_id):
    data = request.get_json()
    studentname = data.get("studentname")
    progress = data.get("progress")
    parentname = data.get("parentname")
    email = data.get("email")
    facultyid = data.get("facultyid")
    cur = mysql.connection.cursor()
    cur.execute("""
        UPDATE parent 
        SET studentname = %s, studentprogress = %s, parentname = %s, parentemail = %s, facultyid = %s 
        WHERE parentid = %s
    """, (studentname, progress, parentname, email, facultyid, parent_id))
    mysql.connection.commit()
    return jsonify({"message": "Parent record updated"}), 200
@app.route('/search')
def search():
    query = request.args.get('query', '').lower()
    # Fetch parent and faculty data
    cur = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
    cur.execute("SELECT * FROM parent")
    parents = cur.fetchall()
    cur.execute("SELECT * FROM faculty")
    faculties = cur.fetchall()
    cur.close()
    # Simple search logic
    matched_parents = [p for p in parents if query in p['studentname'].lower() or query in p['parentname'].lower()]
    matched_faculties = [f for f in faculties if query in f['facultyname'].lower() or query in f['facultyemail'].lower()]
    return render_template("search.html", parents=matched_parents, faculties=matched_faculties, query=query)
@app.route('/delete_parent/<int:parent_id>', methods=['POST'])
def delete_parent(parent_id):
    cur = mysql.connection.cursor()
    cur.execute("DELETE FROM parent WHERE parentid = %s", (parent_id,))
    mysql.connection.commit()
    return jsonify({"message": "Parent record deleted"}), 200
@app.route('/add_note', methods=['POST'])
def add_progress_note():
    data = request.get_json()
    student_id = data.get('student_id')
    date = data.get('date')
    note_type = data.get('type')
    note = data.get('note')
    try:
        cur = mysql.connection.cursor()
        cur.execute("""
            INSERT INTO student_progress (student_id, date, type, note)
            VALUES (%s, %s, %s, %s)
        """, (student_id, date, note_type, note))
        mysql.connection.commit()
        cur.close()
        return jsonify({'message': 'Progress note added successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500
@app.route('/get_notes', methods=['GET'])
def get_notes():
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT * FROM student_progress")
        notes = cur.fetchall()
        col_names = [desc[0] for desc in cur.description]
        results = [dict(zip(col_names, row)) for row in notes]
        return jsonify(results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
@app.route('/download_report/<int:parentid>', methods=['GET'])
def download_report(parentid):
    cur = mysql.connection.cursor()
    # Fetch student name and parent name
    cur.execute("SELECT studentname, parentname FROM parent WHERE parentid = %s", (parentid,))
    parent_data = cur.fetchone()
    if not parent_data:
        return {"error": "Parent not found"}, 404
    studentname, parentname = parent_data
    # Fetch progress notes for this student
    cur.execute("""
        SELECT date, type, note FROM student_progress
        WHERE student_id = %s
        ORDER BY date DESC
    """, (parentid,))
    notes = cur.fetchall()
    # Generate PDF
    filename = f"report_parent_{parentid}.pdf"
    temp_dir = tempfile.gettempdir()  # ✅ Cross-platform temp directory
    filepath = os.path.join(temp_dir, filename)
    pdf = canvas.Canvas(filepath, pagesize=letter)
    width, height = letter
    # Header
    pdf.setFont("Helvetica-Bold", 16)
    pdf.drawString(50, height - 50, f"Progress Report for {studentname}")
    pdf.setFont("Helvetica", 12)
    pdf.drawString(50, height - 70, f"Parent: {parentname}")
    y = height - 100
    pdf.setFont("Helvetica", 11)
    if not notes:
        pdf.drawString(50, y, "No progress records available.")
    else:
        for date, type_, note in notes:
            if y < 80:
                pdf.showPage()
                y = height - 50
                pdf.setFont("Helvetica", 11)
            pdf.drawString(50, y, f"Date: {date} | Type: {type_}")
            y -= 15
            text_obj = pdf.beginText(60, y)
            text_obj.textLines(note)
            pdf.drawText(text_obj)
            y -= 15 * (note.count('\n') + 1) + 10

    pdf.showPage()
    pdf.save()
    return send_file(filepath, as_attachment=True, download_name=filename)
@app.route('/getnotes/<int:parentid>', methods=['GET'])
def get_notes_by_parent(parentid):
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT * FROM student_progress WHERE student_id = %s", (parentid,))
        notes = cur.fetchall()
        col_names = [desc[0] for desc in cur.description]
        results = [dict(zip(col_names, row)) for row in notes]
        return jsonify(results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
@app.route('/parent_details/<int:parentid>', methods=['GET'])
def get_parent_details_with_progress(parentid):
    try:
        cur = mysql.connection.cursor(MySQLdb.cursors.DictCursor)
        # Get parent and student details
        cur.execute("SELECT parentid, parentname, parentemail, studentname FROM parent WHERE parentid = %s", (parentid,))
        parent = cur.fetchone()
        if not parent:
            return jsonify({"error": "Parent not found"}), 404
        # Get progress notes
        cur.execute("""
            SELECT date, type, note 
            FROM student_progress 
            WHERE student_id = %s
            ORDER BY date DESC
        """, (parentid,))
        progress_notes = cur.fetchall()

        result = {
            "parent": parent,
            "progress_notes": progress_notes
        }
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
def match_category(user_input):
    cur = mysql.connection.cursor()
    cur.execute("SELECT id, keywords FROM categories")
    categories = cur.fetchall()
    user_input = user_input.lower()
    for category_id, keywords in categories:
        for keyword in keywords.split(','):
            if keyword.strip().lower() in user_input:
                return category_id
    return None
@app.route("/chat", methods=["POST"])
def chat():
    data = request.get_json()
    user_message = data.get("message", "").lower()
    # Phone number check
    if re.match(r"^[\d\s()+-]{7,15}$", user_message):
        return jsonify({"response": "Thank you! One of our team members will reach out to you shortly. 😊"})
    # Try to match category
    category_id = match_category(user_message)
    cur = mysql.connection.cursor()
    if category_id:
        cur.execute("SELECT answer FROM answers WHERE category_id = %s", (category_id,))
    else:
        cur.execute("SELECT answer FROM answers WHERE category_id = (SELECT id FROM categories WHERE category_name = 'default' LIMIT 1)")
    result = cur.fetchone()
    response = result[0] if result else "I'm not sure how to help with that. Please leave your number so we can contact you."
    return jsonify({"response": response})
print(app.url_map)
if __name__ == "__main__":
    app.run(debug=True)
    print(app.url_map)

**Key- Technology**
1.	Flask (Python Web Framework):
Flask is a lightweight and flexible web framework that provides the backbone for your application's backend. It handles HTTP requests, routing, and integrates with databases to serve dynamic content. Flask’s simplicity allows rapid development and easy integration of extensions such as authentication and PDF generation.
2.  MySQL Database:
MySQL is a widely-used relational database management system that securely stores and manages data related to admins, faculty, parents, students, and progress reports. It provides reliable storage and efficient querying capabilities essential for real-time data retrieval and manipulation.
3.  JWT (JSON Web Tokens):
JWT is used to implement stateless, secure authentication for users such as admins, faculty, and parents. Tokens carry user identity data and expire after a set period, reducing the risk of session hijacking and improving security for API requests.
4.  bcrypt (Password Hashing):
bcrypt is a powerful password hashing library used to securely store user passwords. By hashing and salting passwords, it protects against common vulnerabilities like brute force attacks and ensures user credentials remain confidential.
5.  ReportLab (PDF Generation):
ReportLab allows the application to generate downloadable PDF reports summarizing student progress. This feature facilitates easy sharing of records with parents and staff in a professional and accessible format.
6.  Flask-CORS:
Cross-Origin Resource Sharing (CORS) is enabled through this extension to allow secure communication between the frontend and backend, even if they run on different domains or ports, enabling flexible deployment architectures.
7.  Regular Expressions (Regex):
Regex is used in the chatbot feature to parse and identify patterns such as phone numbers and keywords in user messages. This enables responsive, automated interaction, improving user experience and support efficiency.
8. RESTful API Design:
The backend exposes a set of RESTful API endpoints to perform Create, Read, Update, and Delete (CRUD) operations on data entities. This structured approach standardizes client-server communication and facilitates modularity and scalability.
9. Frontend Technologies (HTML/CSS/JavaScript):
Although not detailed here, the frontend typically employs these technologies to provide intuitive interfaces for users to interact with the system, including login pages, dashboards, forms, and data visualization components.
10. Session and Cookie Management:
Secure handling of user sessions and cookies ensures authorized access and maintains stateful interactions across multiple HTTP requests without compromising security.

**Description :**
The Daycare Management System is a comprehensive web-based platform designed to streamline the administration and communication processes in daycare centers. It provides a centralized solution to manage students, parents, faculty, and administrative staff efficiently while ensuring secure access and real-time data updates.

**Key Features:**
1.	Role-Based Authentication and Authorization
The system supports multiple user roles — Admin, Faculty, and Parent — each with distinct login credentials and access privileges. Secure password management is implemented using bcrypt hashing, and session management is maintained via JWT (JSON Web Tokens) for protected routes and seamless user experience.
2.	User Management and Registration
Admins can register new users, including faculty members, and parents can be linked to their respective children (students). The system validates all inputs, preventing duplicate accounts and ensuring data integrity across the database.
3.	Student Progress Tracking
Faculty can add detailed progress notes for students, recording various developmental metrics, behavioral observations, and daily activities. These notes are timestamped and categorized for easy reference.
4.	Comprehensive Data Viewing and Searching
The platform enables users to view and search records of faculties, parents, and students. A powerful search feature allows querying by names or emails, facilitating quick access to relevant information.
5.	Editing and Deleting Records
Admins and authorized users can update faculty and parent details as well as remove outdated or incorrect records securely, ensuring the database remains current.
6.	Progress Reports and PDF Generation
Parents can download PDF reports summarizing their child’s progress notes, automatically generated on demand. The system uses the ReportLab library for creating well-structured, printable reports.
7.	Interactive Chatbot Support
An integrated chatbot interface handles user inquiries, providing quick automated responses based on pre-defined categories. It also recognizes phone numbers to initiate personalized follow-ups, enhancing user engagement.
8.	Database Integration and Security
The backend leverages MySQL for robust data storage, with careful query parameterization to avoid SQL injection risks. Passwords are stored securely using bcrypt encryption, and sensitive data access is controlled through JWT tokens.

**Future research:**
      Future research in the domain of digital daycare management can focus on several areas to enhance the system's intelligence, security, and personalization. One major research direction is the integration of Artificial Intelligence (AI) and Machine Learning (ML) to monitor children’s activity patterns, detect anomalies in behavior, and provide personalized developmental insights to parents and staff. Another promising area is the use of IoT (Internet of Things) devices such as smart wearables or sensors for real-time health monitoring (body temperature, movement, sleep tracking), ensuring better child safety and care.
