/*
-- 1.3

-- drop indices
DROP INDEX IF EXISTS authored_id_pubid_idx;
DROP INDEX IF EXISTS inproceedings_pubid_idx;
DROP INDEX IF EXISTS incollection_pubid_idx;
DROP INDEX IF EXISTS book_pubid_idx;
DROP INDEX IF EXISTS article_pubid_idx;
DROP INDEX IF EXISTS publication_pubkey_idx;
DROP INDEX IF EXISTS author_name_idx;

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
	title TEXT,
	year INTEGER
);
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
CREATE TABLE Incollection(
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	pubid INTEGER NOT NULL,
	booktitle TEXT,
	publisher TEXT,
	isbn TEXT
);
CREATE TABLE Inproceedings(
	--pubid INTEGER NOT NULL REFERENCES Publication(pubid),
	pubid INTEGER NOT NULL,
	booktitle TEXT,
	editor TEXT
);
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
*/
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
/*
--  field_name 
-- ------------
--  ee
--  author
--  year
--  url
--  title
CREATE UNIQUE INDEX pub_k_idx ON Pub(k);
CREATE INDEX pub_p_idx ON Pub(p);
CREATE INDEX field_k_idx ON Field(k);

--3

INSERT INTO Author (name,homepage) (
	SELECT DISTINCT ON (x.v) x.v AS name, y.v AS homepage
		FROM
			field AS x LEFT OUTER JOIN field AS y ON (y.p = 'url' AND y.k = 'homepages/' || LOWER(TRIM(LEADING ' ' FROM SUBSTRING(SUBSTRING(x.v FROM ' [A-Za-z][A-Za-z]*$') FROM ' [A-Za-z]'))) || '/' || REPLACE(REPLACE(x.v, ' ', ''), '.', ''))
			JOIN pub AS p ON (x.k = p.k AND (p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p = 'inproceedings'))
		WHERE x.p = 'author'
);
CREATE UNIQUE INDEX author_name_idx ON Author(name);
INSERT INTO Publication (pubkey, title, year) (
	SELECT DISTINCT ON (p.k) p.k, title.v, CAST(year.v AS INT)
		FROM pub AS p LEFT OUTER JOIN field as title ON (p.k = title.k AND title.p = 'title')
			LEFT OUTER JOIN field AS year ON (p.k = year.k AND year.p = 'year')
		WHERE  p.p = 'article' OR p.p = 'book' OR p.p = 'incollection' OR p.p ='inproceedings'
);
CREATE UNIQUE INDEX publication_pubkey_idx ON Publication(pubkey);
INSERT INTO Article (pubid, journal, month, volume, number) (
	SELECT DISTINCT ON (p.pubid) p.pubid, journal.v, month.v, volume.v, number.v
		FROM Publication AS p JOIN pub ON (p.pubkey = pub.k AND pub.p = 'article')
			LEFT OUTER JOIN field AS journal ON (p.pubkey = journal.k AND journal.p = 'journal')
			LEFT OUTER JOIN field AS month ON (p.pubkey = month.k AND month.p = 'month')
			LEFT OUTER JOIN field AS volume ON (p.pubkey = volume.k AND volume.p = 'volume')
			LEFT OUTER JOIN field AS number ON (p.pubkey = number.k AND number.p = 'number')
);
CREATE UNIQUE INDEX article_pubid_idx ON Article(pubid);
INSERT INTO Book (pubid, publisher, isbn) (
	SELECT DISTINCT ON (p.pubid) p.pubid, publisher.v, isbn.v
		FROM Publication AS p JOIN pub ON (p.pubkey = pub.k AND pub.p = 'book')
			LEFT OUTER JOIN field AS publisher ON (p.pubkey = publisher.k AND publisher.p = 'publisher')
			LEFT OUTER JOIN field AS isbn ON (p.pubkey = isbn.k AND isbn.p = 'isbn')
);
CREATE UNIQUE INDEX book_pubid_idx ON Book(pubid);
INSERT INTO Incollection (pubid, booktitle, publisher, isbn) (
	SELECT DISTINCT ON (p.pubid) p.pubid, booktitle.v, publisher.v, isbn.v
		FROM Publication AS p JOIN pub ON (p.pubkey = pub.k AND pub.p = 'incollection')
			LEFT OUTER JOIN field AS booktitle ON (p.pubkey = booktitle.k AND booktitle.p = 'booktitle')
			LEFT OUTER JOIN field AS publisher ON (p.pubkey = publisher.k AND publisher.p = 'publisher')
			LEFT OUTER JOIN field AS isbn ON (p.pubkey = isbn.k AND isbn.p = 'isbn')
);
CREATE UNIQUE INDEX incollection_pubid_idx ON Incollection(pubid);
INSERT INTO Inproceedings (pubid, booktitle, editor) (
	SELECT DISTINCT ON (p.pubid) p.pubid, booktitle.v, editor.v
		FROM Publication AS p JOIN pub ON (p.pubkey = pub.k AND pub.p = 'inproceedings')
			LEFT OUTER JOIN field AS booktitle ON (p.pubkey = booktitle.k AND booktitle.p = 'booktitle')
			LEFT OUTER JOIN field AS editor ON (p.pubkey = editor.k AND editor.p = 'editor')
);
CREATE UNIQUE INDEX inproceedings_pubid_idx ON Inproceedings(pubid);
INSERT INTO Authored (id, pubid) (
	SELECT DISTINCT a.id, p.pubid
		FROM Author AS a JOIN field AS f ON (a.name = f.v AND f.p = 'author')
			JOIN Publication AS p ON (p.pubkey = f.k)
);
CREATE UNIQUE INDEX authored_id_pubid_idx ON Authored(id,pubid);

--4
--4.1

SELECT author
	FROM (
			SELECT a.name AS author, COUNT(*)
				FROM Author AS a JOIN Authored AS ad ON (a.id = ad.id)
				GROUP BY a.id
				ORDER BY count DESC
				LIMIT 20
		) AS author_count;
--     author      
-------------------
-- H. Vincent Poor
-- Wei Wang
-- Yan Zhang
-- Wei Liu
-- Wen Gao
-- Philip S. Yu
-- Thomas S. Huang
-- Chin-Chen Chang
-- Yu Zhang
-- Elisa Bertino
-- Lajos Hanzo
-- Jing Li
-- Lei Wang
-- Yang Yang
-- Jiawei Han
-- Witold Pedrycz
-- Xiaodong Wang
-- Wei Zhang
-- Tao Li
-- Li Zhang

--4.2

SELECT author
	FROM (
			SELECT a.name AS author, COUNT(*)
				FROM Author AS a JOIN Authored AS ad ON (a.id = ad.id)
					JOIN Publication AS p ON (ad.pubid = p.pubid AND p.pubkey LIKE 'conf/stoc/%')
				GROUP BY a.id
				ORDER BY count DESC
				LIMIT 20
		) AS author_count;
--          author           
-----------------------------
-- Avi Wigderson
-- Robert Endre Tarjan
-- Moni Naor
-- Uriel Feige
-- Rafail Ostrovsky
-- Ran Raz
-- Frank Thomson Leighton
-- Mihalis Yannakakis
-- Noam Nisan
-- Prabhakar Raghavan
-- Christos H. Papadimitriou
-- Oded Goldreich
-- Salil P. Vadhan
-- Moses Charikar
-- Miklós Ajtai
-- Baruch Awerbuch
-- Eyal Kushilevitz
-- Madhu Sudan
-- Eli Upfal
-- Shafi Goldwasser
SELECT author
	FROM (
			SELECT a.name AS author, COUNT(*)
				FROM Author AS a JOIN Authored AS ad ON (a.id = ad.id)
					JOIN Publication AS p ON (ad.pubid = p.pubid AND p.pubkey LIKE 'conf/mmsys/%')
				GROUP BY a.id
				ORDER BY count DESC
				LIMIT 20
		) AS author_count;
--         author         
--------------------------
-- Mohamed Hefeeda
-- Pål Halvorsen
-- Carsten Griwodz
-- Roger Zimmermann
-- Cheng-Hsin Hsu
-- Shervin Shirmohammadi
-- Dag Johansen
-- Klara Nahrstedt
-- Jean Le Feuvre
-- Stephan Kopf
-- Wolfgang Effelsberg
-- Vamsidhar Reddy Gaddam
-- Prashant J. Shenoy
-- Cyril Concolato
-- Michael Zink
-- Håkon Kvale Stensland
-- Wei Tsang Ooi
-- Kuan-Ta Chen
-- Philipp Schaber
-- Mohammad Hosseini
SELECT author
	FROM (
			SELECT a.name AS author, COUNT(*)
				FROM Author AS a JOIN Authored AS ad ON (a.id = ad.id)
					JOIN Publication AS p ON (ad.pubid = p.pubid AND p.pubkey LIKE 'conf/icdcn/%')
				GROUP BY a.id
				ORDER BY count DESC
				LIMIT 20
		) AS author_count;
--        author        
------------------------
-- Arobinda Gupta
-- C. Siva Ram Murthy
-- Subir Bandyopadhyay
-- Michel Raynal
-- Arunita Jaekel
-- Stéphane Devismes
-- Kannan Srinathan
-- Shay Kutten
-- Vijay K. Garg
-- Sajal K. Das
-- Debashis Saha
-- C. Pandu Rangan
-- Sébastien Tixeuil
-- Eli Gafni
-- Roberto Baldoni
-- Awadhesh Kumar Singh
-- Hugues Fauconnier
-- R. C. Hansdah
-- Sathya Peri
-- Hagit Attiya

--4.3.a

SELECT sao.name AS author
	FROM (
			(
				--SIGMOD authors
				SELECT DISTINCT sa.id, sa.name
					FROM Author AS sa JOIN Authored AS ad ON (sa.id = ad.id)
					JOIN Publication AS p ON (ad.pubid = p.pubid AND p.pubkey LIKE 'conf/sigmod/%')
			)
			EXCEPT
			(
				--pods authors
				SELECT DISTINCT sa.id, sa.name
					FROM Author AS sa JOIN Authored AS ad ON (sa.id = ad.id)
					JOIN Publication AS p ON (ad.pubid = p.pubid AND p.pubkey LIKE 'conf/pods/%')
			)
		) AS sao JOIN Authored AS ad ON (sao.id = ad.id)
			JOIN Publication AS p ON (ad.pubid = p.pubid AND p.pubkey LIKE 'conf/sigmod/%')
		GROUP BY sao.name
		HAVING COUNT(ad.pubid) >= 10;
--          author          
----------------------------
-- Stanley B. Zdonik
-- Alfons Kemper
-- Carlos Ordonez
-- Stefano Ceri
-- Nick Roussopoulos
-- Ahmed K. Elmagarmid
-- Guy M. Lohman
-- Jiawei Han
-- Suman Nath
-- Zachary G. Ives
-- Jingren Zhou
-- Lawrence A. Rowe
-- AnHai Doan
-- Xifeng Yan
-- Xiaokui Xiao
-- Jeffrey Xu Yu
-- Samuel Madden
-- Clement T. Yu
-- Gautam Das
-- Donald Kossmann
-- Feifei Li
-- Juliana Freire
-- Sihem Amer-Yahia
-- Krithi Ramamritham
-- Volker Markl
-- Guoliang Li
-- José A. Blakeley
-- Jian Pei
-- Tim Kraska
-- Jim Gray
-- Cong Yu
-- Kevin S. Beyer
-- Ion Stoica
-- Daniel J. Abadi
-- Anastasia Ailamaki
-- Kevin Chen-Chuan Chang
-- Elke A. Rundensteiner
-- Jun Yang 0001
-- Anthony K. H. Tung
-- Goetz Graefe
-- Michael Stonebraker
-- Kaushik Chakrabarti
-- Jignesh M. Patel
-- Luis Gravano
-- K. Selçuk Candan
-- Xuemin Lin
-- Ihab F. Ilyas
-- Jayavel Shanmugasundaram
-- David B. Lomet
-- Nicolas Bruno
*/

