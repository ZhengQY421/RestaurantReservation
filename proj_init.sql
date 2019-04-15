DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS Restaurants CASCADE;
DROP TABLE IF EXISTS Branches CASCADE;
DROP TABLE IF EXISTS Owners CASCADE;
DROP TABLE IF EXISTS Ratings CASCADE;
DROP TABLE IF EXISTS Incentives CASCADE;
DROP TABLE IF EXISTS Discounts CASCADE;
DROP TABLE IF EXISTS Prizes CASCADE;
DROP TABLE IF EXISTS Choose CASCADE;
DROP TABLE IF EXISTS Gives CASCADE;
DROP TABLE IF EXISTS Response CASCADE;
DROP TABLE IF EXISTS Tables CASCADE;
DROP TABLE IF EXISTS Reserves CASCADE;
DROP TABLE IF EXISTS Photos CASCADE;

create table Users (
    uid             SERIAL,
    name            VARCHAR(50) NOT NULL,
    email           VARCHAR(50) UNIQUE,
    password        VARCHAR(50) NOT NULL,
    primary key (uid)
);

create table Customers (
    uid             INT NOT NULL,
    address         VARCHAR(50),
    pNumber         CHAR(8) NOT NULL UNIQUE,
    rewardPt        INT DEFAULT 0 CHECK (rewardPt >= 0),
    foreign key (uid) references Users(uid) on delete cascade
);

create table Restaurants (
    rid             SERIAL,
    name            TEXT NOT NULL UNIQUE,
    type            TEXT,
    description     TEXT,
    primary key (rid)
);
ALTER SEQUENCE restaurants_rid_seq restart with 1000000;

create table Branches (
    rid             INT NOT NULL,
    bid             INT NOT NULL,
    pNumber         CHAR(8) UNIQUE,
    address         VARCHAR(100) NOT NULL,
    location        TEXT,
    primary key (bid, rid),
    foreign key (rid) references Restaurants (rid) on delete cascade
);

CREATE OR REPLACE FUNCTION branch_location_check()
RETURNS TRIGGER AS
$$
DECLARE count NUMERIC;
BEGIN
    SELECT COUNT(*) into count
    FROM Branches B
    WHERE NEW.rid = B.rid
    AND NEW.address = B.address;
    IF count > 0 THEN
        RAISE NOTICE 'There is already a branch in that location!';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER branch_location_check
BEFORE INSERT OR UPDATE ON Branches
FOR EACH ROW
EXECUTE PROCEDURE branch_location_check();

create table Owners (
    uid             INT,
    rid             INT,
    bid             INT,
    primary key (rid, bid),
    foreign key (uid) references Users (uid) on delete cascade,
    foreign key (rid, bid) references Branches (rid, bid) on delete cascade
);

CREATE TABLE Incentives (
    iid             SERIAL,
    incentiveName   TEXT NOT NULL UNIQUE,
    description     TEXT,
    redeemPts       INT CHECK(redeemPts >= 0),

    primary key (iid)
);
ALTER SEQUENCE incentives_iid_seq restart with 1000000;

CREATE TABLE Discounts (
    iid             INT,
    percent         INT CHECK(percent > 0 and percent <= 100),
    PRIMARY KEY (iid),
    FOREIGN KEY (iid) REFERENCES Incentives (iid) on delete cascade
);

CREATE TABLE Prizes (
    iid             INT,
    PRIMARY KEY (iid),
    FOREIGN KEY (iid) REFERENCES Incentives (iid) on delete cascade
);

create table Choose (
    timeStamp       TIMESTAMPTZ NOT NULL,
    uid             INT NOT NULL,
    iid             INT NOT NULL,
    foreign key (uid) references Users (uid) on delete cascade,
    foreign key (iid) references Incentives (iid) on delete cascade
);

CREATE OR REPLACE FUNCTION redeem_points_check()
RETURNS TRIGGER AS
$$
DECLARE points_available NUMERIC;
DECLARE points_needed NUMERIC;
BEGIN
    SELECT rewardPt INTO points_available
    FROM Customers C
    WHERE NEW.uid = C.uid;
    IF EXISTS(SELECT 1 FROM Incentives I2 where I2.iid=NEW.iid) THEN
        SELECT I3.redeemPts INTO points_needed
        FROM Incentives I3
        Where I3.iid = NEW.iid;
    END IF;
    IF points_available >= points_needed THEN
        Update Customers C1
        SET rewardPt = points_available - points_needed
        WHERE C1.uid = NEW.uid;
        RETURN NEW;
    ELSE
        RAISE NOTICE 'Not enough points to redeem reward!';
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER redeem_points_check
BEFORE INSERT OR UPDATE ON Choose
FOR EACH ROW
EXECUTE PROCEDURE redeem_points_check();

create table Ratings (
    rtid            SERIAL,
    uid             INT NOT NULL,
    score           NUMERIC (1) DEFAULT 0 CHECK(score > 0 and score <= 5),
    review          TEXT,
    PRIMARY KEY (rtid),
    FOREIGN KEY (uid) references Users (uid) on delete cascade
);
ALTER SEQUENCE ratings_rtid_seq restart with 100000;

create table Gives  (
    timeStamp       TIMESTAMPTZ NOT NULL,
    uid             INT,
    rtid            INT,
    rid             INT NOT NULL,
    bid             INT NOT NULL,
    PRIMARY KEY(uid, rtid, rid, bid),
    FOREIGN KEY (rtid) references Ratings (rtid) on delete cascade,
    FOREIGN KEY (uid) references Users (uid) on delete cascade,
    FOREIGN KEY (rid, bid) references Branches (rid, bid) on delete cascade
);

create table Response (
    timeStamp       TIMESTAMPTZ NOT NULL,
    rtid            INT,
    rid             INT NOT NULL,
    bid             INT NOT NULL,
    textResponse    TEXT NOT NULL,
    PRIMARY KEY(rtid, rid, bid),
    FOREIGN KEY (rtid) references Ratings(rtid) on delete cascade,
    FOREIGN KEY (rid, bid) references Branches(rid, bid) on delete cascade
);

CREATE OR REPLACE FUNCTION ratings_review_check()
RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.score IS NULL AND NEW.review IS NULL THEN
        RAISE NOTICE 'Invalid!';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ratings_review_check
BEFORE INSERT OR UPDATE ON Ratings
FOR EACH ROW
EXECUTE PROCEDURE ratings_review_check();

CREATE TABLE  Photos (
    pid             SERIAL,
    rid             INT NOT NULL,
    caption         TEXT,
    file            TEXT NOT NULL,
    PRIMARY KEY (pid),
    FOREIGN KEY (rid) references Restaurants on delete cascade
);
ALTER SEQUENCE photos_pid_seq restart with 10000000;

create table Reserves (
    reserveId       SERIAL,
    uid             INT NOT NULL,
    timeStamp       TIMESTAMPTZ NOT NULL,
    guestCount      INT NOT NULL CHECK(guestCount > 0),
    PRIMARY KEY (reserveId)
);

create table Tables (
    tid             SERIAL,
    time            VARCHAR(4),
    rid             INT NOT NULL,
    bid             INT NOT NULL,
    reserveId       INT UNIQUE,
    vacant          BOOLEAN NOT NULL,
    seats           INT NOT NULL CHECK(seats > 0),
    PRIMARY KEY (tid, time),
    FOREIGN KEY (reserveId) references Reserves (reserveId),
    FOREIGN KEY (rid, bid) references Branches (rid, bid) on delete cascade
);

create or replace view accountTypes (uid, isCustomer, isOwner) as
select
uid,
coalesce((select true from Customers C where C.uid = U.uid), false),
coalesce((select true from (select distinct uid from Owners O) as A where A.uid = U.uid), false)
from Users U
;

INSERT INTO Users(name, email, password) VALUES ('Oliver Zheng', 'oliver@gmail.com', 'password');
INSERT INTO Users(name, email, password) VALUES ('Edenuis Lua', 'edenuis@yahoo.com.sg', 'password1');
INSERT INTO Users(name, email, password) VALUES ('Adrianna Fu', 'adrianna@outlook.com', 'password2');
INSERT INTO Users(name, email, password) VALUES ('Tom Hardy', 'hardtom@gmail.com', 'password3');
INSERT INTO Users(name, email, password) VALUES ('Jane Smooth', 'smoothiejanie@open.io', 'password4');
INSERT INTO Users(name, email, password) VALUES ('Baby Max', 'Iamcute@tippy.com', 'password5');
INSERT INTO Users(name, email, password) VALUES ('Captain America', 'avengersunited@ua.gov.sg', 'password6');
INSERT INTO Users(name, email, password) VALUES ('Pikachu Pie', 'pika@chu.com', 'pika');
INSERT INTO Users(name, email, password) VALUES ('Ash Ketchup', 'catchthemall@pokemon.org', 'password8');
INSERT INTO Users(name, email, password) VALUES ('Kane Crook', 'crookedKane@bullock.com', 'password9');
INSERT INTO Users(name, email, password) VALUES ('Green Broccoli', 'Iamdelicious@bullock.com', 'password10');
INSERT INTO Users(name, email, password) VALUES ('May Fall', 'fallforme@gmail.com', 'password11');
INSERT INTO Users(name, email, password) VALUES ('Arnold Schwarzenegger', 'Iwillbeback@terminator.org', 'password12');
INSERT INTO Users(name, email, password) VALUES ('Bruise Wayne', 'thathurts@bw.com', 'password13');
INSERT INTO Users(name, email, password) VALUES ('Sean Black', 'seanblack@yahoo.com.sg', 'password14');
INSERT INTO Users(name, email, password) VALUES ('Groot', 'IAMGROOT@gog.edu.sg', 'password15');
INSERT INTO Users(name, email, password) VALUES ('Olivia Fong', 'oliviafong@outlook.com', 'password16');
INSERT INTO Users(name, email, password) VALUES ('Amelia Millie', 'milesaway@outlook.com', 'password17');
INSERT INTO Users(name, email, password) VALUES ('Jack-Jack Parr', 'powerfuljack@incredibles.com.sg', 'password18');
INSERT INTO Users(name, email, password) VALUES ('Violet Parr', 'ignorejackjack@incredibles.com.sg', 'password19');
INSERT INTO Users(name, email, password) VALUES ('Dash Parr', 'ignoreviolet@incredibles.com.sg', 'password20');

INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, '28 Rippin Drive Lane SINGAPORE 970914', '95557797', 100 from Users U where U.name='Jack-Jack Parr';
INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, '37 Jalan Huels Lane SINGAPORE 045488', '95556458', 120 from Users U where U.name='Violet Parr';
INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, '52 Jalan Cummerata Hill SINGAPORE 598859', '85554272', 70 from Users U where U.name='Dash Parr';
INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, 'Blk 296C Greenfelder Park Walk SINGAPORE 403488', '85551368', 55 from Users U where U.name='Arnold Schwarzenegger';
INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, '490 Jalan Rippin Alley SINGAPORE 986666', '95553200', 115 from Users U where U.name='Groot';
INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, 'Blk 555E Crona Road Grove SINGAPORE 632951', '85559123', 205 from Users U where U.name='Bruise Wayne';
INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, 'Blk 441A Jalan Oberbrunner Grove SINGAPORE 373484', '85554657', 350 from Users U where U.name='Baby Max';
INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, 'Blk 146D Farrell Place Park SINGAPORE 173569', '95559431', 75 from Users U where U.name='Captain America';
INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, 'Blk 965C Friesen Crescent Way SINGAPORE 706461', '95551651', 1000 from Users U where U.name='Pikachu Pie';
INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, '376 Von Alley Park SINGAPORE 067166', '95554089', 165 from Users U where U.name='Ash Ketchup';

INSERT INTO Restaurants(name, type, description) VALUES ('Putien', 'Casual Dining', 'Seafood, Singaporean, Chinese');
INSERT INTO Restaurants(name, type, description) VALUES ('Itacho Sushi', 'Casual Dining', 'Sushi, Japanese');
INSERT INTO Restaurants(name, type, description) VALUES ('Hai Di Lao Hot Pot', 'Casual Dining', 'Sichuan, Chinese, Seafood');
INSERT INTO Restaurants(name, type, description) VALUES ('Paris Baguette Cafe', 'Cafe, Bakery', 'Cafe, Bakery');
INSERT INTO Restaurants(name, type, description) VALUES ('Graffiti Cafe', 'Quick Bites', 'Cafe, Fast Food');
INSERT INTO Restaurants(name, type, description) VALUES ('Bonchon', 'Casual Dining', 'Korean');
INSERT INTO Restaurants(name, type, description) VALUES ('Pizza Maru', 'Casual Dining', 'Korean, Pizza');
INSERT INTO Restaurants(name, type, description) VALUES ('Cali', 'Cafe', 'American, Bar, All-Day Breakfast, Cafe');
INSERT INTO Restaurants(name, type, description) VALUES ('Hard Rock Cafe', 'Cafe', 'American, Bar, Burgers');
INSERT INTO Restaurants(name, type, description) VALUES ('Brotzeit', 'Casual Dining', 'German, Bar');
INSERT INTO Restaurants(name, type, description) VALUES ('Summer Hill', 'Cafe', 'French, Cafe');


INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000000) as bid, '62956358', '127 Kitchener Road 208514', 'Kitchener Road, Kallang' from Restaurants R where name='Putien';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000000) as bid, '65094296', '2 Orchard Turn, #04-12 ION Orchard 238801', 'Ion Orchard, Orchard' from Restaurants where name='Putien';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000000) as bid, '66863781', '26 Sentosa Gateway, #01-203/204 The Forum 098138', 'Southern Islands' from Restaurants where name='Putien';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000000) as bid, '63362184', '252 North Bridge Road, #02-18 Raffles City Shopping Centre 179103', 'Raffles City Shopping Centre, Downtown Core' from Restaurants where name='Putien';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000000) as bid, '63456358', '80 Marine Parade Road, #02-13/13A Parkway Parade 449269', 'Parkway Parade, Marine Parade' from Restaurants where name='Putien';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000000) as bid, '66347833', '23 Serangoon Central, #02-18/19 Nex 556083', 'Serangoon' from Restaurants where name='Putien';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000000) as bid, '67812162', '4 Tampines Central 5, #B1-27 Tampines Mall 529510', 'Tampines' from Restaurants where name='Putien';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000000) as bid, '63769358', '1 Harbourfront Walk, #02-131/132 Vivo City 098585', 'Bukit Merah' from Restaurants where name='Putien';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000000) as bid, '63364068', '6 Raffles Boulevard, #02-205 Marina Square 039594', 'Marina Square, Downtown Core' from Restaurants where name='Putien';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000000) as bid, '67952338', '1 Jurong West Central 2, #02-34 JP1 648886', 'Jurong West' from Restaurants where name='Putien';

INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000001) as bid, '66844083', '2 Jurong East Central 1, #02-15 Jcube 609731', 'Jcube, Jurong East' from Restaurants where name='Itacho Sushi';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000001) as bid, '65098911', '2 Orchard Turn, #B3-20 ION Orchard 238801', 'Ion Orchard, Orchard' from Restaurants where name='Itacho Sushi';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000001) as bid, '62418911', '65 Airport Boulevard, #03-30/31 Changi Airport Terminal 3 819663', 'Changi Airport Terminal 3' from Restaurants where name='Itacho Sushi';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000001) as bid, '63378911', '200 Victoria Street, #B1-05 Bugis Junction 188021', 'Downtown Core' from Restaurants where name='Itacho Sushi';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000001) as bid, '66940880', '1 Vista Exchange Green, #B1-12 The Star Vista 138617', 'The Star Vista, Queenstown' from Restaurants where name='Itacho Sushi';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000001) as bid, NULL, '4 Tampines Central 5, #04-32 Tampines Mall 529510', 'Tampines' from Restaurants where name='Itacho Sushi';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000001) as bid, '63378922', '68 Orchard Road #02-35 Plaza Singapura 238839', 'Plaza Singapura, Museum' from Restaurants where name='Itacho Sushi';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000001) as bid, '62278911', '311 New Upper Changi Road, #B2-42/43 Bedok Mall 467360', 'Bedok Mall, Bedok' from Restaurants where name='Itacho Sushi';

INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000002) as bid, '63378626', '3D River Valley Road, #02-04 Clarke Quay 179023', 'River Valley Road, Singapore River' from Restaurants where name='Hai Di Lao Hot Pot';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000002) as bid, '68357227', '313 Orchard Road, #04-23/24 238895', 'Orchard Road, Orchard' from Restaurants where name='Hai Di Lao Hot Pot';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000002) as bid, '68964111', '2 Jurong East Street 21, #03-01 IMM 609601', 'Toh Guan, Jurong East' from Restaurants where name='Hai Di Lao Hot Pot';

INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000003) as bid, '68362010', '435 Orchard Road #02-48/53 Wisma Atria', 'Orchard' from Restaurants where name='Paris Baguette Cafe';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000003) as bid, '65420386', '60 Airport Boulevard, #016-006 Changi Airport Terminal 2 819643', 'T2 Arrival Drive, Changi' from Restaurants where name='Paris Baguette Cafe';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000003) as bid, '65570148', '1 Raffles Place, #B1-01 Raffles Place 048616', 'Church Street, Downtown Core' from Restaurants where name='Paris Baguette Cafe';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000003) as bid, '63367943', '200 Victoria Street, #B1-24/25 Bugis Junction 188021', 'Lorong Renjong, Downtown Core' from Restaurants where name='Paris Baguette Cafe';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000003) as bid, '67347765', '50 Jurong Gateway Road, #02-20/21, Jurong East, Singapore 608549', 'Jem, Jurong East' from Restaurants where name='Paris Baguette Cafe';

INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000004) as bid, NULL, '50 Jurong Gateway Road, #05-02 Jem, 608549', 'Jem, Jurong East' from Restaurants where name='Graffiti Cafe';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000004) as bid, '62331896', '14 Scotts Road, #01-17/18/19 Far East Plaza, 228213', 'Far East Plaza, Orchard' from Restaurants where name='Graffiti Cafe';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000004) as bid, '66345909', '23 Serangoon Central, #B2-62 Nex, 556083', 'Serangoon' from Restaurants where name='Graffiti Cafe';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000004) as bid, NULL, '8 Grange Road, #B1-09 Cathay Cineleisure, 239695', 'Cathay Cineleisure Orchard, Orchard' from Restaurants where name='Graffiti Cafe';

INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000005) as bid, '66122131', '1 Sengkang Square, #01 - 14 / 15, Singapore 545078', 'Compass One, Serangoon' from Restaurants where name='Bonchon';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000005) as bid, '68844768', '201 Victoria St, #01-11, Singapore 188067', 'Bugis+, Bugis' from Restaurants where name='Bonchon';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000005) as bid, '65657990', '1 Northpoint Drive, #B1-180, Singapore 768019', 'Northpoint City, Yishun' from Restaurants where name='Bonchon';

INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000006) as bid, '66340930', 'Bugis+, 201 Victoria St, #04-03/04, 188067', 'Bugis+, Bugis' from Restaurants where name='Pizza Maru';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000006) as bid, '62544307', '930 Yishun Avenue 2 #B1-192/193, Singapore 769098', 'Northpoint City, Yishun' from Restaurants where name='Pizza Maru';

INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000007) as bid, '66849897', '31 Rochester Drive, #01-01, Park Avenue Hotel, 138637', 'Park Avenue Hotel, Buona Vista' from Restaurants where name='Cali';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000007) as bid, '64440590', '2 Changi Business Park Ave 1, Singapore 486015', 'Changi' from Restaurants where name='Cali';

INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000008) as bid, '62355232', '50 Cuscaden Rd, #02-01 Hpl House, Singapore 249724', 'Orchard' from Restaurants where name='Hard Rock Cafe';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000008) as bid, '67957454', '26 Sentosa Gateway, Resorts World Sentosa, The Forum #01-209, 098138', 'Resorts World Sentosa' from Restaurants where name='Hard Rock Cafe';

INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000009) as bid, '68831534', '252 North Bridge Rd, #01-17, Raffles City Shopping Centre, 179103', 'Raffles City Shopping Centre' from Restaurants where name='Brotzeit';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000009) as bid, '63482040', '126 E Coast Rd, Singapore 428809', 'Katong' from Restaurants where name='Brotzeit';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000009) as bid, '68344038', '313 Orchard Rd, # 01 - 27, Singapore 238895', '313@Somerset, Orchard Central' from Restaurants where name='Brotzeit';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000009) as bid, '62728815', '1 Harbourfront Walk, #01-149, VivoCity, 098585', 'VivoCity, Harborfront' from Restaurants where name='Brotzeit';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000009) as bid, '64659874', '3 Gateway Dr, #01-04, Singapore 608532', 'Westgate' from Restaurants where name='Brotzeit';

INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000010) as bid, '62515337', '106 Clementi Street 12, #01-62, Singapore 120106', 'Clementi' from Restaurants where name='Summer Hill';
INSERT INTO Branches(rid, bid, pNumber, address, location) select rid, (select count(*) + 1 from branches b where b.rid=1000010) as bid, '62195936', '50 Hume Ave, Singapore 596229', 'Bukit Batok' from Restaurants where name='Summer Hill';

