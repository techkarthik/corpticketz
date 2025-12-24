const { createClient } = require('@libsql/client');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

async function run() {
    try {
        const res = await db.execute("SELECT * FROM users");
        console.log("Users:", res.rows);
        const orgs = await db.execute("SELECT * FROM organizations");
        console.log("Orgs:", orgs.rows);
    } catch (e) {
        console.error(e);
    }
}
run();
