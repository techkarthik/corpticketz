const { createClient } = require('@libsql/client');
require('dotenv').config({ path: '../.env' }); // Adjust path if running from scripts dir

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

async function migrate() {
    try {
        console.log("Adding columns to branches table...");

        try {
            await db.execute("ALTER TABLE branches ADD COLUMN contact_person TEXT");
            console.log("Added contact_person");
        } catch (e) {
            console.log("contact_person might already exist:", e.message);
        }

        try {
            await db.execute("ALTER TABLE branches ADD COLUMN contact_number TEXT");
            console.log("Added contact_number");
        } catch (e) {
            console.log("contact_number might already exist:", e.message);
        }

        try {
            await db.execute("ALTER TABLE branches ADD COLUMN contact_email TEXT");
            console.log("Added contact_email");
        } catch (e) {
            console.log("contact_email might already exist:", e.message);
        }

        console.log("Migration complete.");
    } catch (e) {
        console.error("Migration failed:", e);
    }
}

migrate();
