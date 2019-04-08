var express = require('express');
var router = express.Router();

/* Connect to Database */
const { Pool } = require('pg');
const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

/* ---- GET for show all incentives ?? ---- */
router.get('/', function(req, res, next) {
    pool.query('SELECT * FROM Incentives', (err, data) => {
        console.log(err)
        res.render('reward/reward', {
            title: 'All Rewards',
            data: data.rows,
            currentUser: req.user});
    });
});

module.exports = router;
