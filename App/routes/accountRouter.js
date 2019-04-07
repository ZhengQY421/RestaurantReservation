var express = require('express');
var router = express.Router();

/* ---- Get Function for Login ---- */
router.get('/login', function(req,res,next){
    res.render('account/login', {title: 'Login'});
});

/* ---- Post Function for Sign up ---- */

module.exports = router;

