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
	year INTEGER NOT NULL
);
CREATE UNIQUE INDEX publication_pubkey_idx ON Publication(pubkey);
CREATE TABLE Article(
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	pubid INTEGER NOT NULL,
	journal TEXT NOT NULL,
	month INTEGER NOT NULL,
	volume INTEGER NOT NULL,
	number INTEGER NOT NULL
);
CREATE TABLE Book(
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	pubid INTEGER NOT NULL,
	publisher TEXT NOT NULL,
	isbn TEXT NOT NULL
);
CREATE UNIQUE INDEX book_pubid_idx ON Book(pubid);
CREATE TABLE Incollection(
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	pubid INTEGER NOT NULL,
	booktitle TEXT NOT NULL,
	publisher TEXT NOT NULL,
	isbn TEXT NOT NULL
);
CREATE UNIQUE INDEX incollection_pubid_idx ON Incollection(pubid);
CREATE TABLE Inproceedings(
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	pubid INTEGER NOT NULL,
	booktitle TEXT NOT NULL,
	editor TEXT NOT NULL
);
CREATE UNIQUE INDEX inproceedings_pubid_idx ON Inproceedings(pubid);
CREATE TABLE Authored(
	id INTEGER NOT NULL REFERENCES Author(id),
	pubid INTEGER NOT NULL REFERENCES Publication(pubid)
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
--  field_name 
-- ------------
--  ee
--  author
--  year
--  url
--  title
CREATE UNIQUE INDEX pub_k_idx ON Pub(k);
CREATE INDEX pub_p_idx ON Pub(p);
CREATE INDEX field_k_idx ON Field(k); -- I don't think this is necessary, but I'll have to test.
CREATE INDEX field_p_idx ON Field(p); -- I don't think this is necessary, but I'll have to test.

--two queries to load Author and deal with multiple homepages.
--Note that this query selects all authors regardless of their publication types.
--	So it should have authors that do not correspond to a publication in PubData.
--I don't know if either is faster, but the second has clearer intentions
--I still need to deal with authors that have a middle initial in the calls to both SUBSTRING and REPLACE
SELECT DISTINCT ON (x.v) x.v AS author, y.v AS url
	FROM field AS x, field AS y
	WHERE x.p = 'author' AND y.k = 'homepages/' || LOWER(TRIM(LEADING ' ' FROM SUBSTRING(x.v FROM ' [A-Z]'))) || '/' || REPLACE(x.v, ' ', '') AND y.p = 'url'
	ORDER BY x.v;
SELECT x.v AS author, MAX(y.v) AS url
	FROM field AS x, field AS y
	WHERE x.p = 'author' AND y.k = 'homepages/' || LOWER(TRIM(LEADING ' ' FROM SUBSTRING(x.v FROM ' [A-Z]'))) || '/' || REPLACE(x.v, ' ', '') AND y.p = 'url'
	GROUP BY x.v;
