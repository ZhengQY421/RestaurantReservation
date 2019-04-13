var express = require("express");
var router = express.Router();
var passport = require("passport");

/* Connect to Database */
const { Pool } = require("pg");
const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

const { checkLoggedIn, checkLoggedOut } = require("./middleware/auth");

function failRegister(req, res) {
    req.flash("error", "Sorry, an error has occurred. Please try again later.");
    res.redirect("/");
}

function makeid(name) {
    var loc = name.indexOf(" ");
    var first = name.slice(0, loc).toLowerCase();
    var last = name.slice(loc + 1).toLowerCase();
    last.replace(" ", "");
    var digit = Math.floor(Math.random() * 11);

    return first.slice(0, 1) + last + digit + "";
}

/* ---- Post Function for Deleting an Account ---- */
router.post("/deleteuser", function(req, res, next) {
    pool.connect(function(err, client, done) {
        function abort(err) {
            if (err) {
                client.query("ROLLBACK", function(err) {
                    done();
                });
                return true;
            }
            return false;
        }
        client.query("BEGIN", function(err, res1) {
            if (abort(err)) {
                return;
            }
            client.query(
            "delete from users where uid=$1",
            [req.body.uid],
                function(err, res3) {
                    if (abort(err)) {
                        return;
                    }

                    client.query("COMMIT", function(err, res4) {
                        if (abort(err)) {
                            return;
                        }
                        req.flash(
                            "success",
                            "Account deleted!"
                        );
                        res.redirect("/");
                        done();
                    });
                });
        });
    });
});


/* ---- Post Function for Login ---- */
router.post(
    "/login",
    checkLoggedOut,
    passport.authenticate("local", {
        failureRedirect: "/",
        failureFlash: true
    }),
    function(req, res, next) {
        req.flash("success", "You have logged in!");

        if (req.user.iscustomer) {
            res.redirect("/");
        } else {
            res.redirect("/account/owner_profile");
        }
    }
);

/* ---- Get/Post Function for Log Out ---- */
router.all("/logout", checkLoggedIn, function(req, res, next) {
    req.logout();
    req.flash("success", "You have been logged out!");
    res.redirect("/");
});

/* ---- Post Function for Sign up ---- */
router.post("/signup", checkLoggedOut, function(req, res, next) {
    pool.query(
        "select 1 from users where email=$1;",
        [req.body.signupEmail],
        function(err, data) {
            if (err) {
                console.log(err);
                failRegister(req, res);
            } else {
                if (data.rowCount === 0) {
                    var name = req.body.signupName;
                    var email = req.body.signupEmail;
                    var password = req.body.signupPassword;
                    var addr = req.body.signupAddr;
                    var pNum = req.body.signupPNum;

                    pool.query(
                        "insert into Users (name, email, password) values ($1, $2, $3) returning *",
                        [name, email, password],
                        function(err, data1) {
                            //console.log(data1);
                            if (err) {
                                console.error(
                                    "Error executing query",
                                    err.stack
                                );
                            } else {
                                var sql_query = "";

                                if (req.body.signupType === "Customer") {
                                    console.log(addr);

                                    pool.query(
                                        "INSERT INTO Customers(uid, address, pNumber, rewardPt) values ((select U.uid from Users U where U.name=$1 and U.email=$2), $3, $4, 0)",
                                        [name, email, addr, pNum],
                                        (err, data) => {
                                            if (err) {
                                                console.log(err);
                                                console.log("error insert");
                                                failRegister(req, res);
                                                return;
                                            }
                                            req.flash(
                                                "success",
                                                "Account created. You may log in now."
                                            );
                                            res.redirect("/");
                                        }
                                    );
                                } else if (req.body.signupType === "Owner") {
                                    req.session.valid = name;
                                    res.render('restaurant/add', {
                                        title: 'Add a Restaurant',
                                        data: data1.rows,
                                        currentUser: req.user});
                                    // return;
                                }
                            }
                        }
                    );
                } else {
                    req.flash(
                        "warning",
                        "Account already exists, please login."
                    );
                    res.redirect("/");
                }
            }
        }
    );
});

