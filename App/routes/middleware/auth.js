function nullFunction () {}

//Check if a user is currently logged in
function checkLoggedIn(req, res, next){
    if (req.isAuthenticated()) {
        return next();
    }
    req.flash("warning", "You must first log in before cotinuing!");
    res.redirect("/");
    return false; 
}

//Check if a user is already logged in
function checkLoggedOut(req, res, next) {
    if (!req.isAuthenticated()) {
      return next();
    }
    req.flash("info", "You are already logged in!");
    res.redirect("/");
    return false;
}

module.exports.checkLoggedIn = checkLoggedIn;
module.exports.checkLoggedOut = checkLoggedOut;
  