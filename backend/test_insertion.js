require('dotenv').config();
const { createClient } = require('@libsql/client');

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

async function test() {
    try {
        // Need a valid organization_id
        console.log("Fetching an organization...");
        const orgRes = await db.execute("SELECT id FROM organizations LIMIT 1");
        if (orgRes.rows.length === 0) {
            console.error("No organizations found to link country to.");
            return;
        }
        const orgId = orgRes.rows[0].id;
        console.log(`Using Org ID: ${orgId}`);

        const result = await db.execute({
            sql: "INSERT INTO countries (organization_id, name, code, currency, timezone) VALUES (?, ?, ?, ?, ?)",
            args: [orgId, 'Test Country', 'TC', '', '']
        });
        console.log("Success:", result);
    } catch (e) {
        console.error("Error during insertion:", e);
    }
}
test();