router.post("/addOwner", checkLoggedOut, function(req, res, next) {
    var info = req.session.valid;
    req.session.valid = null;

    pool.query(
        "insert into owners(uid, rid, bid) values ((select U.uid from Users U where U.name=$1), (select R.rid from restaurants R where R.name=$2), (select bid from branches b where b.rid=(select R.rid from restaurants R where R.name=$2)))",
        [info[1], info[0]],
        (err, data) => {
            console.log(req.body.name);
            if (err) {
                console.log(err);
                console.log("error inserting owner");
                failRegister(req, res);
                return;
            }
            req.flash(
                "success",
                "Account and restaurant created. You may log in now."
            );
            res.redirect("/");
        }
    );
});

/* ---- GET for profile ---- */
router.get("/profile", checkLoggedIn, function(req, res, next) {
    var sql_query = "";
    var sup_query = "";
    var rating_query = "";

    if (req.user.iscustomer) {
        sql_query =
            "select * from Users natural join Customers where Users.uid = " +
            "'" +
            req.user.uid +
            "'";

        sup_query =
            "select * from choose C natural join Incentives i where C.uid=$1";

        rating_query =
            "select u.name, count(rt.score), cast(avg(rt.score) as decimal(3,2)) from (ratings rt natural join customers c) inner join users u on c.uid=u.uid where u.uid=$1 group by (u.name)";
    } else {
        sql_query =
            "select * from Users where Users.uid = " + "'" + req.user.uid + "'";

        sup_query =
            "select * from Owners natural join branches natural join restaurants where uid = $1";
    }

    pool.query(sql_query, (err, userData) => {
        if (err) {
            console.log(err);
            return;
        }

        pool.query(sup_query, [req.user.uid], function(err, supportData) {
            if (err) {
                console.log(err);
                return;
            }

            pool.query(rating_query, [req.user.uid], function(err, ratingData) {
                if (err) {
                    console.log(err);
                    return;
                }

                console.log(supportData);
                console.log(ratingData);
                console.log(userData);

                res.render("account/profile", {
                    title: "User Profile",
                    currentUser: req.user,
                    userData: userData.rows,
                    supportData: supportData.rows,
                    ratingData: ratingData.rows
                });
            });
        });
    });
});

router.get("/reservation", checkLoggedIn, function(req, res, next) {
    if (req.user.iscustomer) {
        pool.query(
            "select r.reserveid, Res.name, b.address, t.time from reserves r inner join tables t on r.reserveid=t.reserveid and r.uid=$1 and r.timestamp >= (select current_date) inner join restaurants Res on t.rid=Res.rid inner join branches b on b.rid=Res.rid and t.bid=b.bid order by t.time, Res.name, b.address",
            [req.user.uid],
            function(err, data) {
                if (err) {
                    return;
                }
                console.log(data.rows);

                res.render("account/reservation", {
                    currentUser: req.user,
                    data: data.rows
                });
            }
        );
    } else {
        pool.query(
            "select reserves.reserveid, branches.location, users.name, tables.time, reserves.guestcount from restaurants natural join owners natural join branches natural join tables inner join reserves on tables.reserveid=reserves.reserveid inner join users on reserves.uid=users.uid where owners.uid=$1 and tables.vacant=false order by branches.location;",
            [req.user.uid],
            function(err, data) {
                if (err) {
                    return;
                }
                console.log(data);

                res.render("account/reservation", {
                    title: "Upcoming reservations",
                    currentUser: req.user,
                    data: data.rows
                });
            }
        );
    }
});

router.get("/owner_profile", checkLoggedIn, function(req, res, next) {
    pool.query(
        "select R.name from restaurants R join owners O on R.rid = O.rid where O.uid = $1",
        [req.user.uid],
        function(err, data) {
            if (err) {
                console.log(err);
            }

            res.redirect("/branches?name=" + data.rows[0].name);
        }
    );
});
module.exports = router;