INSERT INTO Owners(uid, rid, bid) select U.uid, R.rid, B.bid from Users U CROSS JOIN (Restaurants R inner join Branches B on R.rid=B.rid) where U.name='Olivia Fong' and R.name='Putien';
INSERT INTO Owners(uid, rid, bid) select U.uid, R.rid, B.bid from Users U CROSS JOIN (Restaurants R inner join Branches B on R.rid=B.rid) where U.name='Amelia Millie' and R.name='Summer Hill';
INSERT INTO Owners(uid, rid, bid) select U.uid, R.rid, B.bid from Users U CROSS JOIN (Restaurants R inner join Branches B on R.rid=B.rid) where U.name='Sean Black' and R.name='Hard Rock Cafe';
INSERT INTO Owners(uid, rid, bid) select U.uid, R.rid, B.bid from Users U CROSS JOIN (Restaurants R inner join Branches B on R.rid=B.rid) where U.name='May Fall' and R.name='Graffiti Cafe';
INSERT INTO Owners(uid, rid, bid) select U.uid, R.rid, B.bid from Users U CROSS JOIN (Restaurants R inner join Branches B on R.rid=B.rid) where U.name='Tom Hardy' and R.name='Cali';
INSERT INTO Owners(uid, rid, bid) select U.uid, R.rid, B.bid from Users U CROSS JOIN (Restaurants R inner join Branches B on R.rid=B.rid) where U.name='Jane Smooth' and R.name='Paris Baguette Cafe';
INSERT INTO Owners(uid, rid, bid) select U.uid, R.rid, B.bid from Users U CROSS JOIN (Restaurants R inner join Branches B on R.rid=B.rid) where U.name='Kane Crook' and R.name='Bonchon';
INSERT INTO Owners(uid, rid, bid) select U.uid, R.rid, B.bid from Users U CROSS JOIN (Restaurants R inner join Branches B on R.rid=B.rid) where U.name='Green Broccoli' and R.name='Pizza Maru';
INSERT INTO Owners(uid, rid, bid) select U.uid, R.rid, B.bid from Users U CROSS JOIN (Restaurants R inner join Branches B on R.rid=B.rid) where U.name='Oliver Zheng' and R.name='Brotzeit';
INSERT INTO Owners(uid, rid, bid) select U.uid, R.rid, B.bid from Users U CROSS JOIN (Restaurants R inner join Branches B on R.rid=B.rid) where U.name='Edenuis Lua' and R.name='Hai Di Lao Hot Pot';
INSERT INTO Owners(uid, rid, bid) select U.uid, R.rid, B.bid from Users U CROSS JOIN (Restaurants R inner join Branches B on R.rid=B.rid) where U.name='Adrianna Fu' and R.name='Itacho Sushi';

INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Putien 19th Year Anniversary', 'Celebrate with us and enjoy 50% discount at all Putien Outlets from 12 April to 12 May!', 0);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Summer Promotion at Brotzeit', 'Enjoy 20% off on all main course at Brotzeit this summer. Promotion is valid only from 1st April to 30th April.', 50);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Itacho Sushi 10th Year Anniversary Special', 'Enjoy 40% off at all Itacho Sushi outlets this April!', 75);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Party away at Hard Rock Cafe this April', 'This April, Hard Rock Cafe will be hosting a 15% off on all main course from 12 April to 19 April! Time to party the heat away!', 35);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Enjoy 1 for 1 Pizza at Pizza Maru', 'Share a pizza with your loved ones this April!', 80);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Spend time with your family @ Paris Baguette', 'Spend some time with your family at Paris Baguette! 30% off on all items. Hurry down today!', 75);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Leave your mark at Graffiti Cafe', 'Leave your mark at Graffiti Cafe this April and enjoy a 10% discount on all main course items.', 15);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Haidilao dinner promotion', 'Enjoy a 10% discount during dinner period at Hai Di Lao. Promotion is valid at all outlets.', 30);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Its Summer time @ Summer Hill', 'Cool yourself down this summer at Summer Hill and enjoy 25% off on all items while you are there!', 50);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Spicy red hot wings @ Bonchon', 'Sweat it out with Bonchon Spicy Red Hot Wings! Enjoy 70% off on second meal ordered', 45);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('All-inclusive Premium Set Lunch @ Putien', 'Enjoy your lunch at Putien for only $20 Nett', 75);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Haidilao All-day set meal','$15 nett for all Haidilao All-day set meals. Valid only at selected outlets', 100);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Bonchon: 6pcs wings for $5 nett','Delicious wings waiting for you!', 25);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('MEGA PROMO at Paris Baguette Cafe','$5 voucher for all pastries!', 25);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Giant teddy bear','Donate this teddy bear to a child in need', 50);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Movie Tickets', 'A pair of movie tickets to enjoy with your partner', 100);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Mini Note Book','Record your travels with this mini note book', 20);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Spill-Free Tumbler', 'No more spills to worry about!', 200);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Portable Charger', '180 00mAh, 1kg', 150);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Couple Vacation Stay','Enjoy a 2D1N vacation stay at Resort World Sentosa with your partner!', 500);

INSERT INTO Discounts (iid, percent) select iid, 50 from Incentives I where I.incentiveName='Putien 19th Year Anniversary';
INSERT INTO Discounts (iid, percent) select iid, 20 from Incentives I where I.incentiveName='Summer Promotion at Brotzeit';
INSERT INTO Discounts (iid, percent) select iid, 40 from Incentives I where I.incentiveName='Itacho Sushi 10th Year Anniversary Special';
INSERT INTO Discounts (iid, percent) select iid, 15 from Incentives I where I.incentiveName='Party away at Hard Rock Cafe this April';
INSERT INTO Discounts (iid, percent) select iid, 50 from Incentives I where I.incentiveName='Enjoy 1 for 1 Pizza at Pizza Maru';
INSERT INTO Discounts (iid, percent) select iid, 30 from Incentives I where I.incentiveName='Spend time with your family @ Paris Baguette';
INSERT INTO Discounts (iid, percent) select iid, 10 from Incentives I where I.incentiveName='Leave your mark at Graffiti Cafe';
INSERT INTO Discounts (iid, percent) select iid, 10 from Incentives I where I.incentiveName='Haidilao dinner promotion';
INSERT INTO Discounts (iid, percent) select iid, 25 from Incentives I where I.incentiveName='Its Summer time @ Summer Hill';
INSERT INTO Discounts (iid, percent) select iid, 70 from Incentives I where I.incentiveName='Spicy red hot wings @ Bonchon';

INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='All-inclusive Premium Set Lunch @ Putien';
INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='Haidilao All-day set meal';
INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='Bonchon: 6pcs wings for $5 nett';
INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='MEGA PROMO at Paris Baguette Cafe';
INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='Giant teddy bear';
INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='Movie Tickets';
INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='Mini Note Book';
INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='Spill-Free Tumbler';
INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='Portable Charger';
INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='Couple Vacation Stay';

insert into Choose (timeStamp, uid, iid) (select now()::timestamptz(0), (select U.uid from Users U where U.name='Jack-Jack Parr'), (select I.iid from Incentives I WHERE I.incentivename='Spicy red hot wings @ Bonchon'));
insert into Choose (timeStamp, uid, iid) (select  now()::timestamptz(0), (select U.uid from Users U where U.name='Violet Parr'), (select I.iid from Incentives I WHERE I.incentivename='Giant teddy bear'));
insert into Choose (timeStamp, uid, iid) (select  now()::timestamptz(0), (select U.uid from Users U where U.name='Dash Parr'), (select I.iid from Incentives I WHERE I.incentivename='Summer Promotion at Brotzeit'));
insert into Choose (timeStamp, uid, iid) (select  now()::timestamptz(0), (select U.uid from Users U where U.name='Arnold Schwarzenegger'), (select I.iid from Incentives I WHERE I.incentivename='Mini Note Book'));
insert into Choose (timeStamp, uid, iid) (select  now()::timestamptz(0), (select U.uid from Users U where U.name='Groot'), (select I.iid from Incentives I WHERE I.incentivename='Movie Tickets'));
insert into Choose (timeStamp, uid, iid) (select  now()::timestamptz(0), (select U.uid from Users U where U.name='Bruise Wayne'), (select I.iid from Incentives I WHERE I.incentivename='Spill-Free Tumbler'));
insert into Choose (timeStamp, uid, iid) (select  now()::timestamptz(0), (select U.uid from Users U where U.name='Baby Max'), (select I.iid from Incentives I WHERE I.incentivename='Portable Charger'));
insert into Choose (timeStamp, uid, iid) (select  now()::timestamptz(0), (select U.uid from Users U where U.name='Captain America'), (select I.iid from Incentives I WHERE I.incentivename='Giant teddy bear'));
insert into Choose (timeStamp, uid, iid) (select  now()::timestamptz(0), (select U.uid from Users U where U.name='Pikachu Pie'), (select I.iid from Incentives I WHERE I.incentivename='Haidilao dinner promotion'));
insert into Choose (timeStamp, uid, iid) (select  now()::timestamptz(0), (select U.uid from Users U where U.name='Ash Ketchup'), (select I.iid from Incentives I WHERE I.incentivename='Itacho Sushi 10th Year Anniversary Special'));

INSERT INTO Ratings (uid, score, review) VALUES (21, 5, 'Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.');
INSERT INTO Ratings (uid, score, review) VALUES (20, 5, 'Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.');
INSERT INTO Ratings (uid, score, review) VALUES (19, 3, 'Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla.');
INSERT INTO Ratings (uid, score, review) VALUES (13, 3, 'Duis aliquam convallis nunc.');
INSERT INTO Ratings (uid, score, review) VALUES (16, 3, 'Vestibulum quam sapien, varius ut, blandit non, interdum in, ante. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis faucibus accumsan odio. Curabitur convallis. Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus. Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci.');
INSERT INTO Ratings (uid, score, review) VALUES (6, 5, 'Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit.');
INSERT INTO Ratings (uid, score, review) VALUES (7, 1, 'Phasellus in felis.');
INSERT INTO Ratings (uid, score, review) VALUES (8, 2, 'Ut tellus.');
INSERT INTO Ratings (uid, score, review) VALUES (9, 2, 'Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.');
INSERT INTO Ratings (uid, score, review) VALUES (14, 4, 'Duis mattis egestas metus. Aenean fermentum.');

