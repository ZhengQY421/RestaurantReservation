-- Create base and solution tables. Load data into solution tables.


DROP VIEW IF EXISTS zzsolution, zzanswer CASCADE;
DROP VIEW IF EXISTS v1, v2, v3, v4, v5, v6, v7, v8, v9, v10 CASCADE;
DROP TABLE IF EXISTS zzSummary CASCADE;
DROP TABLE IF EXISTS Specializes CASCADE;
DROP TABLE IF EXISTS Areas CASCADE;
DROP TABLE IF EXISTS Works CASCADE;
DROP TABLE IF EXISTS Projects CASCADE;
DROP TABLE IF EXISTS Managers CASCADE;
DROP TABLE IF EXISTS Engineers CASCADE;
DROP TABLE IF EXISTS Employees CASCADE;
DROP TABLE IF EXISTS Departments CASCADE;
DROP TABLE IF EXISTS Offices CASCADE;

CREATE TABLE zzSummary (
	status		TEXT
);


CREATE TABLE Offices (
	oid 			INTEGER,
	address			VARCHAR(60),
	PRIMARY KEY (oid)
);

-- eid = eid of department's manager
CREATE TABLE Departments (
	did 			INTEGER,
	dbudget 		INTEGER NOT NULL,
	oid 			INTEGER NOT NULL,
	eid 			INTEGER NOT NULL,
	PRIMARY KEY (did),
	FOREIGN KEY (oid) REFERENCES Offices
);

CREATE TABLE Employees (
	eid 			INTEGER,
	did 			INTEGER NOT NULL,
	PRIMARY KEY (eid),
	FOREIGN KEY (did) REFERENCES Departments
);

CREATE TABLE Engineers (
	eid 			INTEGER,
	PRIMARY KEY (eid),
	FOREIGN KEY (eid) REFERENCES Employees
);

CREATE TABLE Managers (
	eid 			INTEGER,
	PRIMARY KEY (eid),
	FOREIGN KEY (eid) REFERENCES Employees
);


-- eid = eid of project's supervisor
CREATE TABLE Projects (
	pid 			INTEGER,
	pbudget			INTEGER NOT NULL,
	eid 			INTEGER NOT NULL,
	PRIMARY KEY (pid),
	FOREIGN KEY (eid) REFERENCES Managers
);


CREATE TABLE Works (
	pid 			INTEGER,
	eid 			INTEGER,
	hours 			INTEGER NOT NULL,
	PRIMARY KEY (pid,eid),
	FOREIGN KEY (eid) REFERENCES Engineers,
	FOREIGN KEY (pid) REFERENCES Projects
);

CREATE TABLE Areas (
	aid 			VARCHAR(5),
	PRIMARY KEY (aid)
);

CREATE TABLE Specializes (
	eid 			INTEGER,
	aid 			VARCHAR(5),
	PRIMARY KEY (eid,aid),
	FOREIGN KEY (eid) REFERENCES Employees,
	FOREIGN KEY (aid) REFERENCES Areas
);


DROP VIEW IF EXISTS zzsolution CASCADE;
DROP TABLE IF EXISTS zzdb1q1 CASCADE;
DROP TABLE IF EXISTS zzdb1q2 CASCADE;
DROP TABLE IF EXISTS zzdb1q3 CASCADE;
DROP TABLE IF EXISTS zzdb1q4 CASCADE;
DROP TABLE IF EXISTS zzdb1q5 CASCADE;
DROP TABLE IF EXISTS zzdb1q6 CASCADE;
DROP TABLE IF EXISTS zzdb1q7 CASCADE;
DROP TABLE IF EXISTS zzdb1q8 CASCADE;
DROP TABLE IF EXISTS zzdb1q9 CASCADE;
DROP TABLE IF EXISTS zzdb1q10 CASCADE;

DROP TABLE IF EXISTS zzdb2q1 CASCADE;
DROP TABLE IF EXISTS zzdb2q2 CASCADE;
DROP TABLE IF EXISTS zzdb2q3 CASCADE;
DROP TABLE IF EXISTS zzdb2q4 CASCADE;
DROP TABLE IF EXISTS zzdb2q5 CASCADE;
DROP TABLE IF EXISTS zzdb2q6 CASCADE;
DROP TABLE IF EXISTS zzdb2q7 CASCADE;
DROP TABLE IF EXISTS zzdb2q8 CASCADE;
DROP TABLE IF EXISTS zzdb2q9 CASCADE;
DROP TABLE IF EXISTS zzdb2q10 CASCADE;

DROP TABLE IF EXISTS zzdb3q1 CASCADE;
DROP TABLE IF EXISTS zzdb3q2 CASCADE;
DROP TABLE IF EXISTS zzdb3q3 CASCADE;
DROP TABLE IF EXISTS zzdb3q4 CASCADE;
DROP TABLE IF EXISTS zzdb3q5 CASCADE;
DROP TABLE IF EXISTS zzdb3q6 CASCADE;
DROP TABLE IF EXISTS zzdb3q7 CASCADE;
DROP TABLE IF EXISTS zzdb3q8 CASCADE;
DROP TABLE IF EXISTS zzdb3q9 CASCADE;
DROP TABLE IF EXISTS zzdb3q10 CASCADE;

