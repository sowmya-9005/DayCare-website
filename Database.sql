CREATE DATABASE daycare;
USE daycare;
CREATE TABLE admin (
    adminid INT AUTO_INCREMENT PRIMARY KEY,
    adminname VARCHAR(100) NOT NULL,
    adminemail VARCHAR(100) UNIQUE NOT NULL,
    adminpass VARCHAR(255) NOT NULL
);
CREATE TABLE faculty (
    facultyid INT AUTO_INCREMENT PRIMARY KEY,
    facultyname VARCHAR(100) NOT NULL,
    facultyemail VARCHAR(100) UNIQUE NOT NULL,
    facultypass VARCHAR(255) NOT NULL
);
CREATE TABLE parent (
    parentid INT AUTO_INCREMENT PRIMARY KEY,
    studentname VARCHAR(100) NOT NULL,
    studentprogress TEXT NOT NULL,
    facultyid INT,
    parentname VARCHAR(100) NOT NULL,
    parentemail VARCHAR(100) UNIQUE NOT NULL,
    parentpass VARCHAR(255) NOT NULL,
    FOREIGN KEY (facultyid) REFERENCES faculty(facultyid)
);
select * from faculty;
select * from parent;

CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL,
    keywords TEXT NOT NULL -- e.g., "hi,hello,hey"
);
CREATE TABLE answers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    answer TEXT NOT NULL,
    category_id INT,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);
INSERT INTO categories (category_name, keywords) VALUES
('greeting', 'hi,hello,hey'),
('hours', 'hours,time,open,closing'),
('ages', 'age,old,baby,toddler'),
('staff', 'staff,teachers,educators'),
('meals', 'food,meal,lunch,breakfast,diet'),
('curriculum', 'curriculum,study,learning,teach'),
('thanks', 'thanks,thank you'),
('goodbye', 'bye,goodbye,see you'),
('default', 'default,unknown,other');

INSERT INTO answers (answer, category_id) VALUES
("Hi there! 👋 I'm the Happy Kids Daycare assistant. How can I help you today?", 1),
("Our daycare is open Monday through Friday from 8:30 AM to 5:30 PM.", 2),
("We care for children from 6 weeks to 5 years old.", 3),
("Our staff are certified early childhood educators with full background checks.", 4),
("We serve breakfast, lunch, and snacks. Breakfast includes dosa, idli, and cereals. Meals include dal with vegetables, rice for kids over 4 years, pasta, and chapathi. We accommodate allergies and dietary needs. Non-veg is not served.", 5),
("We use a play-based curriculum focusing on social, emotional, cognitive, and physical growth.", 6),
("Thank you! Our staff will call you soon. 😊", 7),
("Thanks for chatting! Have a wonderful day!", 8),
("Could you please leave your phone number so our staff can contact you?", 9);

CREATE TABLE student_progress (
    note_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    date DATE NOT NULL,
    type ENUM('daily', 'achievement', 'concern') NOT NULL,
    note TEXT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES parent(parentid) ON DELETE CASCADE
);
select * from student_progress;
select * from parent;
select * from categories;