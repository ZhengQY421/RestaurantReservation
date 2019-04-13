var express = require("express");
var router = express.Router();
var passport = require("passport");
var util = require("util");
/* Connect to Database */
const { Pool } = require("pg");
const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

const { checkLoggedIn, checkLoggedOut } = require("./middleware/auth");

/* ---- GET/POST for reserve ---- */
router.all("/", checkLoggedIn, function(req, res, next) {
    var sql_query;
    if (req.user.iscustomer) {
        sql_query = "select distinct time from Tables T order by time";
        pool.query(sql_query, function(err, time) {
            if (err) {
                return;
            }
            sql_query = "select distinct seats from Tables T order by seats";
            pool.query(sql_query, function(err, seats) {
                if (err) {
                    console.log(err);
                    return;
                }
                console.log(req.body);
                res.render("restaurant/reservation", {
                    title: "Reservation Selection",
                    currentUser: req.user,
                    req: req.body,
                    time: time.rows,
                    data: seats.rows
                });
            });
        });
    } else {
        req.flash("error", "Owners are not allowed to make reservations!");
        res.redirect("/");
        return false;
    }
});

router.post("/submit", checkLoggedIn, function(req, res, next) {
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
        function redirect(user, body) {
            client.query("ROLLBACK", function(err) {
                sql_query = "select distinct time from Tables T order by time";
                client.query(sql_query, function(err, time) {
                    if (err) {
                        return;
                    }
                    sql_query =
                        "select distinct seats from Tables T order by seats";
                    client.query(sql_query, function(err, seats) {
                        if (err) {
                            console.log(err);
                            return;
                        }
                        console.log(req.body);
                        req.flash(
                            "error",
                            "The restaurant is fully booked at the chosen timing!"
                        );
                        res.render("restaurant/reservation", {
                            title: "Reservation Selection",
                            currentUser: user,
                            req: body,
                            time: time.rows,
                            data: seats.rows
                        });
                    });
                });
            });
        }
        client.query("BEGIN", function(err, res1) {
            if (abort(err)) {
                return;
            }

            client.query(
                "select r. rid, b.bid, b.address from  restaurants R natural join branches b  where r.name = $1 and b.location = $2",
                [req.body.name, req.body.reserveBranch],
                function(err, resn) {
                    if (abort(err)) {
                        return;
                    }
                    client.query(
                        "select t.tid from restaurants r inner join branches b on r.rid=b.rid inner join tables t on r.rid=t.rid and b.bid=t.bid where r.name=$1 and b.address=$2 and t.time=$3 and t.seats>=$4 and t.vacant=true",
                        [
                            req.body.name,
                            resn.rows[0].address,
                            req.body.time,
                            req.body.seats
                        ],
                        function(err, res2) {
                            if (abort(err)) {
                                return;
                            }
                            if (!res2.rows.length) {
                                res.redirect("/branches?name=" + req.body.name);
                                return;
                            }
                            client.query(
                                "select now()::timestamptz(0)",
                                function(err, res3) {
                                    if (abort(err)) {
                                        return;
                                    }
                                    var time = res3.rows[0].now;
                                    client.query(
                                        "Insert into reserves(uid, timestamp, guestcount) values ($1, $2, $3)",
                                        [req.user.uid, time, req.body.seats],
                                        function(err, res4) {
                                            if (abort(err)) {
                                                return;
                                            }
                                            client.query(
                                                "select reserveId from reserves r where r.timestamp=$1 and r.uid=$2",
                                                [time, req.user.uid],
                                                function(err, res5) {
                                                    if (abort(err)) {
                                                        return;
                                                    }
                                                    var reserveId =
                                                        res5.rows[0].reserveid;
                                                    console.log(reserveId);
                                                    var tid = res2.rows[0].tid;
                                                    client.query(
                                                        "Update tables set vacant=false, reserveId=$1 where tables.tid=$2",
                                                        [reserveId, tid],
                                                        function(err, res6) {
                                                            if (abort(err)) {
                                                                return;
                                                            }
                                                            client.query(
                                                                "COMMIT",
                                                                function(
                                                                    err,
                                                                    res5
                                                                ) {
                                                                    if (
                                                                        abort(
                                                                            err
                                                                        )
                                                                    ) {
                                                                        return;
                                                                    }
                                                                    req.flash(
                                                                        "success",
                                                                        "Successfully booked!"
                                                                    );
                                                                    res.redirect(
                                                                        "/"
                                                                    );
                                                                    done();
                                                                }
                                                            );
                                                        }
                                                    );
                                                }
                                            );
                                        }
                                    );
                                }
                            );
                        }
                    );
                }
            );
        });
    });
});

router.post("/perform", checkLoggedIn, function(req, res, next) {
    if(req.body.submit=='cancel') {
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
                    "Update tables set vacant=true, reserveid=null where reserveid=$1",
                    [req.body.reserveid],
                    function(err, res2) {
                        if (abort(err)) {
                            return;
                        }
                        client.query(
                            "delete from reserves where reserveid=$1",
                            [req.body.reserveid],
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
                                        "Reservation has been cancelled!"
                                    );
                                    res.redirect("/account/reservation");
                                    done();
                                });
                            }
                        );
                    }
                );
            });
        });
    } else {
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
                client.query("select r.uid from reserves r where r.reserveid=$1", [req.body.reserveid], function(err, data) {
                    if(abort(err)) {
                        return;
                    }
                    var uid = data.rows[0].uid
                    client.query(
                        "Update tables set vacant=true, reserveid=null where reserveid=$1",
                        [req.body.reserveid],
                        function(err, res2) {
                            if (abort(err)) {
                                return;
                            }
                            client.query(
                                "delete from reserves where reserveid=$1",
                                [req.body.reserveid],
                                function(err, res3) {
                                    if (abort(err)) {
                                        return;
                                    }
                                    client.query("update customers set rewardpt = rewardpt + 10 where uid=$1", [uid], function(err, res4) {
                                        if(abort(err)) {
                                            return;
                                        }
                                        client.query("COMMIT", function(err, res4) {
                                            if (abort(err)) {
                                                return;
                                            }
                                            req.flash(
                                                "success",
                                                "Woohoo we are making money today!"
                                            );
                                            res.redirect("/account/reservation");
                                            done();
                                        });
                                    });
                                }
                            );
                        }
                    );
                });
                
            });
        });
    }
    
});
module.exports = router;
