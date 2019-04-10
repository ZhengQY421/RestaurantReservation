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
    PRIMARY KEY(rtid, rid, bid, timeStamp),
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
    FOREIGN KEY (rid, bid) references Branches (rid, bid)
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
INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, 'Blk 965C Friesen Crescent Way SINGAPORE 706461', '95551651', 55 from Users U where U.name='Pikachu Pie';
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

INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Putien 19th Year Anniversary!', 'Celebrate with us and enjoy 50% discount at all Putien Outlets from 12 April to 12 May!', 0);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Summer Promotion at Brotzeit', 'Enjoy 20% off on all main course at Brotzeit this summer. Promotion is valid only from 1st April to 30th April.', 50);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Itacho Sushi 10th Year Anniversary Special', 'Enjoy 40% off at all Itacho Sushi outlets this April!', 75);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Party away at Hard Rock Cafe this April!', 'This April, Hard Rock Cafe will be hosting a 15% off on all main course from 12 April to 19 April! Time to party the heat away!', 35);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Enjoy 1 for 1 Pizza at Pizza Maru', 'Share a pizza with your loved ones this April!', 80);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Spend time with your family @ Paris Baguette!', 'Spend some time with your family at Paris Baguette! 30% off on all items. Hurry down today!', 75);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Leave your mark at Graffiti Cafe!', 'Leave your mark at Graffiti Cafe this April and enjoy a 10% discount on all main course items.', 15);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Haidilao dinner promotion', 'Enjoy a 10% discount during dinner period at Hai Di Lao. Promotion is valid at all outlets.', 30);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Its Summer time @ Summer Hill', 'Cool yourself down this summer at Summer Hill and enjoy 25% off on all items while you are there!', 50);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Spicy red hot wings @ Bonchon', 'Sweat it out with Bonchon Spicy Red Hot Wings! Enjoy 70% off on second meal ordered', 45);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('All-inclusive Premium Set Lunch @ Putien', 'Enjoy your lunch at Putien for only $20 Nett', 75);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Haidilao All-day set meal','$15 nett for all Haidilao All-day set meals. Valid only at selected outlets', 100);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Bonchon: 6pcs wings for $5 nett!','Delicious wings waiting for you!', 25);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('MEGA PROMO at Paris Baguette Cafe','$5 voucher for all pastries!', 25);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Giant teddy bear','Donate this teddy bear to a child in need', 50);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Movie Tickets', 'A pair of movie tickets to enjoy with your partner', 100);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Mini Note Book','Record your travels with this mini note book', 20);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Spill-Free Tumbler', 'No more spills to worry about!', 200);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Portable Charger', '180 00mAh, 1kg', 150);
INSERT INTO Incentives (incentiveName, description, redeemPts) VALUES ('Couple Vacation Stay','Enjoy a 2D1N vacation stay at Resort World Sentosa with your partner!', 500);

INSERT INTO Discounts (iid, percent) select iid, 50 from Incentives I where I.incentiveName='Putien 19th Year Anniversary!';
INSERT INTO Discounts (iid, percent) select iid, 20 from Incentives I where I.incentiveName='Summer Promotion at Brotzeit';
INSERT INTO Discounts (iid, percent) select iid, 40 from Incentives I where I.incentiveName='Itacho Sushi 10th Year Anniversary Special';
INSERT INTO Discounts (iid, percent) select iid, 15 from Incentives I where I.incentiveName='Party away at Hard Rock Cafe this April!';
INSERT INTO Discounts (iid, percent) select iid, 50 from Incentives I where I.incentiveName='Enjoy 1 for 1 Pizza at Pizza Maru';
INSERT INTO Discounts (iid, percent) select iid, 30 from Incentives I where I.incentiveName='Spend time with your family @ Paris Baguette!';
INSERT INTO Discounts (iid, percent) select iid, 10 from Incentives I where I.incentiveName='Leave your mark at Graffiti Cafe!';
INSERT INTO Discounts (iid, percent) select iid, 10 from Incentives I where I.incentiveName='Haidilao dinner promotion';
INSERT INTO Discounts (iid, percent) select iid, 25 from Incentives I where I.incentiveName='Its Summer time @ Summer Hill';
INSERT INTO Discounts (iid, percent) select iid, 70 from Incentives I where I.incentiveName='Spicy red hot wings @ Bonchon';

INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='All-inclusive Premium Set Lunch @ Putien';
INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='Haidilao All-day set meal';
INSERT INTO Prizes (iid) select iid from Incentives I where I.incentiveName='Bonchon: 6pcs wings for $5 nett!';
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
insert into Choose (timeStamp, uid, iid) (select  now()::timestamptz(0), (select U.uid from Users U where U.name='Pikachu'), (select I.iid from Incentives I WHERE I.incentivename='Haidilao dinner promotion'));
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

INSERT INTO Photos (rid, caption, file) VALUES (1000000, 'Re-engineered full-range methodology', 'http://dummyimage.com/174x108.png/dddddd/000000');
INSERT INTO Photos (rid, caption, file) VALUES (1000001, 'Realigned fresh-thinking portal', 'http://dummyimage.com/246x118.bmp/ff4444/ffffff');
INSERT INTO Photos (rid, caption, file) VALUES (1000002, 'Team-oriented homogeneous hierarchy', 'http://dummyimage.com/151x131.png/cc0000/ffffff');
INSERT INTO Photos (rid, caption, file) VALUES (1000003, 'Focused heuristic utilisation', 'http://dummyimage.com/174x113.bmp/ff4444/ffffff');
INSERT INTO Photos (rid, caption, file) VALUES (1000004, 'Diverse incremental contingency', 'http://dummyimage.com/196x185.jpg/ff4444/ffffff');
INSERT INTO Photos (rid, caption, file) VALUES (1000005, 'User-friendly clear-thinking support', 'http://dummyimage.com/234x219.png/ff4444/ffffff');
INSERT INTO Photos (rid, caption, file) VALUES (1000006, 'Re-engineered responsive encryption', 'http://dummyimage.com/135x237.jpg/5fa2dd/ffffff');
INSERT INTO Photos (rid, caption, file) VALUES (1000007, 'Fully-configurable actuating forecast', 'http://dummyimage.com/180x137.png/5fa2dd/ffffff');
INSERT INTO Photos (rid, caption, file) VALUES (1000008, 'Multi-channelled homogeneous secured line', 'http://dummyimage.com/230x144.png/ff4444/ffffff');
INSERT INTO Photos (rid, caption, file) VALUES (1000009, 'Centralized dedicated throughput', 'http://dummyimage.com/174x242.bmp/dddddd/000000');

INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 2);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 2);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 2);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 2);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 2);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 4);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 4);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 4);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 4);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 4);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 6);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 6);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 6);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 6);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 6);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 3);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 3);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 3);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 3);
INSERT INTO Reserves(timeStamp, guestCount) (select now()::timestamptz(0), 3);

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
