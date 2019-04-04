var express = require('express');
var router = express.Router();

/* Connect to Database */
const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

/* SQL Query */
var sql_query = 'SELECT * FROM Restaurants';

router.get('/', function(req, res, next) {
    console.log(process.env.DATABASE_URL);
	pool.query(sql_query, (err, data) => {
        console.log(err)
		res.render('restaurant', { title: 'Restaurants', data: data.rows});
	});
});

module.exports = router;