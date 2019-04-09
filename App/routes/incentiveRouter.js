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
router.get('/', function(req, res, next) {
    pool.query('SELECT * FROM Discounts', (err, data) => {
        console.log(err)
        res.render('incentive/incentive', {
            title: 'Discounts',
            data: data.rows,
            currentUser: req.user});
    });
});

/* ---- GET for show prizes ---- */
router.get('/', function(req, res, next) {
    pool.query('SELECT * FROM Prizes', (err, data) => {
        console.log(err)
        res.render('incentive/incentive', {
            title: 'Prizes',
            data: data.rows,
            currentUser: req.user});
    });
});

module.exports = router;
