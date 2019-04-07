DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS Restaurants CASCADE;
DROP TABLE IF EXISTS Branches CASCADE;
DROP TABLE IF EXISTS Owners CASCADE;
DROP TABLE IF EXISTS Ratings CASCADE;
DROP TABLE IF EXISTS Incentives CASCADE;
DROP TABLE IF EXISTS Discounts CASCADE;
DROP TABLE IF EXISTS Rewards CASCADE;
DROP TABLE IF EXISTS Choose CASCADE;
DROP TABLE IF EXISTS Gives CASCADE;
DROP TABLE IF EXISTS Response CASCADE;
DROP TABLE IF EXISTS Tables CASCADE;
DROP TABLE IF EXISTS Reserves CASCADE;
DROP TABLE IF EXISTS Photos CASCADE;

create table Users (
    uid VARCHAR(50),
    name VARCHAR(50),
    email VARCHAR(50),
    password VARCHAR(50),
    primary key (uid)
);

-- may need another specific cid ... for uniquely identifying ?? may
-- not be a good idea to have foreign key as primary key bc that means
-- one to one relationship !!:////
-- https://stackoverflow.com/questions/10982992/is-it-fine-to-have-foreign-key-as-primary-key
create table Customers (
    uid VARCHAR(50),
    address VARCHAR(50),
    pNumber VARCHAR(50),
    rewardPt INT,
    foreign key (uid) references Users on delete cascade
);

-- maybe should include price range, in dollar signs! ($ is cheap, $$$$ is expensive)
create table Restaurants (
    rid             VARCHAR(50),
    name            TEXT,
    type            TEXT,
    description     TEXT,
    primary key (rid)
);

--this is ok, doesn't imply one to one relationship
create table Branches (
    bid VARCHAR(50),
    rid VARCHAR(50),
    pNumber VARCHAR(20),
    address VARCHAR(50),
    location TEXT,
    primary key (bid),
    foreign key (rid) references Restaurants (rid) on delete cascade
);

create table Owners (
    uid VARCHAR(50),
    bid VARCHAR(50),
    primary key (uid,bid),
    foreign key (uid) references Users (uid) on delete cascade,
    foreign key (bid) references Branches (bid) on delete cascade
);

create table Ratings (
        rtid VARCHAR(50),
        uid VARCHAR(50),
        score INT,
        review TEXT,
        primary key (rtid),
        foreign key (uid) references Users (uid) on delete cascade
);

CREATE TABLE Incentives (
    iid         VARCHAR(20),
    primary key (iid)
);

-- shouldn't this be a discount to a specific restaurant????? idk mayb just me
-- but i think should have rid or bid also, not just some random voucher
-- same issue as above... foreign key should prob not be primary key
CREATE TABLE Discounts (
    iid         VARCHAR(20),
    percent     INTEGER,
    PRIMARY KEY (iid),
    FOREIGN KEY (iid) REFERENCES Incentives (iid) on delete cascade
);

-- same issue as above... foreign key should prob not be primary key
CREATE TABLE Rewards (
    iid         VARCHAR(20),
    rewardName       TEXT,
    value       INTEGER,
    PRIMARY KEY (iid),
    FOREIGN KEY (iid) REFERENCES Incentives (iid) on delete cascade
);

create table Choose (
    timeStamp DATE,
    uid VARCHAR(50),
    iid VARCHAR(20),
    foreign key (uid) references Users (uid) on delete cascade,
    foreign key (iid) references Incentives (iid) on delete cascade
);

create table Gives  (
    timeStamp DATE,
    uid VARCHAR(50),
    rtid VARCHAR(50),
    bid varchar(50),
    foreign key (rtid) references Ratings (rtid) on delete cascade,
    foreign key (uid) references Users (uid) on delete cascade,
    foreign key (bid) references Branches (bid) on delete cascade
);

create table Response (
    timeStamp DATE,
    rtid VARCHAR(50),
    bid VARCHAR(50),
    textResponse TEXT

);

CREATE TABLE  Photos (
    rid             VARCHAR(50),
    pid             VARCHAR(50),
    caption         TEXT,
    file            TEXT,
    PRIMARY KEY (pid),
    FOREIGN KEY (rid) references Restaurants on delete cascade
);

create table Reserves (
    reserveId VARCHAR(50),
    timeStamp DATE,
    guestCount INT
);

