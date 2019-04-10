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
        res.redirect("/");
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
                        "insert into Users (name, email, password) values ($1, $2, $3)",
                        [name, email, password],
                        function(err, data) {
                            if (err) {
                                console.error(
                                    "Error executing query",
                                    err.stack
                                );
                            } else {
                                var sql_query = "";

                                if (req.body.signupType === "Customer") {
                                    console.log(addr);
                                    sql_query =
                                        "INSERT INTO Customers(uid, address, pNumber, rewardPt) select U.uid, '" +
                                        addr +
                                        "','" +
                                        pNum +
                                        "', 0 " +
                                        "from Users U where U.name=" +
                                        "'" +
                                        name +
                                        "';";
                                } else if (req.body.signupType === "Owner") {
                                    sql_query =
                                        "INSERT INTO Owners(uid, bid) select U.uid,null from Users U where U.name=" +
                                        "'" +
                                        name +
                                        "';";
                                }

                                pool.query(sql_query, (err, data) => {
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
                                });
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

/* ---- GET for profile ---- */
router.get("/profile", checkLoggedIn, function(req, res, next) {
    var sql_query = "";

    console.log(req.user);
    console.log(req.user.iscustomer);

    if (req.user.iscustomer) {
        sql_query =
            "select * from Users natural join Customers natural join Choose where Users.uid = " +
            "'" +
            req.user.uid +
            "'";
    } else {
        sql_query =
            "select * from Users natural join Owners where Users.uid = " +
            "'" +
            req.user.uid +
            "'";
    }

    pool.query(sql_query, (err, dataUser) => {
        if (err) {
            console.log(err);
            return;
        }

        res.render("account/profile", {
            title: "User Profile",
            currentUser: req.user,
            data: dataUser.rows
        });
    });
});

module.exports = router;
