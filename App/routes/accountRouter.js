var express = require('express');
var router = express.Router();
var passport = require('passport');

const {
    checkLoggedIn,
    checkLoggedOut,
} = require("./middleware/auth");

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

module.exports = router;

