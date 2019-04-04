var createError = require("http-errors");
var express = require("express");
var path = require("path");
var cookieParser = require("cookie-parser");
var logger = require("morgan");
var passport = require("passport");
var session = require("session");
var bodyParser = require("body-parser");

require("dotenv").config();

/* ---- Routers ---- */
var indexRouter = require("./routes/index");
var usersRouter = require("./routes/users");
var restaurantRouter = require("./routes/restaurant");

var app = express();

// view engine setup
app.set("views", path.join(__dirname, "views"));
app.set("view engine", "ejs");

app.use(logger("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, "public")));

/* ---- Using the Website ---- */
app.use("/", indexRouter);
app.use("/users", usersRouter);
app.use("/restaurant", restaurantRouter);

/*
app.use(
  session({
    secret: process.env.SECRET,
    resave: true,
    saveUninitialized: true
  })
);
*/

/*Body Parser */
app.use(bodyParser.urlencoded({ extended: true }));

/*Passport Setup */
app.use(passport.initialize());
app.use(passport.session());

/*Modify with proper id*/
passport.serializeUser(function(user, cb) {
  cb(null, user.id);
});

passport.deserializeUser(function(user, cb) {
  pool.query(
    "select id, email, firstName, lastName, isUser, isWorker, isAdmin from accounts natural join accountTypes where id=$1",
    [user],
    function(err, data) {
      cb(err, data.rows[0]);
    }
  );
});

/*
1. Query the database for a matching account
2. Send success authetication if so, and don't 

Friend's example:
const LocalStrategy = require("passport-local").Strategy;
passport.use(
  "local",
  new LocalStrategy(function(email, password, done) {
    pool.query("select salt from accounts where email=$1", [email], function(
      err,
      data
    ) {
      if (err) return done(err);
      if (data.rowCount === 0)
        return done(null, false, {
          message: "You entered an incorrect email or password!"
        });
      pool.query(
        "select id, email, firstName, lastName, isUser, isWorker, isAdmin from accounts natural join accountTypes where email=$1 and hash=$2",
        [email, getPasswordHash(data.rows[0].salt, password)],
        function(err, data) {
          if (err) return done(err);
          if (data.rowCount === 0)
            return done(null, false, {
              message: "You entered an incorrect email or password!"
            });
          return done(null, data.rows[0]);
        }
      );
    });
  })
);
*/

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
