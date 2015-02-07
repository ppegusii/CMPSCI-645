DROP TABLE IF EXISTS Pub;
DROP TABLE IF EXISTS Field;
create table Pub (k text, p text);
create table Field (k text, i text, p text, v text);
\copy Pub from '../../data/pubFile.txt';
\copy Field from '../../data/fieldFile.txt';
