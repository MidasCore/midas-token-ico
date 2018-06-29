/**
 * Created by codevui on 6/29/18.
 */
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const dbPath = path.resolve(__dirname, '../db/tomo.db');
try {
    const db = new sqlite3.Database(dbPath);

    db.run('CREATE TABLE tomo(txId, address, value, block)');
} catch (error) {
    console.log(error)
}