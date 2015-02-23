-- 1.3
-- drop tables
DROP TABLE IF EXISTS Authored;
DROP TABLE IF EXISTS Inproceedings;
DROP TABLE IF EXISTS Incollection;
DROP TABLE IF EXISTS Book;
DROP TABLE IF EXISTS Article;
DROP TABLE IF EXISTS Publication;
--DROP TABLE IF EXISTS Author;

-- create tables
/*
CREATE TABLE Author(
	id SERIAL PRIMARY KEY,
	name TEXT NOT NULL,
	homepage TEXT
);
*/
CREATE TABLE Publication(
	pubid SERIAL PRIMARY KEY,
	--pubkey TEXT UNIQUE NOT NULL,
	pubkey TEXT NOT NULL,
	title TEXT,
	year INTEGER
);
--unique now or later?
CREATE UNIQUE INDEX publication_pubkey_idx ON Publication(pubkey);
CREATE TABLE Article(
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	pubid INTEGER NOT NULL,
	journal TEXT,
	month TEXT,
	volume TEXT,
	number TEXT
);
CREATE UNIQUE INDEX article_pubid_idx ON Article(pubid);
CREATE TABLE Book(
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	pubid INTEGER NOT NULL,
	publisher TEXT,
	isbn TEXT
);
CREATE UNIQUE INDEX book_pubid_idx ON Book(pubid);
CREATE TABLE Incollection(
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	pubid INTEGER NOT NULL,
	booktitle TEXT,
	publisher TEXT,
	isbn TEXT
);
CREATE UNIQUE INDEX incollection_pubid_idx ON Incollection(pubid);
CREATE TABLE Inproceedings(
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	pubid INTEGER NOT NULL,
	booktitle TEXT,
	editor TEXT
);
CREATE UNIQUE INDEX inproceedings_pubid_idx ON Inproceedings(pubid);
CREATE TABLE Authored(
	--id INTEGER NOT NULL REFERENCES Author(id),
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid)
	id INTEGER NOT NULL,
	pubid INTEGER NOT NULL
);

-- 2.2
SELECT p AS publication_type, COUNT(*)
	FROM pub
	GROUP BY p;
--  publication_type |  count  
-- ------------------+---------
--  www              | 1521335
--  incollection     |   29898
--  article          | 1235495
--  phdthesis        |    6955
--  book             |   11398
--  inproceedings    | 1562008
--  proceedings      |   25625
--  mastersthesis    |       9
/*
WITH	pub_field_exist AS	(
								SELECT DISTINCT pub.p AS pt, field.p AS ft
									FROM pub, field
									WHERE pub.k = field.k
							),
		field_type AS		(
								SELECT DISTINCT field.p AS ft
									FROM field
							),
		pub_type AS			(
								SELECT DISTINCT pub.p AS pt
									FROM pub
							)
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
-- This is faster than the direct query below. The below query queries for
-- all field types twice.
*/
/*
SELECT field_in_all_pub.ft as field_name
	FROM	(
				(
					--all fields
					SELECT DISTINCT field.p AS ft
						FROM field
				)
				EXCEPT
				(
					--field types not having a relationship with all pub types
					SELECT pub_field_not_in_cross.ft AS ft
						FROM	(
									(
										--cross product of all pub types and all field types
										SELECT *
											FROM	(
														--all pub types
														SELECT DISTINCT pub.p AS pt
															FROM pub 
													) AS pub_type,
													(
														--all field types
														SELECT DISTINCT field.p AS ft
															FROM field
													) AS field_type
									)
									EXCEPT
									(
										--existing pub type field type relationships
										SELECT pub.p AS pt, field.p AS ft
											FROM pub, field
											WHERE pub.k = field.k
									)
								) AS pub_field_not_in_cross
				)
			) AS field_in_all_pub;
*/
--  field_name 
-- ------------
--  ee
--  author
--  year
--  url
--  title
CREATE UNIQUE INDEX pub_k_idx ON Pub(k);
CREATE INDEX pub_p_idx ON Pub(p);
--CREATE INDEX field_k_idx ON Field(k); -- I don't think this is necessary, but I'll have to test.
--CREATE INDEX field_p_idx ON Field(p); -- I don't think this is necessary, but I'll have to test.

