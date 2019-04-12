var express = require("express");
var router = express.Router();

/* Connect to Database */
const { Pool } = require("pg");
const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

/* ---- GET for show all details of particular restaurant branches ---- */
router.get("/", function(req, res, next) {
    sql_query =
        "select R.rid, B.bid, P.file, R.name, R.type, R.description, coalesce(B.pnumber, 'No contact number available!') as pnumber, B.address, B.location FROM Photos P natural join Restaurants R inner join Branches B on R.rid=B.rid and R.name=$1";
    pool.query(sql_query, [req.query.name], function(err, branchData) {
        if (err) {
            console.log(err);
        }
        console.log(branchData)
        pool.query(
            "select * from gives G natural join ratings RT natural join response R natural join Users U natural join branches where G.rid = $1",
            [branchData.rows[0].rid],
            function(err, ratingData) {
                if (err) {
                    console.log(err);
                }

                res.render("restaurant/branches", {
                    title: req.query.name,
                    branchData: branchData.rows,
                    ratingData: ratingData.rows,
                    currentUser: req.user
                });
            }
        );
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
        }
    );
});

router.post("/addReview", function(req, res, next) {
    pool.query(
        "insert into ratings values ($1, $2, $3)",
        [req.user.uid, req.body.score, req.body.review],
        function(err, data) {
            console.log(
                req.user.uid + " " + req.body.score + " " + req.body.review
            );

            if (err) {
                console.log(err);
            }

            timeStamp, uid, rtid, rid, bid;

            pool.query(
                "insert into gives values" +
                    "(select now()::timestamptz(0)," +
                    " $1, (select R.rtid from Ratings R where R.review=$2),"
            );
        }
    );
});

module.exports = router;