create table Tables (
    tid VARCHAR(20),
    bid VARCHAR(50),
    reserveId VARCHAR(50)
);

insert into Users (uid, name, email, password) values ('kyarnold0', 'Kelci Yarnold', 'kyarnold0@pen.io', 'LokKcX');
insert into Users (uid, name, email, password) values ('csimione1', 'Coop Simione', 'csimione1@tripadvisor.com', 'xlYYRemeZle');
insert into Users (uid, name, email, password) values ('aormes2', 'Audrey Ormes', 'aormes2@joomla.org', 'wBJ9Sjbn1h0s');
insert into Users (uid, name, email, password) values ('sducarme3', 'Salaidh ducarme', 'sducarme3@miitbeian.gov.cn', 'Y6l0O14p');
insert into Users (uid, name, email, password) values ('hdanell4', 'Hatty Danell', 'hdanell4@parallels.com', 'IJL9bMTgjaO');
insert into Users (uid, name, email, password) values ('bbrafferton5', 'Britta Brafferton', 'bbrafferton5@ft.com', 'kDjWqwWbF');
insert into Users (uid, name, email, password) values ('dde6', 'Darleen De Angelis', 'dde6@altervista.org', 'f8p41A');
insert into Users (uid, name, email, password) values ('bconant7', 'Boigie Conant', 'bconant7@cnn.com', 'XsRzBxO');
insert into Users (uid, name, email, password) values ('aindruch8', 'Abra Indruch', 'aindruch8@wix.com', 'ziGUWE1s7C');
insert into Users (uid, name, email, password) values ('tschermick9', 'Tammie Schermick', 'tschermick9@phoca.cz', 'idoXUol6Lu');
insert into Users (uid, name, email, password) values ('pikachu1', 'Oliver Zheng', 'a@b.com', '123456');

insert into Customers (uid, address, pNumber, rewardPt) values ('csimione1','7 Waywood Alley', '4042239432', 90);
insert into Customers (uid, address, pNumber, rewardPt) values ('aormes2', '4915 Utah Drive', '9387835197', 25);
insert into Customers (uid, address, pNumber, rewardPt) values ('kyarnold0','37529 8th Park', '2299409576', 13);
insert into Customers (uid, address, pNumber, rewardPt) values ('sducarme3','6 Clove Drive', '5319398655', 6);
insert into Customers (uid, address, pNumber, rewardPt) values ('hdanell4','834 Hollow Ridge Park', '9737475346', 54);
insert into Customers (uid, address, pNumber, rewardPt) values ('bbrafferton5','45 Cambridge Parkway', '7807316897', 99);
insert into Customers (uid, address, pNumber, rewardPt) values ('dde6','82 Brickson Park Alley', '2058110589', 2);
insert into Customers (uid, address, pNumber, rewardPt) values ('bconant7','6386 Waxwing Street', '2961713117', 32);
insert into Customers (uid, address, pNumber, rewardPt) values ('aindruch8','0 Holy Cross Plaza', '4965645255', 6);
insert into Customers (uid, address, pNumber, rewardPt) values ('tschermick9','3274 Butterfield Terrace', '1828171768', 17);
insert into Customers (uid, address, pNumber, rewardPt) values ('pikachu1','5 Olive Town', '1828171238', 100);

INSERT INTO Restaurants (rid, name, type, description) VALUES ('fMGw-322686322', 'Lo Scoglio', 'Italian', 'Pellentesque ultrices mattis odio.');
INSERT INTO Restaurants (rid, name, type, description) VALUES ('iAgm-601168182', 'La Mesa', 'Carribean', 'Proin interdum mauris non ligula pellentesque ultrices.');
INSERT INTO Restaurants (rid, name, type, description) VALUES ('Zfna-146983352', 'El Toro', 'Carribean', 'Quisque ut erat.');
INSERT INTO Restaurants (rid, name, type, description) VALUES ('WCpV-011495875', 'Apollo Greek Taverna', 'Greek', 'Nulla tellus.');
INSERT INTO Restaurants (rid, name, type, description) VALUES ('CquA-208726972', 'Komi', 'Greek', 'Suspendisse ornare consequat lectus.');
INSERT INTO Restaurants (rid, name, type, description) VALUES ('VWOv-225141445', 'Mrs.Greek', 'Greek', 'Phasellus sit amet erat.');
INSERT INTO Restaurants (rid, name, type, description) VALUES ('unAw-053722056', 'Pastaciutta', 'Italian', 'Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante.');
INSERT INTO Restaurants (rid, name, type, description) VALUES ('njYe-609049276', 'Falafel King', 'Mediterranean', 'Proin leo odio, porttitor id, consequat in, consequat ut, nulla.');
INSERT INTO Restaurants (rid, name, type, description) VALUES ('gBdC-272348696', 'Ramen-ya', 'Japanese', 'Nullam sit amet turpis elementum ligula vehicula consequat.');
INSERT INTO Restaurants (rid, name, type, description) VALUES ('ebGH-764302971', 'El Mejillón', 'Carribean', 'Vestibulum rutrum rutrum neque.');

