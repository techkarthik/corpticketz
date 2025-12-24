require('dotenv').config();
const { createClient } = require('@libsql/client');

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

async function check() {
    try {
        console.log("--- Tables ---");
        const tables = await db.execute("SELECT name FROM sqlite_master WHERE type='table'");
        console.log(tables.rows.map(r => r.name));

        console.log("\n--- Users Schema ---");
        const users = await db.execute("SELECT sql FROM sqlite_master WHERE name = 'users'");
        if (users.rows.length > 0) console.log(users.rows[0].sql);

        console.log("\n--- Departments Schema ---");
        const depts = await db.execute("SELECT sql FROM sqlite_master WHERE name = 'departments'");
        if (depts.rows.length > 0) console.log(depts.rows[0].sql);
        else console.log("Departments table not found");

    } catch (e) {
        console.error(e);
    }
}
check();