INSERT INTO Gives (timeStamp, uid, rtid, rid, bid) (select now()::timestamptz(0), (select R.uid from Ratings R where R.review='Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.'), (select R.rtid from Ratings R where R.review='Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.'), 1000000, 1);
INSERT INTO Gives (timeStamp, uid, rtid, rid, bid) (select now()::timestamptz(0), (select R.uid from Ratings R where R.review='Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.'), (select R.rtid from Ratings R where R.review='Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.'), 1000000, 2);
INSERT INTO Gives (timeStamp, uid, rtid, rid, bid) (select now()::timestamptz(0), (select R.uid from Ratings R where R.review='Duis aliquam convallis nunc.'), (select R.rtid from Ratings R where R.review='Duis aliquam convallis nunc.'), 1000000, 10);
INSERT INTO Gives (timeStamp, uid, rtid, rid, bid) (select now()::timestamptz(0), (select R.uid from Ratings R where R.review='Phasellus in felis.'), (select R.rtid from Ratings R where R.review='Phasellus in felis.'), 1000000, 3);
INSERT INTO Gives (timeStamp, uid, rtid, rid, bid) (select now()::timestamptz(0), (select R.uid from Ratings R where R.review='Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla.'), (select R.rtid from Ratings R where R.review='Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla.'), 1000000, 4);
INSERT INTO Gives (timeStamp, uid, rtid, rid, bid) (select now()::timestamptz(0), (select R.uid from Ratings R where R.review='Vestibulum quam sapien, varius ut, blandit non, interdum in, ante. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis faucibus accumsan odio. Curabitur convallis. Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus. Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci.'), (select R.rtid from Ratings R where R.review='Vestibulum quam sapien, varius ut, blandit non, interdum in, ante. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis faucibus accumsan odio. Curabitur convallis. Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus. Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci.'), 1000000, 5);
INSERT INTO Gives (timeStamp, uid, rtid, rid, bid) (select now()::timestamptz(0), (select R.uid from Ratings R where R.review='Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit.'), (select R.rtid from Ratings R where R.review='Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit.'), 1000000, 6);
INSERT INTO Gives (timeStamp, uid, rtid, rid, bid) (select now()::timestamptz(0), (select R.uid from Ratings R where R.review='Ut tellus.'), (select R.rtid from Ratings R where R.review='Ut tellus.'), 1000000, 7);
INSERT INTO Gives (timeStamp, uid, rtid, rid, bid) (select now()::timestamptz(0), (select R.uid from Ratings R where R.review='Duis mattis egestas metus. Aenean fermentum.'), (select R.rtid from Ratings R where R.review='Duis mattis egestas metus. Aenean fermentum.'), 1000000, 8);
INSERT INTO Gives (timeStamp, uid, rtid, rid, bid) (select now()::timestamptz(0), (select R.uid from Ratings R where R.review='Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.'), (select R.rtid from Ratings R where R.review='Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.'), 1000000, 9);

INSERT INTO Response (timeStamp, rtid, rid, bid, textResponse) (select now()::timestamptz(0), 100000, 1000000, 1, 'Thank you for the high score! We were very happy to be able to serve you. Please come again!');
INSERT INTO Response (timeStamp, rtid, rid, bid, textResponse) (select now()::timestamptz(0), 100001, 1000000, 2, 'We were happy to be able to serve you as well!');
INSERT INTO Response (timeStamp, rtid, rid, bid, textResponse) (select now()::timestamptz(0), 100002, 1000000, 4, 'Thank you for the score. What can we do better to serve you?');
INSERT INTO Response (timeStamp, rtid, rid, bid, textResponse) (select now()::timestamptz(0), 100003, 1000000, 10, 'Hey the score is too low! Increase it!');
INSERT INTO Response (timeStamp, rtid, rid, bid, textResponse) (select now()::timestamptz(0), 100004, 1000000, 5, 'Your presence is a 3 as well');
INSERT INTO Response (timeStamp, rtid, rid, bid, textResponse) (select now()::timestamptz(0), 100005, 1000000, 6, 'Love to see more 5s from you!');
INSERT INTO Response (timeStamp, rtid, rid, bid, textResponse) (select now()::timestamptz(0), 100006, 1000000, 3, 'Number 1 is where we truly belong!');
INSERT INTO Response (timeStamp, rtid, rid, bid, textResponse) (select now()::timestamptz(0), 100007, 1000000, 7, 'Come on, we are definitely a number 1...');
INSERT INTO Response (timeStamp, rtid, rid, bid, textResponse) (select now()::timestamptz(0), 100008, 1000000, 9, 'The more the merrier...');
INSERT INTO Response (timeStamp, rtid, rid, bid, textResponse) (select now()::timestamptz(0), 100009, 1000000, 8, 'Hey, what can we do to get the 5 from you?');

