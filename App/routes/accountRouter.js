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

function makeid(name) {
    
    var loc = name.indexOf(" "); 
    var first = name.slice(0,loc).toLowerCase();
    var last = name.slice(loc+1).toLowerCase();
    last.replace(" ", "");
    var digit = Math.floor(Math.random() * 11);
    
    return first.slice(0,1)+last+digit+"";
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

                    var name = req.body.signupName;
                    var email = req.body.signupEmail;
                    var password = req.body.signupPassword;
                    var uid = makeid(name);  
                    var addr = req.body.signupAddr;
                    var pNum = req.body.signupPNum;

                    pool.query("INSERT INTO User VALUES" + "('" + uid + "','" + name + "','" + email + "," + password + ")", (err,data) => {
                        if (err) {
                            return console.error('Error executing query', err.stack)
                          }
                        console.log(result.rows[0].name)
                    });
                    
                    var sql_query = ""; 

                    if (req.body.signupType === "Customer"){
                        sql_query = "INSERT INTO Customer VALUES" + "('" + uid + "','" + addr + "','" + pNum + ", 0" +  + ")";

                    }else if (req.body.signupType === "Owner"){
                        sql_query = "INSERT INTO Owners VALUES" + "('" + uid + "','" + addr + "','" + pNum + ", 0" +  + ")";
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

