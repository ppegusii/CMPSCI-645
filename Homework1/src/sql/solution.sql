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
	--pubkey TEXT UNIQUE NOT NULL,
	pubkey TEXT NOT NULL,
	title TEXT NOT NULL,
	year INTEGER
);
CREATE UNIQUE INDEX publication_pubkey_idx ON Publication(pubkey);
CREATE TABLE Article(
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	pubid INTEGER NOT NULL,
	journal TEXT,
	month TEXT,
	volume TEXT,
	number TEXT
);
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

--two queries to load Author and deal with multiple homepages.
--I don't know if either is faster, but the first has clearer intentions
--I still need to deal with authors that have a middle initial in the calls to both SUBSTRING and REPLACE
/*
--Takes too long!
INSERT INTO Author (name,homepage) (
	SELECT DISTINCT ON (x.v) x.v AS name, y.v AS homepage
		FROM field AS x, field AS y, pub AS p
		WHERE x.p = 'author' AND y.k LIKE 'homepages/%' AND y.p = 'url' AND x.k = p.k
		AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings')
		ORDER BY x.v
);
*/
/*
INSERT INTO Author (name,homepage) (
	SELECT DISTINCT ON (x.v) x.v AS name, y.v AS homepage
		FROM field AS x, field AS y, pub AS p
		WHERE x.p = 'author' AND y.k = 'homepages/' || LOWER(TRIM(LEADING ' ' FROM SUBSTRING(SUBSTRING(x.v FROM ' [A-Za-z][A-Za-z]*$') FROM ' [A-Za-z]'))) || '/' || REPLACE(REPLACE(x.v, ' ', ''), '.', '')
			AND y.p = 'url' AND x.k = p.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings')
		ORDER BY x.v
);
*/
--this is the one!
INSERT INTO Author (name,homepage) (
	SELECT DISTINCT ON (x.v) x.v AS name, y.v AS homepage
		FROM
			field AS x LEFT OUTER JOIN field AS y ON (x.p = 'author' AND y.p = 'url' AND y.k = 'homepages/' || LOWER(TRIM(LEADING ' ' FROM SUBSTRING(SUBSTRING(x.v FROM ' [A-Za-z][A-Za-z]*$') FROM ' [A-Za-z]'))) || '/' || REPLACE(REPLACE(x.v, ' ', ''), '.', ''))
			JOIN pub AS p ON (x.k = p.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings'))
		ORDER BY x.v
);
/*
SELECT x.v AS author, MAX(y.v) AS url
	FROM field AS x, field AS y
	WHERE x.p = 'author' AND y.k = 'homepages/' || LOWER(TRIM(LEADING ' ' FROM SUBSTRING(x.v FROM ' [A-Z]'))) || '/' || REPLACE(x.v, ' ', '') AND y.p = 'url'
	GROUP BY x.v;
*/
/*
--Not needed anymore
DROP TABLE IF EXISTS rawArticle;
DROP TABLE IF EXISTS rawBook;
DROP TABLE IF EXISTS rawIncollection;
DROP TABLE IF EXISTS rawInproceedings;
*/
--TODO drop indices
--DROP INDEX IF EXISTS rawTitle_pubkey_idx;
--DROP INDEX IF EXISTS rawYear_pubkey_idx;
--DROP INDEX IF EXISTS rawMonth_pubkey_idx;
--DROP INDEX IF EXISTS rawVolume_pubkey_idx;
--DROP INDEX IF EXISTS rawNumber_pubkey_idx;
--DROP INDEX IF EXISTS rawPublisher_pubkey_idx;
--DROP INDEX IF EXISTS rawISBN_pubkey_idx;
--DROP INDEX IF EXISTS rawBookTitle_pubkey_idx;
--DROP INDEX IF EXISTS rawEditor_pubkey_idx;

--DROP TABLE IF EXISTS rawTitle;
--DROP TABLE IF EXISTS rawYear;
--DROP TABLE IF EXISTS rawMonth;
--DROP TABLE IF EXISTS rawVolume;
--DROP TABLE IF EXISTS rawNumber;
--DROP TABLE IF EXISTS rawPublisher;
--DROP TABLE IF EXISTS rawISBN;
--DROP TABLE IF EXISTS rawBookTitle;
--DROP TABLE IF EXISTS rawEditor;
/*
--Not needed anymore
CREATE TABLE rawArticle AS SELECT DISTINCT ON (k) k AS pubkey, p AS pubtype
	FROM pub
	WHERE p = 'article';
CREATE TABLE rawBook AS SELECT DISTINCT ON (k) k AS pubkey, p AS pubtype
	FROM pub
	WHERE p = 'book';
CREATE TABLE rawIncollection AS SELECT DISTINCT ON (k) k AS pubkey, p AS pubtype
	FROM pub
	WHERE p = 'incollection';
CREATE TABLE rawInproceedings AS SELECT DISTINCT ON (k) k AS pubkey, p AS pubtype
	FROM pub
	WHERE p = 'inproceedings';
*/
/*
CREATE TABLE rawTitle AS SELECT DISTINCT ON (f.k) f.k AS pubkey, f.v AS title
	FROM field AS f, pub AS p
	WHERE f.p = 'title' AND p.k = f.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings');
CREATE INDEX rawTitle_pubkey_idx ON rawTitle(pubkey);
CREATE TABLE rawYear AS SELECT DISTINCT ON (f.k) f.k AS pubkey, f.v AS year
	FROM field AS f, pub AS p
	WHERE f.p = 'year' AND p.k = f.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings');
CREATE INDEX rawYear_pubkey_idx ON rawYear(pubkey);
CREATE TABLE rawJournal AS SELECT DISTINCT ON (f.k) f.k AS pubkey, f.v AS journal
	FROM field AS f, pub AS p
	WHERE f.p = 'journal' AND p.k = f.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings');
CREATE INDEX rawJournal_pubkey_idx ON rawJournal(pubkey);
CREATE TABLE rawMonth AS SELECT DISTINCT ON (f.k) f.k AS pubkey, f.v AS month
	FROM field AS f, pub AS p
	WHERE f.p = 'month' AND p.k = f.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings');
CREATE INDEX rawMonth_pubkey_idx ON rawMonth(pubkey);
CREATE TABLE rawVolume AS SELECT DISTINCT ON (f.k) f.k AS pubkey, f.v AS volume
	FROM field AS f, pub AS p
	WHERE f.p = 'volume' AND p.k = f.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings');
CREATE INDEX rawVolume_pubkey_idx ON rawVolume(pubkey);
CREATE TABLE rawNumber AS SELECT DISTINCT ON (f.k) f.k AS pubkey, f.v AS number
	FROM field AS f, pub AS p
	WHERE f.p = 'number' AND p.k = f.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings');
CREATE INDEX rawNumber_pubkey_idx ON rawNumber(pubkey);
CREATE TABLE rawPublisher AS SELECT DISTINCT ON (f.k) f.k AS pubkey, f.v AS publisher
	FROM field AS f, pub AS p
	WHERE f.p = 'publisher' AND p.k = f.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings');
CREATE INDEX rawPublisher_pubkey_idx ON rawPublisher(pubkey);
CREATE TABLE rawISBN AS SELECT DISTINCT ON (f.k) f.k AS pubkey, f.v AS isbn
	FROM field AS f, pub AS p
	WHERE f.p = 'isbn' AND p.k = f.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings');
CREATE INDEX rawISBN_pubkey_idx ON rawISBN(pubkey);
CREATE TABLE rawBookTitle AS SELECT DISTINCT ON (f.k) f.k AS pubkey, f.v AS booktitle
	FROM field AS f, pub AS p
	WHERE f.p = 'booktitle' AND p.k = f.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings');
CREATE INDEX rawBookTitle_pubkey_idx ON rawBookTitle(pubkey);
CREATE TABLE rawEditor AS SELECT DISTINCT ON (f.k) f.k AS pubkey, f.v AS editor
	FROM field AS f, pub AS p
	WHERE f.p = 'editor' AND p.k = f.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings');
CREATE INDEX rawEditor_pubkey_idx ON rawEditor(pubkey);
*/
INSERT INTO Publication (pubkey, title, year) (
	SELECT t.pubkey, t.title, CAST(y.year AS INT)
		FROM rawTitle AS t, rawYear AS y
		WHERE t.pubkey = y.pubkey
);
INSERT INTO Publication (pubkey, title, year) (
	SELECT p.pubkey, t.v, CAST(y.year AS INT)
		FROM pub AS p LEFT OUTER JOIN field as t ON (p.k = t.k AND t.p = 'title')
			LEFT OUTER JOIN field AS y ON (p.k = y.k AND y.p = 'year'
		FROM rawTitle AS t, rawYear AS y
		WHERE t.pubkey = y.pubkey
);
INSERT INTO Article (pubid, journal, month, volume, number) (
	SELECT p.pubid, j.journal, m.month, v.volume, n.number
		FROM Publication AS p, rawJournal AS j, rawMonth AS m, rawVolume AS v, rawNumber AS n, pub
		WHERE p.pubkey = j.pubkey AND p.pubkey = m.pubkey AND p.pubkey = v.pubkey AND p.pubkey = n.pubkey AND p.pubkey = pub.k AND pub.p = 'article'
);
INSERT INTO Book (pubid, publisher, isbn) (
	SELECT p.pubid, pr.publisher, i.isbn
		FROM Publication AS p, rawPublisher AS pr, rawISBN AS i, pub
		WHERE p.pubkey = pr.pubkey AND p.pubkey = i.pubkey AND p.pubkey = pub.k AND pub.p = 'book'
);
INSERT INTO Incollection (pubid, booktitle, publisher, isbn) (
	SELECT p.pubid, b.booktitle, pr.publisher, i.isbn
		FROM Publication AS p, rawBookTitle as b, rawPublisher AS pr, rawISBN AS i, pub
		WHERE p.pubkey = b.pubkey AND p.pubkey = pr.pubkey AND p.pubkey = i.pubkey AND p.pubkey = pub.k AND pub.p = 'incollection'
);
INSERT INTO Inproceedings (pubid, booktitle, editor) (
	SELECT p.pubid, b.booktitle, e.editor
		FROM Publication AS p, rawBookTitle as b, rawEditor AS e, pub
		WHERE p.pubkey = b.pubkey AND p.pubkey = e.pubkey AND p.pubkey = pub.k AND pub.p = 'inproceedings'
);