DROP TABLE IF EXISTS zzdb4q1 CASCADE;
DROP TABLE IF EXISTS zzdb4q2 CASCADE;
DROP TABLE IF EXISTS zzdb4q3 CASCADE;
DROP TABLE IF EXISTS zzdb4q4 CASCADE;
DROP TABLE IF EXISTS zzdb4q5 CASCADE;
DROP TABLE IF EXISTS zzdb4q6 CASCADE;
DROP TABLE IF EXISTS zzdb4q7 CASCADE;
DROP TABLE IF EXISTS zzdb4q8 CASCADE;
DROP TABLE IF EXISTS zzdb4q9 CASCADE;
DROP TABLE IF EXISTS zzdb4q10 CASCADE;

DROP TABLE IF EXISTS zzdb5q1 CASCADE;
DROP TABLE IF EXISTS zzdb5q2 CASCADE;
DROP TABLE IF EXISTS zzdb5q3 CASCADE;
DROP TABLE IF EXISTS zzdb5q4 CASCADE;
DROP TABLE IF EXISTS zzdb5q5 CASCADE;
DROP TABLE IF EXISTS zzdb5q6 CASCADE;
DROP TABLE IF EXISTS zzdb5q7 CASCADE;
DROP TABLE IF EXISTS zzdb5q8 CASCADE;
DROP TABLE IF EXISTS zzdb5q9 CASCADE;
DROP TABLE IF EXISTS zzdb5q10 CASCADE;

DROP TABLE IF EXISTS zzdb6q1 CASCADE;
DROP TABLE IF EXISTS zzdb6q2 CASCADE;
DROP TABLE IF EXISTS zzdb6q3 CASCADE;
DROP TABLE IF EXISTS zzdb6q4 CASCADE;
DROP TABLE IF EXISTS zzdb6q5 CASCADE;
DROP TABLE IF EXISTS zzdb6q6 CASCADE;
DROP TABLE IF EXISTS zzdb6q7 CASCADE;
DROP TABLE IF EXISTS zzdb6q8 CASCADE;
DROP TABLE IF EXISTS zzdb6q9 CASCADE;
DROP TABLE IF EXISTS zzdb6q10 CASCADE;

DROP TABLE IF EXISTS zzdb7q1 CASCADE;
DROP TABLE IF EXISTS zzdb7q2 CASCADE;
DROP TABLE IF EXISTS zzdb7q3 CASCADE;
DROP TABLE IF EXISTS zzdb7q4 CASCADE;
DROP TABLE IF EXISTS zzdb7q5 CASCADE;
DROP TABLE IF EXISTS zzdb7q6 CASCADE;
DROP TABLE IF EXISTS zzdb7q7 CASCADE;
DROP TABLE IF EXISTS zzdb7q8 CASCADE;
DROP TABLE IF EXISTS zzdb7q9 CASCADE;
DROP TABLE IF EXISTS zzdb7q10 CASCADE;

DROP TABLE IF EXISTS zzdb8q1 CASCADE;
DROP TABLE IF EXISTS zzdb8q2 CASCADE;
DROP TABLE IF EXISTS zzdb8q3 CASCADE;
DROP TABLE IF EXISTS zzdb8q4 CASCADE;
DROP TABLE IF EXISTS zzdb8q5 CASCADE;
DROP TABLE IF EXISTS zzdb8q6 CASCADE;
DROP TABLE IF EXISTS zzdb8q7 CASCADE;
DROP TABLE IF EXISTS zzdb8q8 CASCADE;
DROP TABLE IF EXISTS zzdb8q9 CASCADE;
DROP TABLE IF EXISTS zzdb8q10 CASCADE;

DROP TABLE IF EXISTS zzdb9q1 CASCADE;
DROP TABLE IF EXISTS zzdb9q2 CASCADE;
DROP TABLE IF EXISTS zzdb9q3 CASCADE;
DROP TABLE IF EXISTS zzdb9q4 CASCADE;
DROP TABLE IF EXISTS zzdb9q5 CASCADE;
DROP TABLE IF EXISTS zzdb9q6 CASCADE;
DROP TABLE IF EXISTS zzdb9q7 CASCADE;
DROP TABLE IF EXISTS zzdb9q8 CASCADE;
DROP TABLE IF EXISTS zzdb9q9 CASCADE;
DROP TABLE IF EXISTS zzdb9q10 CASCADE;

DROP TABLE IF EXISTS zzdb10q1 CASCADE;
DROP TABLE IF EXISTS zzdb10q2 CASCADE;
DROP TABLE IF EXISTS zzdb10q3 CASCADE;
DROP TABLE IF EXISTS zzdb10q4 CASCADE;
DROP TABLE IF EXISTS zzdb10q5 CASCADE;
DROP TABLE IF EXISTS zzdb10q6 CASCADE;
DROP TABLE IF EXISTS zzdb10q7 CASCADE;
DROP TABLE IF EXISTS zzdb10q8 CASCADE;
DROP TABLE IF EXISTS zzdb10q9 CASCADE;
DROP TABLE IF EXISTS zzdb10q10 CASCADE;

