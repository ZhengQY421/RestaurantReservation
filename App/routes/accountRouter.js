var express = require('express');
var router = express.Router();
var passport = require('passport');

/* Connect to Database */
const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

const {
    checkLoggedIn,
    checkLoggedOut,
} = require("./middleware/auth");

function failRegister(req, res) {
    req.flash("error", "Sorry, an error has occurred. Please try again later.");
    res.redirect("/");
}

/* ---- Post Function for Login ---- */
router.all('/login', checkLoggedOut,
passport.authenticate("local", {
    failureRedirect: "/",
    failureFlash: true
  }),
function(req,res,next){
    req.flash("success", "You have logged in!");
    res.redirect("/");

});

/* ---- Get/Post Function for Log Out ---- */
router.all('/logout', checkLoggedIn, function(req,res,next){
    req.logout();
    req.flash("success", "You have been logged out!");
    res.redirect("/");
})

/* ---- Post Function for Sign up ---- */
router.post('/signup', checkLoggedOut, function(req, res, next){

    pool.query(
        "select 1 from accounts where email=$1;",[req.body.signupEmail],
        function(err,data){
            if(err){
                failRegister(req, res);
            } else{

                if (data.rowCount === 0){
                    var sql_query = ""; 

                    if (req.body.signupType === "Customer"){
                        sql_query = "INSERT INTO Customer VALUES";

                    }else if (req.body.signupType === "Owner"){

                    }

                }else {
                    req.flash("warning", "Account already exists, please login.")
                    res.redirect("/")
                }
            }

        }
    )
})

module.exports = router;

