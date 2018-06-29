/**
 * Created by codevui on 6/29/18.
 */
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const dbPath = path.resolve(__dirname, '../db/tomo.db');
const db = new sqlite3.Database(dbPath);
try {
    // insert one row into the langs table
    db.all(`SELECT * FROM tomo`, [], function(err, data) {
	if (err) {
	    return console.log(err.message);
	}
	// get the last insert id
	console.log(data);
    });


    db.close();
} catch (error) {
    console.log(error);
}