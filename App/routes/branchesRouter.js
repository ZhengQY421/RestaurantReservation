var express = require('express');
var router = express.Router();

/* Connect to Database */
const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

/* ---- GET for show all details of particular restaurant branches ---- */
router.get('/', function(req, res, next) {
	sql_query = "select R.name, coalesce(B.pnumber, 'No contact number available!') as pnumber, B.address, B.location FROM Restaurants R inner join Branches B on R.rid=B.rid and R.name= '" + req.query.name +"'";
	pool.query(sql_query, function(err, data) {
		if(err) {
			console.log(err);
		};
		res.render('restaurant/branches', { 
			title: req.query.name, 
			data: data.rows,
			currentUser: req.user});
	});
});

module.exports = router;