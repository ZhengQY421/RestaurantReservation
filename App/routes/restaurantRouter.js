var express = require("express");
var router = express.Router();

/* Connect to Database */
const { Pool } = require("pg");
const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

function failRegister(req, res) {
    req.flash("error", "Sorry, an error has occurred. Please try again later.");
    res.redirect("/");
}

function insertBranch(req, res) {
    pool.query(
        "insert into branches(rid, bid, pnumber, address, location) values ((select R.rid from restaurants R where R.name=$1)," +
            "(select count(*)+1 from branches b where b.rid=(select R.rid from restaurants R where R.name=$1)), $2, $3, $4)",
        [req.body.resName, req.body.resPnum, req.body.resAddr, req.body.resLoc],
        function(err, data) {
            if (err) {
                console.log(err);
                console.log;
                console.log("Error inserting branch");
            }

            var info = [req.body.resName];
            info.push(req.session.valid);
            req.session.valid = info;
            console.log(info);

            res.redirect(307, "/account/addOwner");
            return;
        }
    );
}

/* ---- GET for show all restaurants ---- */
router.get("/", function(req, res, next) {
    pool.query("SELECT * FROM Restaurants", (err, data) => {
        console.log(err);
        res.render("restaurant/restaurant", {
            title: "All Restaurants",
            data: data.rows,
            currentUser: req.user
        });
    });
});

/* ---- Get for search restaurants ---- */
router.get("/search", function(req, res, next) {
    pool.query(
        "SELECT * FROM Restaurants where Restaurants.name ~* $1",
        [req.query.searchRes],
        (err, data) => {
            console.log(err);
            console.log(req.query);
            res.render("restaurant/search", {
                title: "Search Restaurants",
                data: data.rows,
                currentUser: req.user
            });
        }
    );
});

/* ---- Get for adding restaurant ---- */
router.get("/add", function(req, res, next) {
    res.render("restaurant/add", {
        title: "Add Restaurant",
        currentUser: req.user
    });
});

/* ---- Post for getting restaurant ---- */
router.post("/add", function(req, res, next) {
    pool.query(
        "select R.rid from restaurants R where R.name=$1",
        [req.body.resName],
        function(err, data) {
            if (err) {
                console.log(err);
            }

            if (data.rowCount == 0) {
                pool.query(
                    "Insert into Restaurants(name, type, description) values ($1, $2, $3)",
                    [req.body.resName, req.body.resType, req.body.cusType],
                    function(err, data) {
                        insertBranch(req, res);
                    }
                );
            } else {
                insertBranch(req, res);
            }
        }
    );
});

module.exports = router;
