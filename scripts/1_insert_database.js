/**
 * Created by codevui on 6/29/18.
 */
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const dbPath = path.resolve(__dirname, '../db/tomo.db');
try {
    const db = new sqlite3.Database(dbPath);

    // insert one row into the langs table
    db.run(`INSERT INTO tomo(txId, address, value, block) VALUES(?, ?, ?, ?)`, ['C', 'D', 1000, 2000], function(err) {
	if (err) {
	    return console.log(err.message);
	}
	// get the last insert id
	console.log(`A row has been inserted with rowid ${this.lastID}`);
    });

    db.close();
} catch (error) {
    console.log(error);
}