DROP TABLE IF EXISTS zzdb11q1 CASCADE;
DROP TABLE IF EXISTS zzdb11q2 CASCADE;
DROP TABLE IF EXISTS zzdb11q3 CASCADE;
DROP TABLE IF EXISTS zzdb11q4 CASCADE;
DROP TABLE IF EXISTS zzdb11q5 CASCADE;
DROP TABLE IF EXISTS zzdb11q6 CASCADE;
DROP TABLE IF EXISTS zzdb11q7 CASCADE;
DROP TABLE IF EXISTS zzdb11q8 CASCADE;
DROP TABLE IF EXISTS zzdb11q9 CASCADE;
DROP TABLE IF EXISTS zzdb11q10 CASCADE;

DROP TABLE IF EXISTS zzdb12q1 CASCADE;
DROP TABLE IF EXISTS zzdb12q2 CASCADE;
DROP TABLE IF EXISTS zzdb12q3 CASCADE;
DROP TABLE IF EXISTS zzdb12q4 CASCADE;
DROP TABLE IF EXISTS zzdb12q5 CASCADE;
DROP TABLE IF EXISTS zzdb12q6 CASCADE;
DROP TABLE IF EXISTS zzdb12q7 CASCADE;
DROP TABLE IF EXISTS zzdb12q8 CASCADE;
DROP TABLE IF EXISTS zzdb12q9 CASCADE;
DROP TABLE IF EXISTS zzdb12q10 CASCADE;

DROP TABLE IF EXISTS zzdb13q1 CASCADE;
DROP TABLE IF EXISTS zzdb13q2 CASCADE;
DROP TABLE IF EXISTS zzdb13q3 CASCADE;
DROP TABLE IF EXISTS zzdb13q4 CASCADE;
DROP TABLE IF EXISTS zzdb13q5 CASCADE;
DROP TABLE IF EXISTS zzdb13q6 CASCADE;
DROP TABLE IF EXISTS zzdb13q7 CASCADE;
DROP TABLE IF EXISTS zzdb13q8 CASCADE;
DROP TABLE IF EXISTS zzdb13q9 CASCADE;
DROP TABLE IF EXISTS zzdb13q10 CASCADE;







CREATE TABLE zzdb10q1 (
    eid integer
);



CREATE TABLE zzdb10q10 (
    eid integer
);



CREATE TABLE zzdb10q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb10q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb10q4 (
    eid integer
);



CREATE TABLE zzdb10q5 (
    pid integer
);



CREATE TABLE zzdb10q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb10q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb10q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb10q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb11q1 (
    eid integer
);



CREATE TABLE zzdb11q10 (
    eid integer
);



CREATE TABLE zzdb11q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb11q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb11q4 (
    eid integer
);



CREATE TABLE zzdb11q5 (
    pid integer
);



CREATE TABLE zzdb11q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb11q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb11q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb11q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb12q1 (
    eid integer
);



CREATE TABLE zzdb12q10 (
    eid integer
);



CREATE TABLE zzdb12q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb12q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb12q4 (
    eid integer
);



CREATE TABLE zzdb12q5 (
    pid integer
);



CREATE TABLE zzdb12q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb12q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb12q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb12q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb13q1 (
    eid integer
);



CREATE TABLE zzdb13q10 (
    eid integer
);



CREATE TABLE zzdb13q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb13q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb13q4 (
    eid integer
);



CREATE TABLE zzdb13q5 (
    pid integer
);



CREATE TABLE zzdb13q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb13q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb13q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb13q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb1q1 (
    eid integer
);



CREATE TABLE zzdb1q10 (
    eid integer
);



CREATE TABLE zzdb1q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb1q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb1q4 (
    eid integer
);



CREATE TABLE zzdb1q5 (
    pid integer
);



CREATE TABLE zzdb1q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb1q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb1q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb1q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb2q1 (
    eid integer
);



CREATE TABLE zzdb2q10 (
    eid integer
);



CREATE TABLE zzdb2q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb2q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb2q4 (
    eid integer
);



CREATE TABLE zzdb2q5 (
    pid integer
);



CREATE TABLE zzdb2q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb2q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb2q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb2q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb3q1 (
    eid integer
);



CREATE TABLE zzdb3q10 (
    eid integer
);



CREATE TABLE zzdb3q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb3q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb3q4 (
    eid integer
);



CREATE TABLE zzdb3q5 (
    pid integer
);



CREATE TABLE zzdb3q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb3q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb3q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb3q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb4q1 (
    eid integer
);



CREATE TABLE zzdb4q10 (
    eid integer
);



CREATE TABLE zzdb4q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb4q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb4q4 (
    eid integer
);



CREATE TABLE zzdb4q5 (
    pid integer
);



CREATE TABLE zzdb4q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb4q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb4q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb4q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb5q1 (
    eid integer
);



CREATE TABLE zzdb5q10 (
    eid integer
);



CREATE TABLE zzdb5q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb5q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb5q4 (
    eid integer
);



CREATE TABLE zzdb5q5 (
    pid integer
);



CREATE TABLE zzdb5q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb5q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb5q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb5q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb6q1 (
    eid integer
);



CREATE TABLE zzdb6q10 (
    eid integer
);



CREATE TABLE zzdb6q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb6q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb6q4 (
    eid integer
);



CREATE TABLE zzdb6q5 (
    pid integer
);



CREATE TABLE zzdb6q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb6q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb6q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb6q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb7q1 (
    eid integer
);



CREATE TABLE zzdb7q10 (
    eid integer
);



CREATE TABLE zzdb7q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb7q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb7q4 (
    eid integer
);



CREATE TABLE zzdb7q5 (
    pid integer
);