INSERT INTO Branches (bid, rid, pNumber, address, location) VALUES ('mHLy-664734', 'fMGw-322686322', '+27 816 806 7329', '3646 Drewry Terrace', 'CapiLand');
INSERT INTO Branches (bid, rid, pNumber, address, location) VALUES ('qojL-278179', 'iAgm-601168182', '+33 124 785 5818', '37 Sommers Road', 'Jurong East');
INSERT INTO Branches (bid, rid, pNumber, address, location) VALUES ('PwNr-270848', 'Zfna-146983352', '+62 173 982 3684', '830 Rigney Drive', 'Clarke Quay');
INSERT INTO Branches (bid, rid, pNumber, address, location) VALUES ('EFUI-983629', 'WCpV-011495875', '+63 732 509 2140', '6 Dayton Crossing', 'Mars');
INSERT INTO Branches (bid, rid, pNumber, address, location) VALUES ('hwaA-126728', 'CquA-208726972', '+359 793 675 4054', '8179 Laurel Parkway', 'Over Rainbow');
INSERT INTO Branches (bid, rid, pNumber, address, location) VALUES ('RGxs-464381', 'VWOv-225141445', '+54 958 380 1486', '26107 Mcguire Place', 'Pallet Town');
INSERT INTO Branches (bid, rid, pNumber, address, location) VALUES ('ylpx-290411', 'unAw-053722056', '+86 968 908 1787', '6136 Cardinal Street', 'Mushroom Kingdom');
INSERT INTO Branches (bid, rid, pNumber, address, location) VALUES ('OjzP-192290', 'njYe-609049276', '+216 836 236 9765', '475 Melby Road', 'Emory University');
INSERT INTO Branches (bid, rid, pNumber, address, location) VALUES ('vqRn-592271', 'gBdC-272348696', '+63 150 562 9719', '81944 Onsgard Point', 'Itomori Square');
INSERT INTO Branches (bid, rid, pNumber, address, location) VALUES ('uyev-477440', 'ebGH-764302971', '+502 168 507 2788', '138 Jackson Alley', 'Neverland');

insert into Owners (uid, bid) values ('kyarnold0', 'mHLy-664734');
insert into Owners (uid, bid) values ('csimione1', 'qojL-278179');
insert into Owners (uid, bid) values ('aormes2', 'uyev-477440');
insert into Owners (uid, bid) values ('sducarme3', 'EFUI-983629');
insert into Owners (uid, bid) values ('hdanell4', 'RGxs-464381');
insert into Owners (uid, bid) values ('bbrafferton5', 'hwaA-126728');
insert into Owners (uid, bid) values ('dde6', 'vqRn-592271');
insert into Owners (uid, bid) values ('bconant7', 'PwNr-270848');
insert into Owners (uid, bid) values ('aindruch8', 'ylpx-290411');
insert into Owners (uid, bid) values ('tschermick9', 'OjzP-192290');

