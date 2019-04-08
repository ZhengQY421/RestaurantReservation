var createError = require("http-errors");
var express = require("express");
var path = require("path");
var cookieParser = require("cookie-parser");
var logger = require("morgan");
var bodyParser = require("body-parser");
var passport = require("passport");
var session = require("express-session");
var flash = require("express-flash");

// Use dotenv package to load custom .env file
require("dotenv").config();

/* Connect to Database */
const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});
\
/* ---- Routers ---- */
var indexRouter = require("./routes/index");
var usersRouter = require("./routes/users");
var restaurantRouter = require("./routes/restaurantRouter");
var accountRouter = require("./routes/accountRouter");

var app = express();

// view engine setup
app.set("views", path.join(__dirname, "views"));
app.set("view engine", "ejs");

app.use(logger("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, "public")));

/* ---- Basically initializes the session ---- */
app.use(
  session({
    secret: process.env.SECRET,
    resave: true,
    saveUninitialized: true
  })
);
app.use(flash());

/*Body Parser */
app.use(bodyParser.urlencoded({ extended: true }));

/*Passport Setup */
app.use(passport.initialize());
app.use(passport.session());

/* ---- Grab the data needed from users ---- */
passport.serializeUser(function(user, cb) {
  cb(null, user.uid);
});

passport.deserializeUser(function(user, cb) {
  pool.query(
    "select uid, name, email, password from Users where uid=$1",
    [user],
    function(err, data) {
      cb(err, data.rows[0]);
    }
  );
});

/* ---- Stuff used to authenticate ---- */
const LocalStrategy = require("passport-local").Strategy;
passport.use(
  "local", new LocalStrategy (function(email, password, done) {
    pool.query(
      "select uid, name, email, password from Users where email=$1 and password = $2",
      [email, password], 
      function(err, data){
        if (err){
          return done(err); 
        } 
        if (data.rowCount === 0){
          console.log(email + " " + password);
          return done(null, false, {message: "Invalid email/password!"}); 
        }
        return done(null, data.rows[0]); 
      });
  })
);

/* ---- Using the Website ---- */
app.use("/", indexRouter);
app.use("/users", usersRouter);
app.use("/restaurant", restaurantRouter);
app.use("/account", accountRouter);

/* ---- Getting the local user ---- */
app.use(function(req,res,next){
  res.locals.currentUser = req.user;
  next();
});

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get("env") === "development" ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render("error");
});

module.exports = app;