CREATE TABLE zzdb7q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb7q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb7q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb7q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb8q1 (
    eid integer
);



CREATE TABLE zzdb8q10 (
    eid integer
);



CREATE TABLE zzdb8q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb8q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb8q4 (
    eid integer
);



CREATE TABLE zzdb8q5 (
    pid integer
);



CREATE TABLE zzdb8q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb8q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb8q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb8q9 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb9q1 (
    eid integer
);



CREATE TABLE zzdb9q10 (
    eid integer
);



CREATE TABLE zzdb9q2 (
    eid integer,
    num integer
);



CREATE TABLE zzdb9q3 (
    oid integer,
    numd integer,
    nume integer,
    numm integer,
    numee integer
);



CREATE TABLE zzdb9q4 (
    eid integer
);



CREATE TABLE zzdb9q5 (
    pid integer
);



CREATE TABLE zzdb9q6 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb9q7 (
    eid integer,
    mid integer
);



CREATE TABLE zzdb9q8 (
    eid integer,
    eid2 integer
);



CREATE TABLE zzdb9q9 (
    eid integer,
    eid2 integer
);



INSERT INTO zzdb10q1 (eid) VALUES (103);



INSERT INTO zzdb10q10 (eid) VALUES (100);
INSERT INTO zzdb10q10 (eid) VALUES (103);
INSERT INTO zzdb10q10 (eid) VALUES (104);



INSERT INTO zzdb10q2 (eid, num) VALUES (101, 0);
INSERT INTO zzdb10q2 (eid, num) VALUES (108, 2);
INSERT INTO zzdb10q2 (eid, num) VALUES (105, 2);
INSERT INTO zzdb10q2 (eid, num) VALUES (109, 2);
INSERT INTO zzdb10q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb10q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 7, 2, 3);
INSERT INTO zzdb10q3 (oid, numd, nume, numm, numee) VALUES (2, 1, 3, 1, 2);



INSERT INTO zzdb10q4 (eid) VALUES (100);
INSERT INTO zzdb10q4 (eid) VALUES (103);
INSERT INTO zzdb10q4 (eid) VALUES (104);









INSERT INTO zzdb10q7 (eid, mid) VALUES (101, 100);
INSERT INTO zzdb10q7 (eid, mid) VALUES (108, 103);
INSERT INTO zzdb10q7 (eid, mid) VALUES (109, 103);



INSERT INTO zzdb10q8 (eid, eid2) VALUES (105, 109);
INSERT INTO zzdb10q8 (eid, eid2) VALUES (108, 105);
INSERT INTO zzdb10q8 (eid, eid2) VALUES (108, 109);



INSERT INTO zzdb10q9 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb10q9 (eid, eid2) VALUES (105, 106);



INSERT INTO zzdb11q1 (eid) VALUES (103);
INSERT INTO zzdb11q1 (eid) VALUES (110);



INSERT INTO zzdb11q10 (eid) VALUES (100);
INSERT INTO zzdb11q10 (eid) VALUES (103);
INSERT INTO zzdb11q10 (eid) VALUES (104);
INSERT INTO zzdb11q10 (eid) VALUES (111);



INSERT INTO zzdb11q2 (eid, num) VALUES (101, 4);
INSERT INTO zzdb11q2 (eid, num) VALUES (115, 1);
INSERT INTO zzdb11q2 (eid, num) VALUES (114, 2);
INSERT INTO zzdb11q2 (eid, num) VALUES (108, 1);
INSERT INTO zzdb11q2 (eid, num) VALUES (113, 2);
INSERT INTO zzdb11q2 (eid, num) VALUES (105, 1);
INSERT INTO zzdb11q2 (eid, num) VALUES (109, 1);
INSERT INTO zzdb11q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb11q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 11, 3, 5);
INSERT INTO zzdb11q3 (oid, numd, nume, numm, numee) VALUES (2, 2, 6, 3, 3);



INSERT INTO zzdb11q4 (eid) VALUES (100);
INSERT INTO zzdb11q4 (eid) VALUES (103);
INSERT INTO zzdb11q4 (eid) VALUES (104);
INSERT INTO zzdb11q4 (eid) VALUES (112);






INSERT INTO zzdb11q6 (eid, eid2) VALUES (101, 105);



INSERT INTO zzdb11q7 (eid, mid) VALUES (109, 103);



INSERT INTO zzdb11q8 (eid, eid2) VALUES (101, 115);
INSERT INTO zzdb11q8 (eid, eid2) VALUES (105, 109);
INSERT INTO zzdb11q8 (eid, eid2) VALUES (108, 101);
INSERT INTO zzdb11q8 (eid, eid2) VALUES (113, 101);
INSERT INTO zzdb11q8 (eid, eid2) VALUES (113, 114);



INSERT INTO zzdb11q9 (eid, eid2) VALUES (108, 115);
INSERT INTO zzdb11q9 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb11q9 (eid, eid2) VALUES (109, 115);
INSERT INTO zzdb11q9 (eid, eid2) VALUES (106, 113);
INSERT INTO zzdb11q9 (eid, eid2) VALUES (106, 114);
INSERT INTO zzdb11q9 (eid, eid2) VALUES (105, 106);
INSERT INTO zzdb11q9 (eid, eid2) VALUES (105, 113);
INSERT INTO zzdb11q9 (eid, eid2) VALUES (105, 114);
INSERT INTO zzdb11q9 (eid, eid2) VALUES (113, 114);



