var express = require('express');
var router = express.Router();

/* Connect to Database */
const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});


router.get('/', function(req, res, next) {
	pool.query('SELECT * FROM Restaurants', (err, data) => {
        console.log(err)
		res.render('restaurant/restaurant', { title: 'Restaurants', data: data.rows});
	});
});

module.exports = router;