--3
/*
--Redo and test
INSERT INTO Author (name,homepage) (
	SELECT DISTINCT ON (x.v) x.v AS name, y.v AS homepage
		FROM field AS x, field AS y, pub AS p
		WHERE x.p = 'author' AND y.k LIKE 'homepages/%' AND y.p = 'url' AND x.k = p.k
		AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings')
		ORDER BY x.v
);
*/
/*
--redo one with LIKE like this and test
--move non-joining constraints to where clause
INSERT INTO Author (name,homepage) (
	SELECT DISTINCT ON (x.v) x.v AS name, y.v AS homepage
		FROM
			field AS x LEFT OUTER JOIN field AS y ON (x.p = 'author' AND y.p = 'url' AND y.k = 'homepages/' || LOWER(TRIM(LEADING ' ' FROM SUBSTRING(SUBSTRING(x.v FROM ' [A-Za-z][A-Za-z]*$') FROM ' [A-Za-z]'))) || '/' || REPLACE(REPLACE(x.v, ' ', ''), '.', ''))
			JOIN pub AS p ON (x.k = p.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings'))
		ORDER BY x.v
);
*/
INSERT INTO Publication (pubkey, title, year) (
	SELECT DISTINCT ON (p.k) p.k, title.v, CAST(year.v AS INT)
		FROM pub AS p LEFT OUTER JOIN field as title ON (p.k = title.k AND title.p = 'title')
			LEFT OUTER JOIN field AS year ON (p.k = year.k AND year.p = 'year')
		WHERE  p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p ='inproceedings'
);
INSERT INTO Article (pubid, journal, month, volume, number) (
	SELECT DISTINCT ON (p.pubid) p.pubid, journal.v, month.v, volume.v, number.v
		FROM Publication AS p JOIN pub ON (p.pubkey = pub.k AND pub.p = 'article')
			LEFT OUTER JOIN field AS journal ON (p.pubkey = journal.k AND journal.p = 'journal')
			LEFT OUTER JOIN field AS month ON (p.pubkey = month.k AND month.p = 'month')
			LEFT OUTER JOIN field AS volume ON (p.pubkey = volume.k AND volume.p = 'volume')
			LEFT OUTER JOIN field AS number ON (p.pubkey = number.k AND number.p = 'number')
);
INSERT INTO Book (pubid, publisher, isbn) (
	SELECT DISTINCT ON (p.pubid) p.pubid, publisher.v, isbn.v
		FROM Publication AS p JOIN pub ON (p.pubkey = pub.k AND pub.p = 'book')
			LEFT OUTER JOIN field AS publisher ON (p.pubkey = publisher.k AND publisher.p = 'publisher')
			LEFT OUTER JOIN field AS isbn ON (p.pubkey = isbn.k AND isbn.p = 'isbn')
);
INSERT INTO Incollection (pubid, booktitle, publisher, isbn) (
	SELECT DISTINCT ON (p.pubid) p.pubid, booktitle.v, publisher.v, isbn.v
		FROM Publication AS p JOIN pub ON (p.pubkey = pub.k AND pub.p = 'incollection')
			LEFT OUTER JOIN field AS booktitle ON (p.pubkey = booktitle.k AND booktitle.p = 'booktitle')
			LEFT OUTER JOIN field AS publisher ON (p.pubkey = publisher.k AND publisher.p = 'publisher')
			LEFT OUTER JOIN field AS isbn ON (p.pubkey = isbn.k AND isbn.p = 'isbn')
);
INSERT INTO Inproceedings (pubid, booktitle, editor) (
	SELECT DISTINCT ON (p.pubid) p.pubid, booktitle.v, editor.v
		FROM Publication AS p JOIN pub ON (p.pubkey = pub.k AND pub.p = 'inproceedings')
			LEFT OUTER JOIN field AS booktitle ON (p.pubkey = booktitle.k AND booktitle.p = 'booktitle')
			LEFT OUTER JOIN field AS editor ON (p.pubkey = editor.k AND editor.p = 'editor')
);
--6 Extra credit
-- resolve conflicts "select * from field where k = 'reference/snam/2014';"
-- multiple edotors, isbns
-- for part 3, duplicates removed by DISTINCT ON