INSERT INTO zzdb12q1 (eid) VALUES (100);
INSERT INTO zzdb12q1 (eid) VALUES (103);



INSERT INTO zzdb12q10 (eid) VALUES (100);



INSERT INTO zzdb12q2 (eid, num) VALUES (101, 0);
INSERT INTO zzdb12q2 (eid, num) VALUES (105, 0);
INSERT INTO zzdb12q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb12q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 7, 2, 3);
INSERT INTO zzdb12q3 (oid, numd, nume, numm, numee) VALUES (2, 1, 1, 1, 0);






INSERT INTO zzdb12q5 (pid) VALUES (1);
INSERT INTO zzdb12q5 (pid) VALUES (3);



INSERT INTO zzdb12q6 (eid, eid2) VALUES (101, 105);



INSERT INTO zzdb12q7 (eid, mid) VALUES (101, 100);






INSERT INTO zzdb12q9 (eid, eid2) VALUES (105, 106);



INSERT INTO zzdb13q1 (eid) VALUES (100);
INSERT INTO zzdb13q1 (eid) VALUES (103);



INSERT INTO zzdb13q10 (eid) VALUES (100);



INSERT INTO zzdb13q2 (eid, num) VALUES (101, 0);
INSERT INTO zzdb13q2 (eid, num) VALUES (105, 0);
INSERT INTO zzdb13q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb13q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 7, 3, 3);
INSERT INTO zzdb13q3 (oid, numd, nume, numm, numee) VALUES (2, 1, 1, 0, 0);






INSERT INTO zzdb13q5 (pid) VALUES (1);
INSERT INTO zzdb13q5 (pid) VALUES (3);



INSERT INTO zzdb13q6 (eid, eid2) VALUES (101, 105);



INSERT INTO zzdb13q7 (eid, mid) VALUES (101, 100);






INSERT INTO zzdb13q9 (eid, eid2) VALUES (105, 106);



INSERT INTO zzdb1q1 (eid) VALUES (103);



INSERT INTO zzdb1q10 (eid) VALUES (100);
INSERT INTO zzdb1q10 (eid) VALUES (103);
INSERT INTO zzdb1q10 (eid) VALUES (104);



INSERT INTO zzdb1q2 (eid, num) VALUES (101, 0);
INSERT INTO zzdb1q2 (eid, num) VALUES (105, 0);
INSERT INTO zzdb1q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb1q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 7, 2, 3);
INSERT INTO zzdb1q3 (oid, numd, nume, numm, numee) VALUES (2, 1, 1, 1, 0);



INSERT INTO zzdb1q4 (eid) VALUES (100);
INSERT INTO zzdb1q4 (eid) VALUES (103);
INSERT INTO zzdb1q4 (eid) VALUES (104);



INSERT INTO zzdb1q5 (pid) VALUES (1);
INSERT INTO zzdb1q5 (pid) VALUES (3);



INSERT INTO zzdb1q6 (eid, eid2) VALUES (101, 105);



INSERT INTO zzdb1q7 (eid, mid) VALUES (101, 100);






INSERT INTO zzdb1q9 (eid, eid2) VALUES (105, 106);



INSERT INTO zzdb2q1 (eid) VALUES (103);



INSERT INTO zzdb2q10 (eid) VALUES (100);
INSERT INTO zzdb2q10 (eid) VALUES (103);
INSERT INTO zzdb2q10 (eid) VALUES (104);



INSERT INTO zzdb2q2 (eid, num) VALUES (101, 0);
INSERT INTO zzdb2q2 (eid, num) VALUES (108, 2);
INSERT INTO zzdb2q2 (eid, num) VALUES (105, 2);
INSERT INTO zzdb2q2 (eid, num) VALUES (109, 2);
INSERT INTO zzdb2q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb2q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 7, 2, 3);
INSERT INTO zzdb2q3 (oid, numd, nume, numm, numee) VALUES (2, 1, 3, 1, 2);



INSERT INTO zzdb2q4 (eid) VALUES (100);
INSERT INTO zzdb2q4 (eid) VALUES (103);
INSERT INTO zzdb2q4 (eid) VALUES (104);



INSERT INTO zzdb2q5 (pid) VALUES (1);
INSERT INTO zzdb2q5 (pid) VALUES (3);



INSERT INTO zzdb2q6 (eid, eid2) VALUES (101, 105);



INSERT INTO zzdb2q7 (eid, mid) VALUES (101, 100);
INSERT INTO zzdb2q7 (eid, mid) VALUES (108, 103);
INSERT INTO zzdb2q7 (eid, mid) VALUES (109, 103);



INSERT INTO zzdb2q8 (eid, eid2) VALUES (105, 109);
INSERT INTO zzdb2q8 (eid, eid2) VALUES (108, 105);
INSERT INTO zzdb2q8 (eid, eid2) VALUES (108, 109);



INSERT INTO zzdb2q9 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb2q9 (eid, eid2) VALUES (105, 106);



INSERT INTO zzdb3q1 (eid) VALUES (103);
INSERT INTO zzdb3q1 (eid) VALUES (110);



INSERT INTO zzdb3q10 (eid) VALUES (100);
INSERT INTO zzdb3q10 (eid) VALUES (103);
INSERT INTO zzdb3q10 (eid) VALUES (104);
INSERT INTO zzdb3q10 (eid) VALUES (111);



