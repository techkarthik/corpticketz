require('dotenv').config();
const { createClient } = require('@libsql/client');

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

async function check() {
    try {
        console.log('Checking pending_registrations table...');
        const result = await db.execute('SELECT * FROM pending_registrations');
        console.log('Count:', result.rows.length);
        console.log('Rows:', result.rows);
    } catch (e) {
        console.error('Error:', e);
    }
}
check();
