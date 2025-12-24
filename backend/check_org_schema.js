require('dotenv').config();
const { createClient } = require('@libsql/client');

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

async function check() {
    try {
        const result = await db.execute("SELECT sql FROM sqlite_master WHERE name = 'organizations'");
        console.log(result.rows[0].sql);
    } catch (e) {
        console.error(e);
    }
}
check();