INSERT INTO zzdb3q2 (eid, num) VALUES (101, 0);
INSERT INTO zzdb3q2 (eid, num) VALUES (108, 2);
INSERT INTO zzdb3q2 (eid, num) VALUES (105, 2);
INSERT INTO zzdb3q2 (eid, num) VALUES (109, 2);
INSERT INTO zzdb3q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb3q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 8, 3, 3);
INSERT INTO zzdb3q3 (oid, numd, nume, numm, numee) VALUES (2, 1, 4, 2, 2);



INSERT INTO zzdb3q4 (eid) VALUES (100);
INSERT INTO zzdb3q4 (eid) VALUES (103);
INSERT INTO zzdb3q4 (eid) VALUES (104);



INSERT INTO zzdb3q5 (pid) VALUES (1);
INSERT INTO zzdb3q5 (pid) VALUES (3);
INSERT INTO zzdb3q5 (pid) VALUES (4);



INSERT INTO zzdb3q6 (eid, eid2) VALUES (101, 105);



INSERT INTO zzdb3q7 (eid, mid) VALUES (108, 103);
INSERT INTO zzdb3q7 (eid, mid) VALUES (109, 103);



INSERT INTO zzdb3q8 (eid, eid2) VALUES (105, 109);
INSERT INTO zzdb3q8 (eid, eid2) VALUES (108, 105);
INSERT INTO zzdb3q8 (eid, eid2) VALUES (108, 109);



INSERT INTO zzdb3q9 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb3q9 (eid, eid2) VALUES (105, 106);



INSERT INTO zzdb4q1 (eid) VALUES (103);
INSERT INTO zzdb4q1 (eid) VALUES (110);



INSERT INTO zzdb4q10 (eid) VALUES (100);
INSERT INTO zzdb4q10 (eid) VALUES (103);
INSERT INTO zzdb4q10 (eid) VALUES (104);
INSERT INTO zzdb4q10 (eid) VALUES (111);



INSERT INTO zzdb4q2 (eid, num) VALUES (101, 0);
INSERT INTO zzdb4q2 (eid, num) VALUES (108, 2);
INSERT INTO zzdb4q2 (eid, num) VALUES (105, 2);
INSERT INTO zzdb4q2 (eid, num) VALUES (109, 2);
INSERT INTO zzdb4q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb4q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 8, 3, 3);
INSERT INTO zzdb4q3 (oid, numd, nume, numm, numee) VALUES (2, 2, 5, 3, 2);



INSERT INTO zzdb4q4 (eid) VALUES (100);
INSERT INTO zzdb4q4 (eid) VALUES (103);
INSERT INTO zzdb4q4 (eid) VALUES (104);
INSERT INTO zzdb4q4 (eid) VALUES (112);



INSERT INTO zzdb4q5 (pid) VALUES (1);
INSERT INTO zzdb4q5 (pid) VALUES (3);
INSERT INTO zzdb4q5 (pid) VALUES (4);



INSERT INTO zzdb4q6 (eid, eid2) VALUES (101, 105);



INSERT INTO zzdb4q7 (eid, mid) VALUES (108, 103);
INSERT INTO zzdb4q7 (eid, mid) VALUES (109, 103);



INSERT INTO zzdb4q8 (eid, eid2) VALUES (105, 109);
INSERT INTO zzdb4q8 (eid, eid2) VALUES (108, 105);
INSERT INTO zzdb4q8 (eid, eid2) VALUES (108, 109);



INSERT INTO zzdb4q9 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb4q9 (eid, eid2) VALUES (105, 106);



INSERT INTO zzdb5q1 (eid) VALUES (103);
INSERT INTO zzdb5q1 (eid) VALUES (110);



INSERT INTO zzdb5q10 (eid) VALUES (100);
INSERT INTO zzdb5q10 (eid) VALUES (103);
INSERT INTO zzdb5q10 (eid) VALUES (104);
INSERT INTO zzdb5q10 (eid) VALUES (111);



INSERT INTO zzdb5q2 (eid, num) VALUES (101, 1);
INSERT INTO zzdb5q2 (eid, num) VALUES (108, 2);
INSERT INTO zzdb5q2 (eid, num) VALUES (113, 1);
INSERT INTO zzdb5q2 (eid, num) VALUES (105, 2);
INSERT INTO zzdb5q2 (eid, num) VALUES (109, 2);
INSERT INTO zzdb5q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb5q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 9, 3, 4);
INSERT INTO zzdb5q3 (oid, numd, nume, numm, numee) VALUES (2, 2, 5, 3, 2);



INSERT INTO zzdb5q4 (eid) VALUES (100);
INSERT INTO zzdb5q4 (eid) VALUES (103);
INSERT INTO zzdb5q4 (eid) VALUES (104);
INSERT INTO zzdb5q4 (eid) VALUES (112);



INSERT INTO zzdb5q5 (pid) VALUES (1);
INSERT INTO zzdb5q5 (pid) VALUES (3);



INSERT INTO zzdb5q6 (eid, eid2) VALUES (101, 105);



INSERT INTO zzdb5q7 (eid, mid) VALUES (108, 103);
INSERT INTO zzdb5q7 (eid, mid) VALUES (109, 103);



