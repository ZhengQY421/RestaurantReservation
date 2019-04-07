var express = require('express');
var router = express.Router();

/* Connect to Database */
const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

/* ---- GET for show all restaurants ---- */
router.get('/', function(req, res, next) {
	pool.query('SELECT * FROM Restaurants', (err, data) => {
        console.log(err)
		res.render('restaurant/restaurant', { title: 'Restaurants', data: data.rows});
	});
});

/* ---- Get for search restaurants ---- */
router.get('/search', function(req,res,next) {
	pool.query('SELECT * FROM Restaurants where Restaurants.name = $1', [req.query.searchRes],(err, data) => {
		console.log(err)
		console.log(req.query)
		res.render('restaurant/search', {title: 'Search Restaurants', data: data.rows});
	});
  }); 

module.exports = router;