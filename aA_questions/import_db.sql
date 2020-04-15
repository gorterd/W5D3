PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,   
    lname TEXT
);

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title TEXT,
    body TEXT NOT NULL,
    author_id INTEGER NOT NULL,

    FOREIGN KEY (author_id) REFERENCES users(id) --Try users.id if this doesn't work
);

CREATE TABLE question_follows (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id) --Try users.id if this doesn't work
    FOREIGN KEY (question_id) REFERENCES questions(id) --Try questions.id if this doesn't work
);

--how do i do puts in ruby????  < q , user id, q id
  -- alvin: "p"                 < r  , user id, r id
  ---- josh: "or print"         < same q, above r, 

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    reply_body TEXT NOT NULL,
    parent_reply_id INTEGER,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (parent_reply_id) REFERENCES replies(id) --Try replies.id if this doesn't work
    FOREIGN KEY (user_id) REFERENCES users(id) --Try users.id if this doesn't work
    FOREIGN KEY (question_id) REFERENCES questions(id) --Try questions.id if this doesn't work
);

CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id) --Try users.id if this doesn't work
    FOREIGN KEY (question_id) REFERENCES questions(id) --Try questions.id if this doesn't work
);

INSERT INTO 
  users(fname, lname)
  VALUES 
    ('Joe', 'Blow'),
    ('Alvin', 'Zablan'),
    ('Jon', 'Hamm'),
    ('Cindy', 'Tong'),
    ('Isaac', 'Owens');

INSERT INTO
  questions(title, body, author_id)
  VALUES
    ('how do I puts', 'i''m really struggling with printing', (SELECT id FROM users WHERE lname = 'Blow') ),
    ('does indenting matter','indenting matters in python, what about ruby', (SELECT id FROM users WHERE lname = 'Zablan')),
    ('what is app academy','i don''t know who any of y''all are or what i''m doing here', (SELECT id FROM users WHERE lname = 'Hamm'));

INSERT INTO
  question_follows(user_id, question_id)
  VALUES
    ((SELECT id FROM users WHERE lname = 'Hamm'), (SELECT id FROM questions WHERE title = 'how do I puts') ),
    ((SELECT id FROM users WHERE lname = 'Zablan'), (SELECT id FROM questions WHERE title = 'what is app academy') ),
    ((SELECT id FROM users WHERE lname = 'Blow'), (SELECT id FROM questions WHERE title = 'does indenting matter') );

INSERT INTO
  replies(reply_body, parent_reply_id, user_id, question_id)
  VALUES
    ('hit p', 
        NULL, 
        (SELECT id FROM users WHERE lname = 'Zablan'), 
        (SELECT id FROM questions WHERE title = 'how do I puts') ),
    ('or print', 
        (SELECT id FROM replies WHERE reply_body = 'hit p'), 
        (SELECT id FROM users WHERE lname = 'Tong'), 
        (SELECT id FROM questions WHERE title = 'how do I puts') ),
    ('or puts', 
        (SELECT id FROM replies WHERE reply_body = 'hit p'), 
        (SELECT id FROM users WHERE lname = 'Owens'), 
        (SELECT id FROM questions WHERE title = 'how do I puts') );

INSERT INTO 
  question_likes(user_id, question_id)
  VALUES
    ((SELECT id FROM users WHERE lname = 'Tong'), (SELECT id FROM questions WHERE title = 'how do I puts') ),
    ((SELECT id FROM users WHERE lname = 'Owens'), (SELECT id FROM questions WHERE title = 'what is app academy') ),
    ((SELECT id FROM users WHERE lname = 'Zablan'), (SELECT id FROM questions WHERE title = 'does indenting matter') );