INSERT INTO zzdb5q8 (eid, eid2) VALUES (105, 109);
INSERT INTO zzdb5q8 (eid, eid2) VALUES (108, 105);
INSERT INTO zzdb5q8 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb5q8 (eid, eid2) VALUES (113, 101);



INSERT INTO zzdb5q9 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb5q9 (eid, eid2) VALUES (105, 113);
INSERT INTO zzdb5q9 (eid, eid2) VALUES (105, 106);
INSERT INTO zzdb5q9 (eid, eid2) VALUES (106, 113);



INSERT INTO zzdb6q1 (eid) VALUES (103);
INSERT INTO zzdb6q1 (eid) VALUES (110);



INSERT INTO zzdb6q10 (eid) VALUES (100);
INSERT INTO zzdb6q10 (eid) VALUES (103);
INSERT INTO zzdb6q10 (eid) VALUES (104);
INSERT INTO zzdb6q10 (eid) VALUES (111);



INSERT INTO zzdb6q2 (eid, num) VALUES (101, 2);
INSERT INTO zzdb6q2 (eid, num) VALUES (114, 2);
INSERT INTO zzdb6q2 (eid, num) VALUES (108, 2);
INSERT INTO zzdb6q2 (eid, num) VALUES (113, 2);
INSERT INTO zzdb6q2 (eid, num) VALUES (105, 2);
INSERT INTO zzdb6q2 (eid, num) VALUES (109, 2);
INSERT INTO zzdb6q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb6q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 10, 3, 5);
INSERT INTO zzdb6q3 (oid, numd, nume, numm, numee) VALUES (2, 2, 5, 3, 2);



INSERT INTO zzdb6q4 (eid) VALUES (100);
INSERT INTO zzdb6q4 (eid) VALUES (103);
INSERT INTO zzdb6q4 (eid) VALUES (104);
INSERT INTO zzdb6q4 (eid) VALUES (112);



INSERT INTO zzdb6q5 (pid) VALUES (1);
INSERT INTO zzdb6q5 (pid) VALUES (3);



INSERT INTO zzdb6q6 (eid, eid2) VALUES (101, 105);



INSERT INTO zzdb6q7 (eid, mid) VALUES (108, 103);
INSERT INTO zzdb6q7 (eid, mid) VALUES (109, 103);



INSERT INTO zzdb6q8 (eid, eid2) VALUES (105, 109);
INSERT INTO zzdb6q8 (eid, eid2) VALUES (108, 105);
INSERT INTO zzdb6q8 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb6q8 (eid, eid2) VALUES (113, 101);
INSERT INTO zzdb6q8 (eid, eid2) VALUES (113, 114);



INSERT INTO zzdb6q9 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb6q9 (eid, eid2) VALUES (106, 114);
INSERT INTO zzdb6q9 (eid, eid2) VALUES (106, 113);
INSERT INTO zzdb6q9 (eid, eid2) VALUES (105, 114);
INSERT INTO zzdb6q9 (eid, eid2) VALUES (105, 106);
INSERT INTO zzdb6q9 (eid, eid2) VALUES (105, 113);
INSERT INTO zzdb6q9 (eid, eid2) VALUES (113, 114);



INSERT INTO zzdb7q1 (eid) VALUES (103);
INSERT INTO zzdb7q1 (eid) VALUES (110);



INSERT INTO zzdb7q10 (eid) VALUES (100);
INSERT INTO zzdb7q10 (eid) VALUES (103);
INSERT INTO zzdb7q10 (eid) VALUES (104);
INSERT INTO zzdb7q10 (eid) VALUES (111);



INSERT INTO zzdb7q2 (eid, num) VALUES (101, 3);
INSERT INTO zzdb7q2 (eid, num) VALUES (115, 1);
INSERT INTO zzdb7q2 (eid, num) VALUES (114, 2);
INSERT INTO zzdb7q2 (eid, num) VALUES (108, 2);
INSERT INTO zzdb7q2 (eid, num) VALUES (113, 2);
INSERT INTO zzdb7q2 (eid, num) VALUES (105, 2);
INSERT INTO zzdb7q2 (eid, num) VALUES (109, 2);
INSERT INTO zzdb7q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb7q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 10, 3, 5);
INSERT INTO zzdb7q3 (oid, numd, nume, numm, numee) VALUES (2, 2, 6, 3, 3);



INSERT INTO zzdb7q4 (eid) VALUES (100);
INSERT INTO zzdb7q4 (eid) VALUES (103);
INSERT INTO zzdb7q4 (eid) VALUES (104);
INSERT INTO zzdb7q4 (eid) VALUES (112);



INSERT INTO zzdb7q5 (pid) VALUES (3);



INSERT INTO zzdb7q6 (eid, eid2) VALUES (101, 105);



INSERT INTO zzdb7q7 (eid, mid) VALUES (108, 103);
INSERT INTO zzdb7q7 (eid, mid) VALUES (109, 103);



INSERT INTO zzdb7q8 (eid, eid2) VALUES (101, 115);
INSERT INTO zzdb7q8 (eid, eid2) VALUES (105, 109);
INSERT INTO zzdb7q8 (eid, eid2) VALUES (108, 105);
INSERT INTO zzdb7q8 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb7q8 (eid, eid2) VALUES (113, 101);
INSERT INTO zzdb7q8 (eid, eid2) VALUES (113, 114);