insert into Ratings (rtid, uid, score, review) values ('Mbxw1905', 'kyarnold0', 5, 'Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices. Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.');
insert into Ratings (rtid, uid, score, review) values ('Cejl0089', 'csimione1', 10, 'Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.');
insert into Ratings (rtid, uid, score, review) values ('Hyjz3444', 'aormes2', 3, 'Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla.');
insert into Ratings (rtid, uid, score, review) values ('iXQd9925', 'sducarme3', 3, 'Duis aliquam convallis nunc.');
insert into Ratings (rtid, uid, score, review) values ('mJCE6787', 'hdanell4', 3, 'Vestibulum quam sapien, varius ut, blandit non, interdum in, ante. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis faucibus accumsan odio. Curabitur convallis. Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus. Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci.');
insert into Ratings (rtid, uid, score, review) values ('EaTB0221', 'bbrafferton5', 5, 'Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit.');
insert into Ratings (rtid, uid, score, review) values ('Sinw9859', 'dde6', 1, 'Phasellus in felis.');
insert into Ratings (rtid, uid, score, review) values ('QmOF6968', 'bconant7', 2, 'Ut tellus.');
insert into Ratings (rtid, uid, score, review) values ('erTf2631', 'aindruch8', 7, 'Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.');
insert into Ratings (rtid, uid, score, review) values ('sgqX4398', 'tschermick9', 4, 'Duis mattis egestas metus. Aenean fermentum.');

INSERT INTO Incentives (iid) VALUES ('875-378-173');
INSERT INTO Incentives (iid) VALUES ('307-527-634');
INSERT INTO Incentives (iid) VALUES ('680-546-784');
INSERT INTO Incentives (iid) VALUES ('404-334-039');
INSERT INTO Incentives (iid) VALUES ('910-678-546');
INSERT INTO Incentives (iid) VALUES ('180-446-808');
INSERT INTO Incentives (iid) VALUES ('423-043-204');
INSERT INTO Incentives (iid) VALUES ('148-256-043');
INSERT INTO Incentives (iid) VALUES ('551-045-818');
INSERT INTO Incentives (iid) VALUES ('177-510-070');

INSERT INTO Discounts (iid, percent) VALUES ('875-378-173', 50);
INSERT INTO Discounts (iid, percent) VALUES ('307-527-634', 60);
INSERT INTO Discounts (iid, percent) VALUES ('680-546-784', 80);
INSERT INTO Discounts (iid, percent) VALUES ('404-334-039', 80);
INSERT INTO Discounts (iid, percent) VALUES ('910-678-546', 60);
INSERT INTO Discounts (iid, percent) VALUES ('177-510-070', 80);
INSERT INTO Discounts (iid, percent) VALUES ('551-045-818', 40);
INSERT INTO Discounts (iid, percent) VALUES ('148-256-043', 80);
INSERT INTO Discounts (iid, percent) VALUES ('423-043-204', 80);
INSERT INTO Discounts (iid, percent) VALUES ('180-446-808', 30);

INSERT INTO Rewards (iid, rewardName, value) VALUES ('875-378-173', 'bxqiyoozsv', 70);
INSERT INTO Rewards (iid, rewardName, value) VALUES ('307-527-634', 'htmbayocaa', 85);
INSERT INTO Rewards (iid, rewardName, value) VALUES ('680-546-784', 'ivcfzpdxmc', 37);
INSERT INTO Rewards (iid, rewardName, value) VALUES ('404-334-039', 'twaniqtyfn', 45);
INSERT INTO Rewards (iid, rewardName, value) VALUES ('910-678-546', 'zqtgtkcnai', 53);
INSERT INTO Rewards (iid, rewardName, value) VALUES ('180-446-808', 'nfstzzzetz', 5);
INSERT INTO Rewards (iid, rewardName, value) VALUES ('423-043-204', 'xadkaruenn', 52);
INSERT INTO Rewards (iid, rewardName, value) VALUES ('148-256-043', 'yrrpbkdjgv', 87);
INSERT INTO Rewards (iid, rewardName, value) VALUES ('551-045-818', 'mctrawlqfj', 62);
INSERT INTO Rewards (iid, rewardName, value) VALUES ('177-510-070', 'zvaslgvabq', 67);

insert into Choose (timeStamp, uid, iid) values ('2014-08-23 07:51:21', 'kyarnold0','875-378-173');
insert into Choose (timeStamp, uid, iid) values ('2017-11-27 14:32:13', 'csimione1','307-527-634');
insert into Choose (timeStamp, uid, iid) values ('2017-01-16 17:57:39', 'aormes2','680-546-784');
insert into Choose (timeStamp, uid, iid) values ('2016-04-23 18:44:43', 'sducarme3','910-678-546');
insert into Choose (timeStamp, uid, iid) values ('2016-12-04 07:13:22', 'hdanell4','180-446-808');
insert into Choose (timeStamp, uid, iid) values ('2017-12-13 11:16:46', 'bbrafferton5','423-043-204');
insert into Choose (timeStamp, uid, iid) values ('2014-07-31 06:42:44', 'dde6','148-256-043');
insert into Choose (timeStamp, uid, iid) values ('2017-08-20 16:12:12','bconant7','551-045-818');
insert into Choose (timeStamp, uid, iid) values ('2017-02-01 12:22:46','aindruch8','404-334-039');
insert into Choose (timeStamp, uid, iid) values ('2017-11-30 00:38:00', 'tschermick9','177-510-070');

