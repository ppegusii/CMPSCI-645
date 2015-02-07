-- drop tables
DROP TABLE IF EXISTS Authored;
DROP TABLE IF EXISTS Inproceedings;
DROP TABLE IF EXISTS Incollection;
DROP TABLE IF EXISTS Book;
DROP TABLE IF EXISTS Article;
DROP TABLE IF EXISTS Publication;
DROP TABLE IF EXISTS Author;

-- create tables
CREATE TABLE Author(
	id SERIAL PRIMARY KEY,
	name TEXT NOT NULL,
	homepage TEXT
);
CREATE TABLE Publication(
	pubid SERIAL PRIMARY KEY,
	pubkey TEXT UNIQUE, -- unsure if this should allow NULL
	title TEXT NOT NULL,
	year INTEGER NOT NULL
);
CREATE TABLE Article(
	pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	journal TEXT NOT NULL,
	month INTEGER NOT NULL,
	volume INTEGER NOT NULL,
	number INTEGER NOT NULL
);
CREATE TABLE Book(
	pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	publisher TEXT NOT NULL,
	isbn TEXT NOT NULL
);
CREATE TABLE Incollection(
	pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	booktitle TEXT NOT NULL,
	publisher TEXT NOT NULL,
	isbn TEXT NOT NULL
);
CREATE TABLE Inproceedings(
	pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	booktitle TEXT NOT NULL,
	editor TEXT NOT NULL
);
CREATE TABLE Authored(
	id INTEGER NOT NULL REFERENCES Author(id),
	pubid INTEGER NOT NULL REFERENCES Publication(pubid)
);