INSERT INTO zzdb7q9 (eid, eid2) VALUES (108, 115);
INSERT INTO zzdb7q9 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb7q9 (eid, eid2) VALUES (109, 115);
INSERT INTO zzdb7q9 (eid, eid2) VALUES (106, 113);
INSERT INTO zzdb7q9 (eid, eid2) VALUES (106, 114);
INSERT INTO zzdb7q9 (eid, eid2) VALUES (105, 106);
INSERT INTO zzdb7q9 (eid, eid2) VALUES (105, 113);
INSERT INTO zzdb7q9 (eid, eid2) VALUES (105, 114);
INSERT INTO zzdb7q9 (eid, eid2) VALUES (113, 114);



INSERT INTO zzdb8q1 (eid) VALUES (103);
INSERT INTO zzdb8q1 (eid) VALUES (110);



INSERT INTO zzdb8q10 (eid) VALUES (100);
INSERT INTO zzdb8q10 (eid) VALUES (103);
INSERT INTO zzdb8q10 (eid) VALUES (104);
INSERT INTO zzdb8q10 (eid) VALUES (111);



INSERT INTO zzdb8q2 (eid, num) VALUES (101, 3);
INSERT INTO zzdb8q2 (eid, num) VALUES (115, 1);
INSERT INTO zzdb8q2 (eid, num) VALUES (114, 2);
INSERT INTO zzdb8q2 (eid, num) VALUES (108, 2);
INSERT INTO zzdb8q2 (eid, num) VALUES (113, 2);
INSERT INTO zzdb8q2 (eid, num) VALUES (105, 2);
INSERT INTO zzdb8q2 (eid, num) VALUES (109, 2);
INSERT INTO zzdb8q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb8q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 11, 3, 5);
INSERT INTO zzdb8q3 (oid, numd, nume, numm, numee) VALUES (2, 2, 6, 3, 3);



INSERT INTO zzdb8q4 (eid) VALUES (100);
INSERT INTO zzdb8q4 (eid) VALUES (103);
INSERT INTO zzdb8q4 (eid) VALUES (104);
INSERT INTO zzdb8q4 (eid) VALUES (112);



INSERT INTO zzdb8q5 (pid) VALUES (3);



INSERT INTO zzdb8q6 (eid, eid2) VALUES (101, 105);



INSERT INTO zzdb8q7 (eid, mid) VALUES (108, 103);
INSERT INTO zzdb8q7 (eid, mid) VALUES (109, 103);



INSERT INTO zzdb8q8 (eid, eid2) VALUES (101, 115);
INSERT INTO zzdb8q8 (eid, eid2) VALUES (105, 109);
INSERT INTO zzdb8q8 (eid, eid2) VALUES (108, 105);
INSERT INTO zzdb8q8 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb8q8 (eid, eid2) VALUES (113, 101);
INSERT INTO zzdb8q8 (eid, eid2) VALUES (113, 114);



INSERT INTO zzdb8q9 (eid, eid2) VALUES (108, 115);
INSERT INTO zzdb8q9 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb8q9 (eid, eid2) VALUES (109, 115);
INSERT INTO zzdb8q9 (eid, eid2) VALUES (106, 113);
INSERT INTO zzdb8q9 (eid, eid2) VALUES (106, 114);
INSERT INTO zzdb8q9 (eid, eid2) VALUES (105, 106);
INSERT INTO zzdb8q9 (eid, eid2) VALUES (105, 113);
INSERT INTO zzdb8q9 (eid, eid2) VALUES (105, 114);
INSERT INTO zzdb8q9 (eid, eid2) VALUES (113, 114);



INSERT INTO zzdb9q1 (eid) VALUES (103);



INSERT INTO zzdb9q10 (eid) VALUES (100);
INSERT INTO zzdb9q10 (eid) VALUES (103);
INSERT INTO zzdb9q10 (eid) VALUES (104);



INSERT INTO zzdb9q2 (eid, num) VALUES (101, 0);
INSERT INTO zzdb9q2 (eid, num) VALUES (108, 2);
INSERT INTO zzdb9q2 (eid, num) VALUES (105, 2);
INSERT INTO zzdb9q2 (eid, num) VALUES (109, 2);
INSERT INTO zzdb9q2 (eid, num) VALUES (106, 0);



INSERT INTO zzdb9q3 (oid, numd, nume, numm, numee) VALUES (1, 3, 7, 2, 3);
INSERT INTO zzdb9q3 (oid, numd, nume, numm, numee) VALUES (2, 1, 3, 1, 2);



INSERT INTO zzdb9q4 (eid) VALUES (100);
INSERT INTO zzdb9q4 (eid) VALUES (103);
INSERT INTO zzdb9q4 (eid) VALUES (104);









INSERT INTO zzdb9q7 (eid, mid) VALUES (101, 100);
INSERT INTO zzdb9q7 (eid, mid) VALUES (108, 103);
INSERT INTO zzdb9q7 (eid, mid) VALUES (109, 103);



INSERT INTO zzdb9q8 (eid, eid2) VALUES (105, 109);
INSERT INTO zzdb9q8 (eid, eid2) VALUES (108, 105);
INSERT INTO zzdb9q8 (eid, eid2) VALUES (108, 109);



INSERT INTO zzdb9q9 (eid, eid2) VALUES (108, 109);
INSERT INTO zzdb9q9 (eid, eid2) VALUES (105, 106);