insert into Gives (timeStamp, uid, rtid, bid) values ('2019-04-27 16:13:44','kyarnold0','Mbxw1905','mHLy-664734');
insert into Gives (timeStamp, uid, rtid, bid) values ('2019-04-19 08:47:04','csimione1','Cejl0089','qojL-278179');
insert into Gives (timeStamp, uid, rtid, bid) values ('2019-04-19 15:48:43','aormes2','Hyjz3444', 'PwNr-270848');
insert into Gives (timeStamp, uid, rtid, bid) values ('2019-04-22 02:28:28','sducarme3','iXQd9925','EFUI-983629');
insert into Gives (timeStamp, uid, rtid, bid) values ('2019-04-18 23:22:06','hdanell4','mJCE6787', 'hwaA-126728');
insert into Gives (timeStamp, uid, rtid, bid) values ('2019-04-24 06:21:24', 'bbrafferton5','EaTB0221', 'RGxs-464381');
insert into Gives (timeStamp, uid, rtid, bid) values ('2019-04-23 00:03:41','dde6','Sinw9859','ylpx-290411');
insert into Gives (timeStamp, uid, rtid, bid) values ('2019-04-26 11:59:26','bconant7','QmOF6968','OjzP-192290');
insert into Gives (timeStamp, uid, rtid, bid) values ('2019-04-27 00:28:58','aindruch8','erTf2631','vqRn-592271');
insert into Gives (timeStamp, uid, rtid, bid) values ('2019-04-17 09:41:11', 'tschermick9','sgqX4398', 'uyev-477440');

insert into Response (timeStamp, rtid, bid, textResponse) values ('2019-04-19 08:47:04','Cejl0089','qojL-278179','Mauris sit amet eros. Suspendisse accumsan tortor quis turpis. Sed ante. Vivamus tortor.');
insert into Response (timeStamp, rtid, bid, textResponse) values ('2019-04-19 15:48:43','Hyjz3444', 'PwNr-270848','Mauris ullamcorper purus sit amet nulla. Quisque arcu libero, rutrum ac, lobortis vel, dapibus at, diam.');
insert into Response (timeStamp, rtid, bid, textResponse) values ('2019-04-22 02:28:28','iXQd9925','EFUI-983629','Nulla mollis molestie lorem. Quisque ut erat. Curabitur gravida nisi at nibh.');
insert into Response (timeStamp, rtid, bid, textResponse) values ('2019-04-18 23:22:06','mJCE6787','hwaA-126728','Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue.');
insert into Response (timeStamp, rtid, bid, textResponse) values ('2019-04-23 00:03:41','Sinw9859','ylpx-290411','Aenean lectus. Pellentesque eget nunc.');
insert into Response (timeStamp, rtid, bid, textResponse) values ('2019-04-26 11:59:26','QmOF6968','OjzP-192290','Curabitur convallis. Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor.');
insert into Response (timeStamp, rtid, bid, textResponse) values ('2019-04-27 00:28:58','erTf2631','vqRn-592271','Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem.');
insert into Response (timeStamp, rtid, bid, textResponse) values ('2019-04-17 09:41:11','sgqX4398','uyev-477440','In hac habitasse platea dictumst. Maecenas ut massa quis augue luctus tincidunt.');
insert into Response (timeStamp, rtid, bid, textResponse) values ('2019-04-24 06:21:24','EaTB0221','RGxs-464381','Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros.');
insert into Response (timeStamp, rtid, bid, textResponse) values ('2019-04-27 16:13:44','Mbxw1905','mHLy-664734','Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti.');

