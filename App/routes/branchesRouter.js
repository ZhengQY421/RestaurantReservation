var express = require("express");
var router = express.Router();

/* Connect to Database */
const { Pool } = require("pg");
const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

const { checkLoggedIn, checkLoggedOut } = require("./middleware/auth");

/* ---- GET for show all details of particular restaurant branches ---- */
router.get("/", function(req, res, next) {
    sql_query =
        "select R.rid, B.bid, coalesce(P.file, 'No photos available!') as file, R.name, R.type, R.description, coalesce(B.pnumber, 'No contact number available!') as pnumber, B.address, B.location FROM Photos P right outer join Restaurants R on P.rid=R.rid inner join Branches B on R.rid=B.rid and R.name=$1";
    pool.query(sql_query, [req.query.name], function(err, branchData) {
        if (err) {
            console.log(err);
        }
        pool.query(
            "select * from response right outer join ratings on response.rtid = ratings.rtid inner join users on users.uid = ratings.uid inner join gives on gives.rtid = ratings.rtid inner join branches on branches.bid = gives.bid and branches.rid = gives.rid where gives.rid = $1",
            [branchData.rows[0].rid],
            function(err, ratingData) {
                if (err) {
                    console.log(err);
                }

                pool.query(
                    "select avg(rt.score) from (restaurants r inner join branches b on r.rid = b.rid inner join gives g on g.bid = b.bid inner join ratings rt on rt.rtid = g.rtid) where r.name = $1",
                    [req.query.name],
                    function(err, avgscore) {
                        sql_query =
                            "select distinct time from Tables T order by time";
                        pool.query(sql_query, function(err, time) {
                            if (err) {
                                return;
                            }
                            sql_query =
                                "select distinct seats from Tables T order by seats";
                            pool.query(sql_query, function(err, seats) {
                                var path = "restaurant/branches";

                                if (req.user && req.user.isowner) {
                                    path = "restaurant/branches_owner";
                                }
                                
                                if(!req.isAuthenticated()) {
                                    req.flash("error", "Please login before making a reservation!")
                                }
                                res.render(path, {
                                    title: req.query.name,
                                    branchData: branchData.rows,
                                    ratingData: ratingData.rows,
                                    currentUser: req.user,
                                    avg: avgscore.rows[0].avg,
                                    time: time.rows,
                                    data: seats.rows
                                });
                            });
                        });
                    });
            });
    });
});

/* ---- GET for show all ratings of particular restaurant branches ---- */
router.get("/ratings", function(req, res, next) {
    pool.query(
        "select * from ratings natural join branches natural join Users natural join response natural join gives where rid=$1",
        [req.query.rid],
        function(err, data) {
            if (err) {
                console.log(err);
            }

            res.render("restaurant/ratings", {
                title: req.query.name,
                data: data.rows,
                currentUser: req.user
            });
        });
});

router.post("/addReview", checkLoggedIn, function(req, res, next) {
    pool.query(
        "insert into ratings (uid, score, review) values ($1, $2, $3)",
        [req.user.uid, req.body.score, req.body.review],
        function(err, data) {
            console.log(
                req.user.uid + " " + req.body.score + " " + req.body.review
            );

            if (err) {
                console.log(err);
            }

            pool.query(
                "insert into gives (timeStamp, uid, rtid, rid, bid) values (" +
                    "(select now()::timestamptz(0))," +
                    " $1, (select R.rtid from Ratings R where R.review=$2), $4, (select B.bid from Branches B where B.location = $3 and B.rid=$4))",
                [req.user.uid, req.body.review, req.body.branch, req.query.rid],
                function(err, data) {
                    console.log(req.body.branch);

                    if (err) {
                        console.log(err);
                        req.flash(
                            "error",
                            "Review couldn't be posted due to an unknown error!"
                        );
                        res.redirect("/branches?name=" + req.query.name);
                        return;
                    }

                    req.flash("success", "Review posted!");
                    res.redirect("/branches?name=" + req.query.name);
                }
            );
        }
    );
});

router.post("/addresponse", checkLoggedIn, function(req, res, next) {
    if (req.user.iscustomer) {
        req.flash("Error", "Sorry, this feature is restaurant owners!");
        res.redirect("/");
    }

    pool.query(
        "INSERT INTO Response (timeStamp, rtid, rid, bid, textResponse) values (" +
            "(select now()::timestamptz(0)), $1, $2, $3, $4)",
        [req.query.rtid, req.query.rid, req.query.bid, req.body.response],
        function(err, data) {
            if (err) {
                console.log(err);
                return;
            }

            req.flash("Success", "You have successfully responded!");
            res.redirect(
                "/branches/ratings?rid=" +
                    req.query.rid +
                    "&name=" +
                    req.query.name
            );
        }
    );
});

module.exports = router;
