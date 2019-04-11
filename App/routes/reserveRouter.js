var express = require('express');
var router = express.Router();
var passport = require('passport');
var util = require('util');
/* Connect to Database */
const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

pool.query = util.promisify(pool.query);

const {
    checkLoggedIn,
    checkLoggedOut,
} = require("./middleware/auth");

/* ---- GET/POST for reserve ---- */
router.all('/', checkLoggedIn, async function(req, res, next){
    var sql_query;
    var results;
    if (req.user.iscustomer){
        try{
            sql_query = "select R.rid, B.bid from Restaurants R natural join Branches B where R.name=$1 and B.address=$2";
            results = await pool.query(sql_query, [req.query.name, req.query.address]);
        } catch(err) {
            throw new Error(err)
        }
        if(results){
            var time;
            try{
                sql_query = "select distinct time from Tables T where T.rid=$1 and T.bid=$2 order by time";
                time = await pool.query(sql_query, [results.rows[0].rid, results.rows[0].bid]);
            } catch(err) {
                throw new Error(err)
            }
            
            sql_query = "select distinct seats from Tables T where T.rid=$1 and T.bid=$2 order by seats";
            pool.query(sql_query, [results.rows[0].rid, results.rows[0].bid], function(err, data) {
                if (err){
                    console.log(err);
                    return;
                }
            res.render('restaurant/reservation', {

                title: 'Reservation Selection',
                currentUser: req.user,
                name: req.query.name,
                address: req.query.address,
                time: time.rows,
                data: data.rows
                });
            });
        }
    } else {
        req.flash("error", "Owners are not allowed to make reservations!");
        res.redirect("/");
        return false;
    }
});

router.post('/submit', checkLoggedIn, function(req, res, next){
    var status = 1;
    pool.connect(function(err, client, done) {
        function abort(err) {
            if(err) {
                client.query('ROLLBACK', function(err) {
                    done();
                });
                return true;
            }
            return false;
        }
        client.query('BEGIN', function(err, res1) {
            if(abort(err)) {
                return;
            }
            client.query('select t.tid from restaurants r inner join branches b on r.rid=b.rid inner join tables t on r.rid=t.rid and b.bid=t.bid where r.name=$1 and b.address=$2 and t.time=$3 and t.seats>=$4 and t.vacant=true', [req.query.name, req.query.address, req.body.time, req.body.seats], function(err, res2) {
                if(abort(err)) {
                    return;
                }
                if(!res2.rows.length) {
                    status = 0;
                    var url = "/reservation?name=" + req.query.name +"&address="+ req.query.address;
                    req.flash("error", "The restaurant is fully booked at the chosen timing!");
                    res.redirect(url);
                    return;
                }
                var tid = res2.rows[0].tid;
                client.query('Update tables set vacant=false where tables.tid=$1', [tid], function(err, res3) {
                    if(abort(err)) {
                        return;
                    }
                    client.query('Update customers set rewardpt = rewardpt + 5 where uid=$1', [req.user.uid], function(err, res4) {
                        if(abort(err)) {
                            return;
                        }
                        client.query('COMMIT', function(err, res5) {
                            if(abort(err)) {
                                return;
                            }
                            req.flash("success", "Successfully booked!")
                            res.redirect("/")
                            done();
                        })
                    })
                });
            });
        });
    });
});

module.exports = router;