INSERT INTO Photos (rid, pid, caption, file) VALUES ('fMGw-322686322', 'Eou-811351331-LrG', 'Re-engineered full-range methodology', 'http://dummyimage.com/174x108.png/dddddd/000000');
INSERT INTO Photos (rid, pid, caption, file) VALUES ('iAgm-601168182', 'CsI-382818924-YgZ', 'Realigned fresh-thinking portal', 'http://dummyimage.com/246x118.bmp/ff4444/ffffff');
INSERT INTO Photos (rid, pid, caption, file) VALUES ('Zfna-146983352', 'rHh-945997725-MTQ', 'Team-oriented homogeneous hierarchy', 'http://dummyimage.com/151x131.png/cc0000/ffffff');
INSERT INTO Photos (rid, pid, caption, file) VALUES ('WCpV-011495875', 'Ihm-380887401-BDS', 'Focused heuristic utilisation', 'http://dummyimage.com/174x113.bmp/ff4444/ffffff');
INSERT INTO Photos (rid, pid, caption, file) VALUES ('CquA-208726972', 'uFi-105203583-TtL', 'Diverse incremental contingency', 'http://dummyimage.com/196x185.jpg/ff4444/ffffff');
INSERT INTO Photos (rid, pid, caption, file) VALUES ('VWOv-225141445', 'ZLp-957760797-clG', 'User-friendly clear-thinking support', 'http://dummyimage.com/234x219.png/ff4444/ffffff');
INSERT INTO Photos (rid, pid, caption, file) VALUES ('unAw-053722056', 'uBR-460594002-LYe', 'Re-engineered responsive encryption', 'http://dummyimage.com/135x237.jpg/5fa2dd/ffffff');
INSERT INTO Photos (rid, pid, caption, file) VALUES ('njYe-609049276', 'OMs-371828441-wjH', 'Fully-configurable actuating forecast', 'http://dummyimage.com/180x137.png/5fa2dd/ffffff');
INSERT INTO Photos (rid, pid, caption, file) VALUES ('gBdC-272348696', 'JRM-615790334-iRd', 'Multi-channelled homogeneous secured line', 'http://dummyimage.com/230x144.png/ff4444/ffffff');
INSERT INTO Photos (rid, pid, caption, file) VALUES ('ebGH-764302971', 'riO-333182348-wDV', 'Centralized dedicated throughput', 'http://dummyimage.com/174x242.bmp/dddddd/000000');

insert into Reserves (reserveId, timeStamp, guestCount) values ('aCWK2009', '2019-07-17 09:04:46', 3);
insert into Reserves (reserveId, timeStamp, guestCount) values ('pVMx8145', '2019-06-23 07:36:22', 9);
insert into Reserves (reserveId, timeStamp, guestCount) values ('DhFu9514', '2019-06-12 21:03:48', 5);
insert into Reserves (reserveId, timeStamp, guestCount) values ('MXez1118', '2019-08-20 22:51:20', 8);
insert into Reserves (reserveId, timeStamp, guestCount) values ('VUpH7740', '2019-08-31 14:17:15', 1);
insert into Reserves (reserveId, timeStamp, guestCount) values ('UTMh4236', '2019-05-25 09:30:13', 10);
insert into Reserves (reserveId, timeStamp, guestCount) values ('qaWt9037', '2019-07-09 23:47:37', 2);
insert into Reserves (reserveId, timeStamp, guestCount) values ('bXQI9268', '2019-06-11 03:58:46', 6);
insert into Reserves (reserveId, timeStamp, guestCount) values ('xFZk2289', '2019-07-16 11:59:38', 5);
insert into Reserves (reserveId, timeStamp, guestCount) values ('HlVb5951', '2019-06-29 08:24:08', 8);

insert into Tables(tid, bid, reserveId) values ('a4','qojL-278179','pVMx8145');
insert into Tables(tid, bid, reserveId) values ('a1','mHLy-664734','aCWK2009');
insert into Tables(tid, bid, reserveId) values ('e4','PwNr-270848','DhFu9514');
insert into Tables(tid, bid, reserveId) values ('a9','EFUI-983629','MXez1118');
insert into Tables(tid, bid, reserveId) values ('n2','hwaA-126728','VUpH7740');
insert into Tables(tid, bid, reserveId) values ('b4','uyev-477440','UTMh4236');
insert into Tables(tid, bid, reserveId) values ('c3','RGxs-464381','qaWt9037');
insert into Tables(tid, bid, reserveId) values ('z7','ylpx-290411','bXQI9268');
insert into Tables(tid, bid, reserveId) values ('l4','OjzP-192290','xFZk2289');
insert into Tables(tid, bid, reserveId) values ('c2','vqRn-592271','HlVb5951');
