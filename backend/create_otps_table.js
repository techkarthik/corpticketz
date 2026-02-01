require('dotenv').config();
const { createClient } = require('@libsql/client');

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

async function createTable() {
    try {
        console.log('Creating otps table...');
        await db.execute(`
            CREATE TABLE IF NOT EXISTS otps (
                email TEXT NOT NULL,
                organization_id TEXT NOT NULL,
                otp TEXT NOT NULL,
                purpose TEXT NOT NULL,
                expires_at DATETIME NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (email, organization_id, purpose)
            )
        `);
        console.log('otps table created successfully.');
    } catch (e) {
        console.error('Error creating table:', e);
    }
}
createTable();
