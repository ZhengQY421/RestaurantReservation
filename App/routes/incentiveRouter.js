var express = require('express');
var router = express.Router();

/* Connect to Database */
const { Pool } = require('pg');
const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

/* ---- GET for show all incentives (prizes AND discounts) ---- */
router.get('/', function(req, res, next) {
    pool.query('SELECT * FROM Incentives', (err, data) => {
        console.log(err)
        res.render('incentive/incentive', {
            title: 'All Rewards',
            data: data.rows,
            currentUser: req.user});
    });
});

/* ---- GET for show discounts ---- */
router.get('/discount', function(req, res, next) {
    pool.query('SELECT * FROM Discounts natural join Incentives', (err, data) => {
        console.log(err)
        res.render('incentive/discount', {
            title: 'Discounts',
            data: data.rows,
            currentUser: req.user});
    });
});

/* ---- GET for show prizes ---- */
router.get('/prize', function(req, res, next) {
    pool.query('SELECT * FROM Prizes natural join Incentives', (err, data) => {
        console.log(err)
        res.render('incentive/prize', {
            title: 'Prizes',
            data: data.rows,
            currentUser: req.user});
    });
});


module.exports = router;
