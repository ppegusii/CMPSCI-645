-- 1.3
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
CREATE UNIQUE INDEX book_pubid_idx ON Book(pubid);
CREATE TABLE Incollection(
	pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	booktitle TEXT NOT NULL,
	publisher TEXT NOT NULL,
	isbn TEXT NOT NULL
);
CREATE UNIQUE INDEX incollection_pubid_idx ON Incollection(pubid);
CREATE TABLE Inproceedings(
	pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	booktitle TEXT NOT NULL,
	editor TEXT NOT NULL
);
CREATE UNIQUE INDEX inproceedings_pubid_idx ON Inproceedings(pubid);
CREATE TABLE Authored(
	id INTEGER NOT NULL REFERENCES Author(id),
	pubid INTEGER NOT NULL REFERENCES Publication(pubid)
);

-- 2.2
SELECT p, COUNT(*)
	FROM pub
	GROUP BY p;
--        p       |  count  
-- ---------------+---------
--  www           | 1521335
--  incollection  |   29898
--  article       | 1235495
--  phdthesis     |    6955
--  book          |   11398
--  inproceedings | 1562008
--  proceedings   |   25625
--  mastersthesis |       9
BEGIN;
	SELECT DISTINCT pub.p AS pt, field.p AS ft INTO pub_field_exist
		FROM pub, field
		WHERE pub.k = field.k;
	SELECT DISTINCT field.p AS ft INTO field_type
		FROM field;
	SELECT DISTINCT pub.p AS pt INTO pub_type
		FROM pub;
	SELECT field_type.ft AS field_name
		FROM field_type
		WHERE NOT EXISTS	((
								SELECT pub_type.pt, field_type.ft
									FROM pub_type
							)
							EXCEPT
							(
								SELECT *
									FROM pub_field_exist
									WHERE pub_field_exist.ft = field_type.ft
							));
	DROP TABLE IF EXISTS pub_type;
	DROP TABLE IF EXISTS field_type;
	DROP TABLE IF EXISTS pub_field_exist;
COMMIT;
CREATE UNIQUE INDEX pub_k_idx ON Pub(k);
CREATE INDEX field_k_idx ON Field(k);
