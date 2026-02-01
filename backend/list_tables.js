require('dotenv').config();
const { createClient } = require('@libsql/client');

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

async function checkTables() {
    try {
        const result = await db.execute("SELECT name FROM sqlite_master WHERE type='table'");
        console.log('Tables:', result.rows.map(r => r.name));
    } catch (e) {
        console.error(e);
    }
}
checkTables();
