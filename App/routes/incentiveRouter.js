var express = require('express');
var router = express.Router();

/* Connect to Database */
const { Pool } = require('pg');
const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

const { checkLoggedIn, checkLoggedOut } = require("./middleware/auth");


/* ---- GET for show all incentives (prizes AND discounts) ---- */
router.get('/', checkLoggedIn, function(req, res, next) {
    pool.query('SELECT * FROM Incentives', (err, data) => {
        console.log(err)
        res.render('incentive/incentive', {
            title: 'All Rewards',
            data: data.rows,
            currentUser: req.user});
    });
});

/* ---- GET for show discounts ---- */
router.get('/discount', checkLoggedIn, function(req, res, next) {
    pool.query('SELECT * FROM Discounts natural join Incentives', (err, data) => {
        console.log(err)
        res.render('incentive/discount', {
            title: 'Discounts',
            data: data.rows,
            currentUser: req.user});
    });
});

/* ---- GET for show prizes ---- */
router.get('/prize', checkLoggedIn, function(req, res, next) {
    pool.query('SELECT * FROM Prizes natural join Incentives', (err, data) => {
        console.log(err)
        res.render('incentive/prize', {
            title: 'Prizes',
            data: data.rows,
            currentUser: req.user});
    });
});


router.post('/redeem', checkLoggedIn, function(req, res, next) {

    pool.query('SELECT I.incentiveName FROM incentives I where I.iid = $1',
        [req.body.iid],
        function(err, data) {
            if (err) {
                console.log(err);
            }

            var incentiveName = data.rows[0].incentivename;

        //returns the rows that are inserted
        pool.query('INSERT INTO Choose (timeStamp, uid, iid) VALUES ((select now()::timestamptz(0)), ($1), ($2)) RETURNING *',
            [req.user.uid, req.body.iid], (err, data) => {

                if (err) {
                    console.log(err);
                }

                // insert returns 0 rows if not enough points bc of trigger on insert into choose in proj_init.sql
                if (data.rowCount == 0) {
                    req.flash("error", "Sorry, you don't have enough points for " + incentiveName + ".");
                    res.redirect("/incentive");
                }

                else {
                    req.flash("success", "You have redeemed " + incentiveName + ".");
                    res.redirect("/incentive");
                }
        });
    });
});


module.exports = router;
