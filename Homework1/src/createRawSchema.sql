create table Pub (k text, p text);
create table Field (k text, i text, p text, v text);
\copy Pub from '/path/to/pubFile.txt';
\copy Field from '/path/to/fieldFile.txt';