INSERT INTO Photos (rid, caption, file) VALUES (1000000, 'Re-engineered full-range methodology', 'http://www.putien.com/wp-content/uploads/2014/04/AX9A3086-1500-330x220.jpg');
INSERT INTO Photos (rid, caption, file) VALUES (1000001, 'Realigned fresh-thinking portal', 'http://shopsinsg.com/wp-content/uploads/2016/10/itacho-sushi-restaurant-bugis-junction-singapore.jpg');
INSERT INTO Photos (rid, caption, file) VALUES (1000002, 'Team-oriented homogeneous hierarchy', 'https://insideretail.asia/wp-content/uploads/2018/07/Hai-Di-Lao-hotpot.jpg');
INSERT INTO Photos (rid, caption, file) VALUES (1000003, 'Focused heuristic utilisation', 'http://shopsinsg.com/wp-content/uploads/2017/01/paris-baquette-bakery-cafe-singapore.jpg');
INSERT INTO Photos (rid, caption, file) VALUES (1000004, 'Diverse incremental contingency', 'https://media-cdn.tripadvisor.com/media/photo-s/09/72/8b/64/simple-but-relaxing-ambience.jpg');
INSERT INTO Photos (rid, caption, file) VALUES (1000005, 'User-friendly clear-thinking support', 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxMTEhUTExMVFRUXGB8YFxcYGBYfGBgfGRgYGBgdGh8YHyggGiAlHxgaITElJSkrLi4uGCAzODMtNygtLisBCgoKDg0OGxAQGzIlICUtLzAtLS0tLS0tLy0tLy8tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLf/AABEIALcBEwMBIgACEQEDEQH/xAAcAAACAwEBAQEAAAAAAAAAAAAFBgMEBwACAQj/xABAEAACAQIEAwYDBQUHBQEBAAABAhEAAwQSITEFQVEGEyJhcYEykaEHFEKx0SNicsHwM1KCkqKy4RUkQ1PCFvH/xAAaAQADAQEBAQAAAAAAAAAAAAACAwQBAAUG/8QAMREAAgIBAwIEBQIGAwAAAAAAAAECEQMSITFBUQQTInEyYYGh8FKRFIKxwdHxBRXh/9oADAMBAAIRAxEAPwDOJpo+z7H5bzWSdLglf4k1+qz/AJRSaJBHi3HKNNefSp8PjHtOl1fiRgw84Mke4ke9A1aoJOmbSa4V4tXldVdTKsAynqCJH516FTDwN23s58DeHTK3+V1NZXbw6nlWxcctZ8NfXrab/aTWNpioElT9KdjewqfJP90Wo7uFAG9elx6efyr5dxKGNaaAFuxOAzY23zCAv8hA+rVq5NI32a2JN69uNEB/1H8xTsaTN7jYLYnsNrTJinw5sCBDx7zzmlQGvfeGs1GtHXBrVXiWPt2LL3XmV103P91R5sTHtVivXCeH4PiVjEB3uL3D+J1KxAUkMJUyPi+VFCOpmSdIxDieJuX7rXbhlmM+QHIDyA0qAJWm8N7McPxlzusNi7y3SDkF60uV4EmCp0066+VJ/GeD3rN9sO1s94rZYGoJ5EHmCNZ6dKpcaEgzDYR7jKiKSWMActvpG9NHG+zq2cJaA8Tm6M79fA+g6KKPdk+zwsrLaufjb/5Xy8+f5E+0uGzWBsAtxTHM6MNOu9Ic7lSGKNISuF8K20o5e4cFtOY2WflVzhuHAiiXELU2bgG+Rv8AaaMBCMDXGvNHh2XxBIUBC+koHXOmZGuKGBiCVUnntG9NUGzgARUbirjYZsneZTkzZc3LNExPWNahuWGABKkBvhJBgwYMHnrppQuJwU7IYNLj3M4nKFIHI6tv1pquLF63GxRx8ikfnS52I/trg625+TD9aZeJXltFLjnKqh8zdBlDMdNTGXpUmT46HQ4LiJVbi/GMPhVzX7gUn4UGrt/Co1Prt50l8Z+0YyVw1vKvK4/xHzC8h6mfIUi4m8zszuxZmMkkkkn3rI4ZP4tjnkS4Grj/AG+v3pSxOHtnSQf2rDzYaJ/h186UT+e55n1rgK9BaojFRWwptvkhIrslWBar2tqtBLXAF8bD92fkR+tHkx15PhuuP8RI+RmhHBEi76g/r/KjVy3S5cjI8HocfxP/ALP9KfpXVVKV9oaQW4nJdPrU4xQjUa0c7WcA+73zAi2/iWNh1H8x6+VCVwanmfpTU09xVUaN9nXEe8wxtk+Ky2XzytLJ/wDS/wCGmmKzLsJc7jFKJOW6O7Pruh+Yj/Ea1CKnyKmOi7R5ZJBHUEfMRWE4kQkcwfyBFbytYxjrVpHxNplJuC64RuQGfTn68udHi6g5AMiiJNfGqVrRFerOHZtAN9B76CnijU/s+wvd4G2ebln9iTl+gFMJrxgsOLdtLY2RQo9hFSlake7soPFfa+xVfH4tLNtrr/ConzJ2AHmTpXHALtpxvubYtIQLtwdfhXYn1Ow9zyov9hmVrWNDgZCqBgdoi5P0rMcViXv3WuPq7nbkOQAnkNq1H7M+LYLB4a6uIdluXWh1KMVywVUKVBBmT86rxrSqEyds+djrXCbeORreJuswJFlbgXLLSo1Gux0zBaK2ezzXsfib2LIVgodghMBIK2wpI5hCS28gjSg/B+zPDEvd6MW7qGDKhs3AwCsGCzGuwBIG3SmPE9qkGMLMG+7XbItMwHiQqzkMwGuUi4RptGtNk1dWYkyDhN61iLrYbuRYfKWtMt3vEuAbgyAVYfr7+f8Ao/3rCXHtZxdtXWVrbAam2SCBHODp1onwnBWUvpiTiLLrbRwmRgWOfKNh5KdPOhb3rjYK9icK696MY2JCAjNA8BVlmZInQ8jQQgnyqYTb6Au1ggMImKS5nzP3fd5WU58xUCT5gbgb0x9o5weES3bcpdZWZ7iwGJVZIBIMCSPYUI7UXLV/ha3cMCve3jce2CfDcyk3FI5ar9Z5ir+P4icfgbWKw5JdAVuoACymBmkEciJ9DNE1XAIpcA7YWcRZv2uIhHJtN3V1kBecvw5gJkzIPUHXaiWK4ibLWMZfwVwsWtxfttby3ItkAqB4szCPC2mhjlQLstwvF483AVw6oinPcu2F3jRQVAM9Ty+lGbd3DngWFOL78L3rKjWcuZTnukHxmIygimQvqjCTEcZsoyLibF5Lp7v+2w6yWFm5aNyJPeeNlaI1g86kxGO4e1tbV4hWW6zZTav28ttrqs4tqRoW1I30B2OzJi7qtiWvrLunDhcsE/EcxfMwB0DQE1j8UUldn8W3EMLjbN5muGwnf2Ll0hnRhmJUsRqpyroep8oZZwRNrA2zefC3LXe5GVT3q5VIsm5ojnxKXRRuYzxOkBL7GW/veLnFXXYXFZGlgIVvDpyUSdhHOtG4hw3D372HvW7NtiVsnFWCilLlq/GW4F55G1n90ToNUdMUuD4ozWmQILzW2tqpgIbmUoQ3pOnTSp81VdUV+DUZ5Klv29xwbsVatrbS1aUs+fMCirIWIPi30PUzWW9tezxwmIKZcoYZwsgxO408x9a2uy63rmUXUYM0CbYW4qiSuVyu40FIf2nYQZ7Yz54JCNIMpAjbpAFLpLdHoeJTlicZ1aV8U+fp7VXQzJbNWbeFPSjeD4cNNKNWuHCNqxni2KS4I9K+nBmnE4ERtVW9gvKsOsXMBay3V/rkaNXBVe/h8jofP+Yq04oJBwJbPBb7qGW2Sp1BlRPzM11WLPFIUA2rbkADMc0wNBseQAHtXVDKXib2S/P5hyUA72k4SMTZZNm3U9CNv66E9ayElkJVtHUkMpG0edbiDWffaVwDbFWxpoLoHyDfyPlHSq8cq2F5I9RTt41gQQNQQQROhGorR+z3bO3fhLwFq4dAT/Zv6E/CfI+xNZQtk16OGNNlBMWpNG/xSf2v7Kd9N61AujXyb1/Xl5jYB2I7SX7d23h7hz2nYIMx8VsnRcp3iYEH2itQikNODG7SRhT4goxW4hVl0II1Hr1ohwVkNy3cuDwi4pJjUBWB5dKfu1nZNMSuZIW6Boevkeo/oeef/dblr9mywy7/ADpykpIW00zYkcMAQQQdQRsQdiKI2rFo2ixchxssaGsy7B8Xu98cMRmt5S8/+v08jO3v1p9mlNaXQxO0cRWa9s+Pi9c7tGHdWz7M2xPoNh7nnR7t92h+72u6tn9rdHuibFvInYe55Vl63eUAUeOHUCcugTTFoOU+k089luC5gt10y8wDuPXo35UJ7DdnC37e6AF/ApAPmG12PT5nlWk4W4qEeEMB+EzB+WtdOfRHRj1Z8VQBA2FU+LcUtYe2bl1sq8hzY9FHM/0a+cT4llkIoZzqEmAJ2zHUgfMmlO92au4l+8xNws3RZVVHRcxIA9BypSS6sY2+gr8d7T3cQ/h/ZWwZVEMe7Ffib6Dl1JPsj373A5e5kAI8TtrppEnWmjCdjbGgyZo/iJ95P8qMth7dpCoAU9OZpvmx4QGh8sFKGWcrMs6mGIk+cHWobV65bud5au3LT82QjxfxAghh6irlyqdzemrYAHYrt5xG4ht3LiOjCGUooBB3nLFUrnanEthfubqrWNIXYrBzDK0Tv1mvmCwguXVtk5czETExoTsNTtGnWiy9k7hnK6EgkEEwRld0nQkRK8tswrnkrkfj8PknHVFbfQ84j7QcS9yxdNsLcsghXXL4laMyuMsFTlGgjadDU2I7b2zh71m1hFwzX/7V7QHi6iDEAgkRPM1XXsvdJ0iMyrmIcfEuaYKyBsOskaVGvZu8dFyMRJMNMCSoO2xgkeQMxWrN2Zv8Ll/SFn7a2+/wmItW2svYQWXXUpctiIXTUQJjQ6kdKAdoHtXcRcxFq7PeXGuZGRlKy2aJ2P0rr3DGtOi3AAWCsNQdG22q2cEOlZKTmqsCEpYcidbos4/tO0r93lSNS5GoPLKD+ZoVdvXLzl7rF2O5Pl9BVsYLXQVP90C7kA9OfyFDaiHm8RkzyuX/AIQ4ZYopY1qkXCgmNARJPmSD+VfbRuXGKW8zHNACA67cxv8AOgeVCVibCDlV+Jgvrv8AIa1Uu8RtAwFZzPPQfzJ+lXLnZh0RHusqZwSBqz6GDoOfpO9Vxwq0Q8Bi2UwztljQwco6eYpMsqumPj4dtWAuKY5rjAFVUIdgD5bkmvdz+v6iq2MghCI8VpGMTuVE7nerK2y2igknkBJ67CndEJXLIS39f0a6p/udz/13P8rV8rKCCHYvtUL4Fm6YugeFj/5AP/oc+u/Wmu9aV1KOAVYQQdiDvWT9oOzrYNw3iKTKXVaIM6Tp4WFNnAe21oqFxJhh/wCRCGDeZUAEHrE9dNqycesTFLpITuN8BOGuuhUlB4g2vwMYUz1B8J/5qktu0f6atc4xwjCY+0uTEBiJOZD4k20aRsehHKs6472GxGHDOpW7bUSWXRgBqSVP8ifSjjO9nyLa7FGxbto6uNCjK41P4SG/lW0BqwRcMTs6/wCatr4BfL4awx3NpZ9coDfWaHL0DgGcVeQhciZSB4tZnz8qQvtHs28ltsgNwvE6A5QpJ5a6lfnTpFZ99o+KPeqgiETX1fXT2Cn3oYJuRsuAj9nXDStlr7atdMA/uJoPaZprYgbkD3pc+zHjy4gLg7i5XRPAwHhZV08X91h8j5HStLTs4jallPyrZQk2cpJIyzivYW3iLr3nv3izmf8AxwByA8OwGlL3HexlvD2zcS67kGMrBek7it2xXAQqSjGZAkcgdDHXekvtXw1jhgG3CjNtqQpzeutCpzUtJ1RcWzNcJ2jxNtVRbgyqIAyJsPapz2vxX95P8gqVuFrG1DMTgop+ldhWpjBwfjot2xKszHxM5Mkk6nU+tEv/ANOv/rf/AE/rS1hVlV02EfKpsvLapJNWXwxWtg6O1+hUNdUE6quUTGmsNJr5g+M2ncKubMeq/wDNAreHkCFJPtVjBWCtxCQB4hyjnH86yLjZs8TS2GR2qq5qV2qu5q0gAV0eIjzP50YtcLw8AG+oYlAQGXLByi74oj8cif7jDXkLu2GJYhWIzZZAMSdhI5nkKN3sfZVSTgsjh0LZklDl1YQ8FMylZAkc+dYHGTXBHZwKM0/eTqyBSXEspyd4x18MSpykz+zI1Ir3ZwYGVUxTqqlSNYtoHU3WYS4iMh5DxRtNQXr9rOSuFPd5QuU5swcEahtwdpHmetWFuYPNLWXA7y4fhYeAgd2NG0Knfr1rKDWWa6g3EPc7wLcaWQhJ3+ExvzHQ9KLMVWSxAjqY50CgZtNpkek13Hni6wGmViNPePyoJ3wjY+pty3GzhOHN8N3WoRbhYkFRoQRy1MUHxjpDEXBmAkADTzEnfSeVDbuOTDkd1fe6GX9pANsektMjroKpW+0rlhaC2QHOQxb8Xi03B313pSxu7GuSiqC2KKkqQMozwc0k7HkdBrRns9es96mdgQHWQ7ZQRmE6AQR60DwfEcdi5Olq2GAV1QL486qCJljEnyqaz9n+OvuScQpn8T52Pv4iaBxXVhqba2Rb7Sdqwlx7dtsyqxClTKxPLlFKmK7QM5kHL7n9TTVhvs27u6hxmIsCwJzlrhts0gxlE8jG511o3hcPwrDXVuW1Rwk+FLLOSSsSXYRz60S0rhWZKcn8jNsK5ymc0BiASCBAMadR50awahygJgGAT00FRcZ4sl63btqjr3JuqSwAVg90umWCZgbzseteMKZtr/XP0qnlEsWlO+Qxa4KXAZWKg7Bh4h611C3ckySSepNdWFLyYv0fcYMIy4i0Vc6MSXBysSGPhXJBiIiQduVDr3YtdRbCKPwsyvJ9YBYfWoOzfDBen9o6Nbgq6s2ZSQYMSBHh5gzNMvA+JzbU3mlpym4DAJBiSuoE+Q57CkNvoyX0y5ES9YxfD7guG2DDDKyyUuKc2ZSR5DppINaTgcUl60txQcrrqrDUTurDryob2rY3B3JtZrZDMHQnkBsDBkGPp6VQ7E8PxGEu6hjafVs2SUYDRomfIiNo6UxXJb8mwtbCLxzhn3bEPa7rOAZQ+LVWkrt029q0TsFfDYRA6sgQsmUbjUlfi5QwqH7RuAtiBafDmbiyD+GVOu5MaNtr+I1V+zMsBibDznt3FJB1jMCh19bf1rZyWn2OgqlR47Ucev2r/dWzlXu1YkLLSxcROsaKOXOkXiWMJeWl2OpLSSfWd+VO3bvhN5LlzElR3WVFOpDrsBI03Lcjzpe7K8J+9YpQ0d0Je4SDsNl16nT0npXRlFRs5xblQ1disEbVoXmXLcujkIITdV29/fyphwvEi7m2uckcz8OkZvUifpRy7bQoQtxVRdWcqBrGiAndjyH60jcE4xdU3IWURGIYrtJktEajyJFSebKcmkVrFFRs1XEYo2sErgTCW4HUll0050g8XuE277Z8wNwRqSAO7iAdo0J001oVf4211UFy8WVB4UaMizziNTGxMkVbENgbrAg/tANPJf8Amnxn60ieUaiwEz6VQvoDUpeoyapZKMnCuz9trNtyzgsJ0jfbTSrL9mbWUsbrTPwmMx8/hinvsVgEfh9jcSmsE6wzVS4vwrKTDH515uXVGW5ZDK6pMSk4WiCAzaczFDr72QygXCzZhAUAiZG5GlScbwrteKlmKwNJMfKr/D+DLkZuYUkewNYmk02G8k65KbPUbGr/AAzg928MyZQsxLMBrodtzuKg47gmw123bYhs6M0iYGUgRr616RJQOw/FHslgoU/tFuCQTDJOUiDyzGveP49cvLldUK5laIP4RlgayAQBPWBQ/E/Eal4VhhduhGfICDr6CRv1296w4Z8JiMYcrqto94UfUnVkS3DanRikSR1boKH4jjL2/wBk1pAFDLlVmiLqa6z0aRVqzhHDpbXFXAFRiIjwlXVQsecT7etUuM8Nyq1w3mdhoJA1ClEGoPQ6dQK4Iix/HWe26G2ozIizJMd2BlI84BnXXN5CKXH8ATexAUMfGxB9ZI196qBqYj2fW7Fz9qFIBXU6CBm3OvM+WlBI2LEmzwW4TNxkT+NxP0mjPD+yBuEXVa44WGGW0+U5ddGhlIleophwXAsKBDoryisO8ZSYYGTCxrtvrJ0o5Z4zbS3BuJaLLJCjYsonMD7DTXwUE5tcDIqxUbh+LwWGN23ZQW7jJclmm4xMMkAKRAiYnn5mrwwvELv9pdhdSRmaAAJ1A/Sq3FO0ObDW7H3pICLKwJUoojXLOhjY8vOgd3Gvc+K5euegulY+gj9KFJvevsFt3D2K4AxvBBirdhMmdrrhMx2kIJGaOp8q612ewanNf4pcugEwttfCdfDOSf68qA8Rw721XvLV1JkgygzDQcyTQVseuwtk/wAVx/yGlbGLfX+h0nFK6D/EMWjYS1bhu8t3bmYwIOeHGu5OtQ8OP7P3P5zVX7mzWr2INz4by2zaA08VvNnBJ/dAiPeiHZggtbBAI75QQdiCy05bREyfqPkjrXVqjYeyD/ZJ/kX9K6l+Yvz/AEFpYJ7F4ZDw668eJWuqTzMaqPTxemppb7M4HvsNct5WLkyDJCywgz4TsdTzj11c/s0UHC4lNv8Aubg9PBbFXMNiLGHlbeEgKIJDQDl0k6bnrSszelUZGNs8YLgUi0RbY5VYEZ9pAEarptV5OEAsRcRrY5GZH5VJa7VouhsMF30YE/IgfnXjFdsrRBBtXMkST4ZHtP8AOuS9F69zd74I+IcFti2xRwY1iRrSXhsL9ya5ikAZr5VWDfCNC06azP50Y4RxkXsRel4w2WUEL3jZYVmifCOesemhqbjWBFywqofxDLm3PhPSdY19jSoam/UE1W6FrjOP++q1hkUJo/hzAkqRA1J0nX2r1wXDDDWmFq2CzGfESSSNFG+36mrXDOHKrt40Y5YgTI1Gpn+tau4hMtl2AlgCV2iQZ/KnSj0XB0X3FK3jXK3CAbrsFJJIVZBKknyGvyGnKp+z7J+0ADd4yNnzZckAbCCfLXpNDsJbnD3RIMLrG39ofnVvsOtzv3XMI7poAHLNb30/eHzrNFK0FKbbpkN0wPgy+QtsaL4FR9wxBCx413BBPhgmDUNxjplbNIElRcGwQA/CJnXbqKK2yzYDEkgDURBY6a75lBB30iuTkpbgaoONISSwryWox2Jw6Xb7LcRXXuyYYSJDJr9TRTtxw21at2jbtohLkEqAJ8POqnLehGnawPgu02MtJ3Nu7iAoWUFpUOXxSdCuo35184r2vvAL+3xZZgILhFWSBt4fEAZEjfQjpU/C+FpcS23jDtmBIPhhWjYDzG9E7vY5LrBXbObfLOSV29PaoMmXEptS/oVxUlFMUMRjrlw23Nx2Jk5jpy203jWi3AraXVz4q8+kZUJueI6kEZfCIIWQRrJ6VB2kwiWO7tq4IQxkEHLOu+5nQ61Zx9wKwCjXeZ09hGm3WmQmlFNGyg5Sr5Dj2Vn7regwQ8z/AIV/Shf2gp+3wp/cuj62jUvZXjlmwlxbrEZmBUBSZ0g7D0qp2p4raxVyxkJQW8+Z7kKoDBY5k/h6dKr6k6FfFfEf65Vb4dcw4WLqgtm3OeMpXchTurKANNe8PSquJCksUuI4BiRmHL94CjPZvjLWkZFtG7BNw+IDKO7NolZH74n2rgUfXOAzAqBlnURe20gL02M+RHOajzYOB4IIiYFzxxkJCz8ObxgzsdRoRF7D8UuqEC4c+Ffu7TcUB1zP3aHTS4hOkGZXavl/id24oHcaoy3VYXl0ZbK21aI1BFotHkelaaLV9VDsEMrJykiCROkg7GKMYjDOGsqbz5XsJcUCJGcLI1B0mfkKE8Vxgu3rlwKEzsWKgyATqYPrJ96ucXxuRsMxOgw1vSdogQBvy+tcudzJcBP/AKJb/ZZi7ZxMZ2A+DNsCByoHxbB2VYkKNHUjQHSep9KvjtG5FvLhyxtDLDMoJ8GUErMjQ0F4xx17etzDgF+RbaM0bDzqf1D0o1+dyJccGa7ZCBYDAGf7sjpz1NEezfE3e6ivbCgSBAImQwI1PnQNOLM5juLSSDLwc2onVompOCcQxBv2h3Jyd4MzC3cOkwTOogdfKu0uv2N1RW99/uaZxF7Z0OHstA/EGJ110LMaROOcLKI98JYC6kKtuCBOkxWhYzhjhXYsnhgaSZB2I2pF7RcHcC+e/chCwyADL4R66TG3mKCDt3Z3ShcRXYF4OXSY2EqIot2fuQZ6Op+o/Sl/DK4OU3RAEm3PTSNoJmDp0NF+DP8AGPT+dVVtQhtOVmp3cJezHwqdegP1mupIHGr40F1/nXUnyn+f6Hea+w49iuLWrBxiXLiofvF25rIGUfEZ20jbfSjeI7cqbeUW1yupVXzmGHwyPB/OsZttdhpyzMkM3ibYkydzP8qJ4y6b9lmcgCSRlEJbAyiFGyjnHPkNK6VoGEdS3GrHcfuOdFQKsISqmNCV3nfwmfSjxuBmJdEAIykKNIAgHXnzrM/+sxYsorZokyyifiaNvIDU/wD9u4fjN68rTd0RSWE5WfQ7ECJnfbQ7yKnlhfQdabVFvhnaG3hcTdu2WtMGZhD5yArOCIygQ0DeaL4ztbbu2hDOlwPIZGYAaHmCGBMxz2NZOH5Vbw1t3RlQMSCGhRJMSOXrPtVWhIRbltyPOB45bsXCXbMGBBIYkjUEk5tTtNFb/G7bWruQFgo1PJlfTMOcAkTIFZngsK4cC4rSWVbSNpmuMwCjXca60w4XsxduXMQpaG7tsrZTkckkCDIIEpuR7UM2urCUGlVEVi5+zZEg6EFeozEjbarvZvvwLt63acKllkNyAVVz3MA6Efhn03igOA7N3rQN7Eq9pRoNYksIIJExpr7GnfgFkiUXvL3egi3ZYmF2bM0khcvhloPIAEmDj0tel2DuncgJxNb9hAe+ssGMEJb8iR8dpQR6VFhO0DC21lirTtqFCiNgAoB3oj2oDLeTD37SkBQ/7DvC+hy5WN3lGYyBuBQFOzdzEXi+EU92IDF2Eqw3WQBMelDDvMLavQt/kizwXiJw1wuqq8oVgzBBIM6elEuKcWfFIistu2A2ZQuYsxgroNdN9TA03qv2ls28Mti2wlhKsRpyUljzOpPtFVfuS3rc2mMlSmUTE5iRvqND9fmzXFrWD5ctWgZOy/GUwwt5071QzDwQSoJDMfYSTqdBpTFd7Q2rOJuNat95oACLigSNTuPQfOs27I3hbW5auF0YspOmgGZQZAltCATA2nlUIcrOpMac/egWCDk3Rkp7II9reKs+IzmyoViDIKykQMzMPxc+lR4q8sgs0CBPprz6+VUuEYzNdVDqLhyQWYAEkZDI1EOFPtTp2g7OlLSWrgQIR4SPiLBZJM/i+f5UU4qKSrYZgjKVtS3+f9hf4Pxm33OKtlvE4TJoYOVmJ15cqp3Fd0OQLOZQSZ0DSNhy2Jpdw7FXaToGyz13pi4HiQLmUmAw3PUaj+dMk2otoXGKc1FgPiWIdWNu6pAHyOu4PSmzsnwq89jv7Vy2oM2znzEjLlu66RqEU9Dtzonb4SmKItkK3Sf5EUP4hwC/gsXbt32axg7jaXEYqBlRmyk8m8JAmdCN9aHFkc1xwHmxeW+f8hj/APOYr/3oC0ORkEkl1Y7wCxZVJHPKOQqo/AbyoHGKA1SB3YDCWQrGu696SOg2idOGCwXhFzGtcIMMO+8BjPqG1gEAEdDAnxCqN61wkKJulzl8RJvTmy25KBR/FAbTNIOgFOEgrtBw/wC73cned5K5iwAAnMwIEE7ZYPQyOVeuDd015SyEOqzm5EDTZiRI0gx7aal+F9n8JjMUFwzMmHRJukB8+YuwABuaaiIPIKZE6l3xvZTBW7RFl0td2CXZjmMD4s5Jn25E6DWgyJuLoPE0pq+AFwrF2LmLti7d1CwRcgDLDASQBJkSBvrpvSnx/jWKweNxbWlVrTuVtNctyqgGQUgjaSBJI8qYuEdgVx1s4oXWtOXm0P71tCApYDVGMGCDpvBobi3v37iWr2Ha2FbO7kA217oh4bTY5Y31ml4sWnnews2Ryk2jz2Sv96hu3O4d7hYnNbz5fFqgzN4ABOmp9d6GYngeJw2ItXAHbDNcWGWCAGbLBjWBO+1ODYCzd7oWTaQD42UgA+FF5aQFQACivHOCA2i+Hu3EKrOXMSjDdjB+EnU6aHpRLFO22tjZZoOKSe5JhbheyAdzb+tpsv8Atj5VnfarjAW/i7OViztIbw5RnsIOZnQzyopgLuJe6LS3nDawWgLpBO6zrOmnKveI7HOxuviriM7IcjEvmkMsEym0SNOtJjHQtwdV8Gf2bVtVmQLkGZMhtVEL0Os+xq1wy5DN6U04PsrbSzfcvLC0wgDQHIW0kfwkHeRSnwO+i30ZxKBgWETIBBOnOn3SbAa3Qw4fhGJuKHSw7K2oOgkdRJrq0fhuJN+0t1MwVxK5oBiYBiee/oa6vDl/y2VNrSvv/kp8iP6jKLHALqlzAuW0WW1hgeoHOPyBonhsCt1LaZyGyDNk2AJbQj+8RrV/tTic2LWxZUhwF8I0Zi0n6D6DXapMajWMll47wgZmU/FJO3oIB9K97Dilmkk5V1+gHmYsVylG1/f36CVxzBXcO4QkQAAGH4gBuB/KvGBvHI51IC69BOgOvnTbxPBG4uUyB6TS7xbBPatrbUsQ7SZESR8I9NTp51Vn8MoK4u19CPF4qOR7c9gIW1NNHYPBXXuO9tMypAeCJEhoMHcaGY12pQzVqv2RrlsXmOjO4A81y8vfN8qjyfCVYG1NSXQu4i2FuIblsF0Ie2WU6fvISP60ohgcTZSyiA7CCXbxN8omrHaWzmwlzK0taUuhG4KCSNeqyPlS7wPFHSJMjYRP1MfWocsW47HszrxGJyr1IYcLjbanRQZEGEYyOew1qnxHBqrjE2rrWUZCmRBD5iyn4iDAIEkdVGlSOtyfhgH+8wH+2Z+dCL2PJFzDXDDWyuXTRpQMpjzDMu/I0jwsmp/LqeXOCkvmDsJxf7xce85MDwqknXKdC066evX3u2MWZldI2y6R6RSpw1oEjYkkeWxj6/WrDY0gabxP1r2KRJqdBfi/CLeKZXe46MSMxgNmGk6EjxQImY614sYa1hbps2zDsBkutJRmOot3FbRQwgSNQTuVNCeHY5muMZ0ER7yTVqzi0e7dsXGL2ruVWJImywLZWUHXQsddRBIOkx1Kq6Bxdu+pH/0jEXbb48qtm3myHcElYV8o5AMMuvMEcqDYzGaQDHoNa3TinDLT4VMIxLIqKM06sVHxE9SZPuaV/wD8BhYec/i55hKwZ8OlcqXADtuzIUukENmgggyOUHcVvvF+Fm8tq5fZYsI5aNM75VM6HRYBMTPi96T8L2AwrO6XDdDBdgy5WBgB1lZ1jUToZ5QS4dpbo+63FBKqFUTE7kKJ9yKydtUjYqhIwOHtj/xqJkzGviMn570u8ew2W+VQaORlAGknSBy3/Ojt3GKBOYGBv6CvXBeHNibtrMwypcNwwYbKiNeETyzZfnRLsYzQuxPAxhralyGcALJ2ECPD+vt1NGe0GEt4vD3MPc0DiAeasNVYeYMGvlmzlQE6aaVRuXyT5Cubrg2r5Pz9i1ZGZHEMjFWHQqSrfUGh5ua0ydv7QTH4gDmwb/OiufqxpTuNXIFmh/ZrxI2+/gL+FiTPIMOtT8X4q1662GW1cKBlbEd3bBeM2chI1AJ5npzEyL7BIRavZtnRjtqABvPPafL3p0wxAUJ+zJcsxEOCSxRzqNP/AB+0ecUqDucl7FDiljjXLsIYHiyIlu4tm5ZRj3cEAMFSQBlJIA0oPxLiyd7eD3FU3Sy2pSJBEjMQSOmw5Ve4kbZwdte8toysriIJEgyAGIY6EjXal/GY23cfIVVywgNGo6a6ifbrS8knq2ZRh8PKUbcX+zqjzwXhbq1tnuWcqatkZpaFgLDIABOp1olx3tI5tXciF5Hdqple8L6eFzpoJPnGm4ISMd3qgKl8SJOiRoANIMg/FTbYwefC2S4DZim40ModIG2pBj1punJepsn14dOmKEfs5i7qXLty6zq5TIojwZWksD01VQPU1dw3HcSCA5QoNGzMxMdZzHTn8JpwHBrf9y2PRR/OpBwxR/xpWb2K9K7i5xDiPeWmVDdU8gAcrToZKnbWdqU+E8Nu3L9uzlZTcbICQRp+Iid4WT7Vp3/TU6D6ULs28nEsJG2dx/mw7UGScoY5SXRN/Y5tSao0C1bCKEUQqgKo6ACAPlXVzXANzXyvjd2VmbWsT3OPcJZe7cU5Ll0EBEUhdFAiCYDGZOpr3xLCMbpvFgbehEsJG2np+etT4wm6P2XeQSS2Ypr/AJEX+dC8Ibl7FWsJEC5Ks4GqhMxbeQdF8q+yUPUgfNajJd01+4VGKUASyj3qPGXLLLLOpC6xIJPprvNMo+zu0BP3hp6m2v8AI1WxvYpOV5m6Sk/KXivQcMH6vseBj8BKE1KL3XsZPxnhzWLrIRoDoeoO1aL2awi2bSCWz5QTHXU/zNFONcDDhc6LcKkGVjcc4366Vc4fhLkaKq67llBA67ivPlK1R70IaXZFguIy5RhAO88wdDQ3g3DkXwISDaGRzDMZlxmEA5ZUDlVjtXcXDZL7S4+F8mUwTGU7jQwaB8Z4pi8PZs4m2xRMU1xohGMKVCTvEqc0A8zSvKlNNIZPNpiNYBG1x4HIofzCA/KKX+M4LNfF5SVBtZWBD692TrLAGfENTPPrort22xq/EyxMT3axJkgTtMAmPI0/dgg/EMLdu3mzul0omigAZLbRoOpNDi8LLG7l+fYneVOqEdbeQuJBAckR+8qED2iKgxqQdNm1A8juKOcS4FeyXLoTRbrKwUMzjWJIXcctJofgeC4y6v7PDM9s75yEBjmM0QauithMuS32Pw9sJeFwKTnGUka/CNBQDgWED40ftDpdlgT4/AWcjowOWPcUe4FhXs3Ltq6jo0I4DQeqkqQACNhIpN+/ZMW1xGOYXH2EwCzcukE0pKTlJD24qEG0bXwZy10wTttrAB5kf4QPc0auPy19xQHsBbdrL3HuB8zwrhcsgKukeRn50fxFvz+h/WtxwcY0DkmpStFPGWS0MvxoZU9f7ynyYafI7gUnccx7XsPeOZgCCQNRGXVdP8Ip3Rdd6VeKYMDD3QAM28jcCf8Aj60GV04+4WNpJ2IGCzkxOnp6b099kkTubrutu2AjWiQpzPmu3FIJmYy2l08xtFBMGA0LoCROu2+s/SiQO1tZIn5ljHtqYFHlyado8mYMWp2+AvhOM3mfKt24QTsSW/3TTNaB570G4Lw0W/EfiP0FHsPv1/rryoMUWl6g80ouXpMj7a3cN99vm4lxmzAGDA0RV08Q6UvnG4QfDhZ/ib9ZqXjVx3dzcHjFxw0bTmM689eflQpUpuhd3+5q8ZKKqMYr+VX90x64I6XCq28iKV11gKNJGg19PKj1i7hFfLftO/Rg7EEfvCR9D7UmdluG55kfFoNdgupOmxBj5GjXG7pt5LeeZkiRyUSSSNTrSHBKQ7/sM7hWpr22/pQwX8RgyVWzYILNGZ1Gmk6SSTy6etVOKlbUXMg8Cu2gH4cpH1g+1DcFcPe2FeBvEbHQx6bCi/GrGdCvVWX5lKZGuSWebJN+qTfu2ArHajCXFHeK09GthgPlNF7XH8PdVLVrMWzrHhyqMp/eAJ0MafTnleHtszIFEljAA5zRzsxe/wC4tamM2lUSm6JklZpleDUhrwRSjSM0v8SfJjMLcgkLekx07pwaYCtCuO2wiNcYjQQBzpeWnFxfXYbhg5S+RXxXFizs2up5V1Id3jN0kkHKOg5V1LXh0lSKv4iHY0vh+KSyxL6A7H0gn86IcCIuXTdCBSM+UhQCfFlkxvpI96XeKqWCAbgtPuF/Sp8BYKKLmZ1jRcsiWJiJkaSfSZ6Cm9bJRwx2KI1G3PfT51UxXEhby3LjsqCC2p23Og30oJeBa0NS37zEmdd9eVKnEuIM1spmJUSBqT8qyEtTGTioKzQbOIwlzxrfsEbki6IHtmEfKgvFe1+Bs/2S/erg2ie7nzd+X8Ib1rJXeDrUysTTFiQDzvoP3BeMXOIXjaxK2jbCs6IEUKhAiRHi2J3POmLifD0w/C7lpdYQAsVAJJcamIk60g9ib+TEhsyqAjSWIA1jmafuP3ze4feNqHEAhlIIKo4LxB5ZT8vKse0kjU7g2zN72FJwuIO+RrT+W7pPyuGmbsXcnCACfjOb10H5AUGwl9Th8UhGr2QQfNLitHyJPtTV9k9sfdHMye9OnTwrFOmIQxdlQRbuLyzyP8UsfrPzo7bxQC+EAa9BVawfiA5/814w2HLSAfxc9hoKUMQL7VWwSjKBL5h8hm0oVxa3GHuhVkm2wgRuVNFe0OFzXbY0NtCBJnOS7ZWM7ARA269ag47YCWyx20B92C/zrOrYx/CkRdg+MYaxgbaXbotvLlgyvMljtAOnL2otf7a4VR4TcuH91SB/rj8qUON4UKlobwsTz/qDS7jA2Q6kDTn5getURgmrJ3KnQ93O2wY+Gx6Fn/kq1HieL2rquDozKQBBgEjr6x1pOwlkyNdN+dXbO9J8RjTSDxT33C/C8JaAKs6lo0YBtNyY0np5aVUs8Pu5xeQgySAJgjIVeDPxa6jmKv8ACrQdpiAND7jShnaLCn7tlP4Lsx81/Q1Ph9U93uVZV5caXBpVnB6SZ+ZH5VDj+LWMOue7dRQOQMu3kANTWLW2HOCB1Jj6V9wZIMrAMiIA31iOlX+SReYe+0d1Hv3XthlRmLKrbjN4jzPMmhiLVziLku0mTOpO561UFLfJw19lHYW2GuUGR015EexPvQrGYvvcXbIkiCvLlqdOQ026Vd7OYvJYusdkM/6RA9z+dCeEycRbP8U+6mprdyfYp0xqC7jdwrCF72YHwpEgzPOI+VH8Tuh/e/MVFw3ClV0U5mgtA1PT5TFXbuDfwllIGbmI3BA3olwKl8Wwi8N4KlrHgFmOS5K6ADbMAfnFfMJwQ2ceBIyhi6+hBj5THtTRjOFsmOtK0DvGU+XNeX8P1qbtPww2rtpwZzgroNiGED3zH5Vjm6Y1Qi2vYt5q8k0wpwa0N8zep/SKsWuH2xtbX3En60ViNLE+/mynICWjSAT+VAMfwHEYqyyW7bAgr8cL8LAkb7kTWtLZNc2GND1scpNQ0mI2+wOKgf8AbL73hP8ApMV1bX91rqLWwNJmF7cev6V9TDliJzHoJga+nrVbit0oAwG5j5RVnAXiArfiIkeXXeuSOsL3cOoAWTuB9QDSViOCXHzlSDkdlIO/hYiffenHvSUYk6gz+lC+HXs3eGDreOp0mFUkieXnSoylG67j5RU6vsCLPY60FHf2nW4PiXOcpg7iOR8jVW52JDwyXTbU8imaPQ5hTFi+JDvUQ694pKzvoJ57iJq/hTCCfP8AOsnOcZbMLHjhOG6ELtHwFMJbtw7OzkyTAEADYD16mtB7J3EtYOwhMHIGI83Jc/7qSPtHvy9pOiM3+Ygf/NM9nRE/hX/aKfC5RVk2RJSaQlcXsouIv2kMJnIUxoobl/hmPamz7N7PcWbkjxOwkToAJj8zQfFcMQ3S5JzZsxOuo5Aj5Uy8CtkqYECf5U2TtClsxow2PtmVZlRjsCdx5Hr5Vd4awh4kkHQCNZA89P8Amkvj1jQFudcuLuYZSquy9YMbCKneSm76FMcdpV1GnG4Y57U/icT00OaPPQUL7eOLSWwRmDtEcoHi99hQQ49ntkXLj3CRpndjGszB30096E8YugBQSBEHy1Me1ZPJ0XULFDe+zDvFrebCq3Ncp+kfzFKeNXMrDyn/AC+L+VHw/fKrgHKQVB5EwdJ8qE4WzmuImgztknkM3hG3rVeCVxa7EuWNNPuV8Jd09v5VJZxAmqeCUzB01ysOY5Gi7dmbw1Fu4Vj4pWPqRHvWZ9qZmNWFOD3/AAmPKpOJIblq4o3zgfTWvPA8K9pZdRB8ImCTHPwk9fzpn4JgwrCYJcM+gjXMDGvPWocbqbZfn3gkY9rtsZj0qXhxl1TSSwCkkASdACToNas8dw7W8TfWIK3W0/xEqfcEH3qHBYdbjhGbKrEAzsoJEmeUb+1evyjzOA8OwuLJBKrHOCSflEH51bbsEEGa9dbLzhVWB/E5In1itcNvWYEetR3MMG3CkdCJ/OoNTKNKM6w/CMFcttYwttrggEtLxcII+JtFEb6GNI51Lb4GLBXvLC215upHhgGC+uo/Ka0Luwoico9gKqvibH4mQ/6v1oQwDgMY1wZ7d9XWYBEEaelfb/E1uDulYO/xSs5Rl5k7DpvRi5xC1EBCw9ABQC5gVlu6XugwhhuG0IG0bZm+fpWpLqYJvFO0uLxWOU4ezCpARTBJhpLyYE/QCN6b/tGxxsJh2W2Ln7XP8UAC2uYjQHefpXmzw4KwadZJECBJEE6zUfFOFpey583hnmecTz8hXUjrY3YfH2WRXV1KsoYa8iJFc/FbY2k+g/Wl7D2wiqi/CoAHoBAqSuowK3OOH8KfM/pVO/xm6diB6D9aqkVG4rqOJ/vt3/2N866vC7V1LthiT2muRYtwJPeEfMLVjh1yVGgAGnnpXV1NiLYRUqcwB1ySfmY+oNK2M4ykPYS33lwt4g0BSCBuekRtrXV1DFW2HN6YxaLvDuGW3xCXgzhlLF0OqiUIhCSWjxDenXhPDA1uTECY+ddXVPmfqKMPwWZdx/CNi+JnD295FsSY0VczHXoMx9q0a12VvwBNtYAG5O3tXV1UXSSXYklu2V27JNmOa8PZP1YUf4J2YW2pm45mP7v6Gurq7UzEkCu2VlLa5VBkeMkknrA6VX7fJby2HtKAHUtzn8JEz611dSW3uVQXw/UN8QwllcL3ZUQqAAxuygEHTnmANJGJ7H2MSVuXjcJAjKGhdJjlPPrXV1FdSQFXB+4cs8FS3aS1aGVVOg16Ecz50rWCFOaNQwPyMivldVnheZfQnzcIr8VQWsZiLewF1iPRiWX6EVrfZ/DJiMFYZl3QfiYGV8J1XXcGurq7LvBGY3UmUO03Ztu6jDkI0+IuXaR08ROXXmAaB8MU2rdy3dc5iw2LToCGgrGXcGR0866uqbgoUm9mKvazBC3lutduXGuMR49WKqogljMxoNfLpS8qkwyHbSvtdV+F+lIkycs17s/x+42Fs/CIQLsZ8Hg5+lWXxrtu7egMflXV1SzVSY+PCK2U89a85a6uoDT2lSEmurq448tcr3NdXVxx8ivhFdXVxp8mvhrq6uOOBrq6uoaNP//Z');
INSERT INTO Photos (rid, caption, file) VALUES (1000006, 'Re-engineered responsive encryption', 'https://insideretail.sg/wp-content/uploads/2017/12/Pizza-Maru.jpg');
INSERT INTO Photos (rid, caption, file) VALUES (1000007, 'Fully-configurable actuating forecast', 'https://qul.imgix.net/ce1cb95d-8781-41db-8b89-a2cdbbc9d85b/357573_sld.jpg');
INSERT INTO Photos (rid, caption, file) VALUES (1000008, 'Multi-channelled homogeneous secured line', 'https://media-cdn.tripadvisor.com/media/photo-s/01/9a/9f/53/eingang.jpg');
INSERT INTO Photos (rid, caption, file) VALUES (1000009, 'Centralized dedicated throughput', 'https://insideretail.sg/wp-content/uploads/2013/08/brotzeit.jpg');

INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 6, 2);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 7, 2);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 8, 2);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 9, 2);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 13, 2);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 14, 4);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 16, 4);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 19, 4);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 20, 4);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 21, 4);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 13, 6);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 6, 6);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 7, 6);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 8, 6);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 9, 6);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 14, 3);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 16, 3);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 19, 3);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 20, 3);
INSERT INTO Reserves(timeStamp, uid, guestCount) (select now()::timestamptz(0), 21, 3);

INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 1, 1, False, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 1, 2, False, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 2, 3, False, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 2, 4, False, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 3, 5, False, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 3, 6, False, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 4, 7, False, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 4, 8, False, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 5, 9, False, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 5, 10, False, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 6, 11, False, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 6, 12, False, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 6, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 6, 13, False, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 6, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 6, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 6, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 7, 14, False, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 8, 15, False, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 8, 16, False, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 9, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 9, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 9, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 9, 17, False, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 9, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 9, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 9, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 9, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 9, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 9, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 9, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 9, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 9, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 9, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 9, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 9, 18, False, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 9, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 9, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 9, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 9, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 9, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 9, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 9, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 9, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 9, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 9, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 9, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 9, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 10, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 10, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 10, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000000, 10, 19, False, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 10, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 10, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 10, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000000, 10, 20, False, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 10, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 10, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 10, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000000, 10, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 10, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 10, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 10, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000000, 10, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 10, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 10, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 10, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000000, 10, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 10, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 10, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 10, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000000, 10, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 10, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 10, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 10, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000000, 10, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 6, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 6, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 6, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 6, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 6, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 6, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 6, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 6, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 6, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 6, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 7, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 7, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 7, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 7, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000001, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000001, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000001, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000001, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000001, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000001, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 8, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 8, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 8, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000001, 8, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000002, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000002, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000002, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000002, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000002, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000002, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000002, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000003, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000003, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000003, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000003, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000003, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000003, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000003, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000004, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000004, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000004, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000004, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000004, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000004, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000004, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000005, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000005, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000005, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000005, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000005, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000005, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000005, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000006, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000006, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000006, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000006, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000006, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000006, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000006, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000006, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000006, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000006, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000006, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000006, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000006, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000006, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000006, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000006, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000006, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000006, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000006, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000006, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000006, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000006, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000006, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000006, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000006, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000006, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000006, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000006, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000006, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000006, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000006, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000006, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000006, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000006, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000006, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000006, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000006, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000006, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000006, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000006, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000006, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000006, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000006, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000006, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000006, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000006, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000006, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000006, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000006, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000006, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000006, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000006, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000006, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000006, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000006, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000006, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000007, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000007, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000007, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000007, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000007, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000007, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000007, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000007, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000007, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000007, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000007, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000007, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000007, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000007, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000007, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000007, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000007, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000007, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000007, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000007, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000007, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000007, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000007, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000007, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000007, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000007, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000007, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000007, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000007, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000007, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000007, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000007, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000007, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000007, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000007, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000007, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000007, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000007, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000007, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000007, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000007, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000007, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000007, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000007, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000007, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000007, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000007, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000007, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000007, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000007, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000007, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000007, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000007, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000007, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000007, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000007, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000008, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000008, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000008, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000008, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000008, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000008, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000008, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000008, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000008, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000008, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000008, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000008, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000008, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000008, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000008, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000008, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000008, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000008, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000008, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000008, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000008, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000008, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000008, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000008, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000008, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000008, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000008, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000008, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000008, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000008, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000008, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000008, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000008, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000008, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000008, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000008, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000008, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000008, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000008, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000008, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000008, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000008, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000008, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000008, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000008, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000008, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000008, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000008, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000008, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000008, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000008, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000008, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000008, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000008, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000008, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000008, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 3, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 3, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 3, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 3, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 4, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 4, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 4, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 4, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000009, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000009, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000009, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000009, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000009, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000009, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 5, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 5, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 5, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000009, 5, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000010, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000010, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000010, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000010, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000010, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000010, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000010, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000010, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000010, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000010, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000010, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000010, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000010, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000010, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000010, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000010, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000010, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000010, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000010, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000010, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000010, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000010, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000010, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000010, 1, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000010, 1, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000010, 1, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000010, 1, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000010, 1, NULL, True, 8);

INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000010, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000010, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000010, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10AM', 1000010, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000010, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000010, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000010, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('12PM', 1000010, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000010, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000010, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000010, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('2PM', 1000010, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000010, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000010, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000010, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('4PM', 1000010, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000010, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000010, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000010, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('6PM', 1000010, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000010, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000010, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000010, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('8PM', 1000010, 2, NULL, True, 8);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000010, 2, NULL, True, 2);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000010, 2, NULL, True, 4);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000010, 2, NULL, True, 6);
INSERT INTO TABLES(time, rid, bid, reserveId, vacant, seats) VALUES ('10PM', 1000010, 2, NULL, True, 8);