--4.3.b

SELECT sao.name AS author
	FROM (
			(
				--PODS authors
				SELECT DISTINCT sa.id, sa.name
					FROM Author AS sa JOIN Authored AS ad ON (sa.id = ad.id)
					JOIN Publication AS p ON (ad.pubid = p.pubid AND p.pubkey LIKE 'conf/pods/%')
			)
			EXCEPT
			(
				--SIGMOD authors
				SELECT DISTINCT sa.id, sa.name
					FROM Author AS sa JOIN Authored AS ad ON (sa.id = ad.id)
					JOIN Publication AS p ON (ad.pubid = p.pubid AND p.pubkey LIKE 'conf/sigmod/%')
			)
		) AS sao JOIN Authored AS ad ON (sao.id = ad.id)
			JOIN Publication AS p ON (ad.pubid = p.pubid AND p.pubkey LIKE 'conf/pods/%')
		GROUP BY sao.name
		HAVING COUNT(ad.pubid) >= 5;
--         author          
---------------------------
-- Nicole Schweikardt
-- Stavros S. Cosmadakis
-- Pablo Barceló
-- Alan Nash
-- Juan L. Reutter
-- Mikolaj Bojanczyk
-- Francesco Scarcello
-- Marco A. Casanova
-- Eljas Soisalon-Soininen
-- David P. Woodruff
-- Floris Geerts
-- Reinhard Pichler
-- Nancy A. Lynch
-- Kari-Jouko Räihä
-- Thomas Schwentick
-- Rasmus Pagh
-- Vassos Hadzilacos
-- Giuseppe De Giacomo

--6 Extra credit
---- resolve conflicts "select * from field where k = 'reference/snam/2014';"
-- multiple edotors, isbns
-- for part 3, duplicates removed by DISTINCT ON
