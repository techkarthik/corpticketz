const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const { createClient } = require('@libsql/client');
const fs = require('fs');
const bcrypt = require('bcrypt');


const url = process.env.TURSO_DATABASE_URL;
const authToken = process.env.TURSO_AUTH_TOKEN;

if (!url || !authToken) {
    console.error("Missing Turso credentials. Check .env file path.");
    console.error("Attempted to load from:", path.join(__dirname, '../.env'));
    process.exit(1);
}

const db = createClient({
    url,
    authToken,
});

async function run() {
    try {
        console.log("Resetting Database for Multi-Tenancy...");

        // Disable Foreign Keys temporarily to allow drops? LibSQL might not enforce them strictly during DROP but let's see.

        const tables = [
            'attachments', 'ticket_history', 'tickets', 'priorities', 'categories',
            'users', 'working_hours', 'holidays', 'departments', 'branches', 'countries',
            'pending_registrations', 'organizations'
        ];

        for (const table of tables) {
            try {
                await db.execute(`DROP TABLE IF EXISTS ${table}`);
                console.log(`Dropped ${table}`);
            } catch (e) { console.log(`Error dropping ${table}: ${e.message}`); }
        }

        console.log("Reading schema.sql...");
        const schemaPath = path.join(__dirname, '../db/schema.sql');
        const schema = fs.readFileSync(schemaPath, 'utf8');

        console.log("Executing schema...");
        await db.executeMultiple(schema);

        console.log("Schema initialized.");

        // We do NOT seed default admin anymore because registration flow is required.
        // OR we seed one Default Org for testing.

        console.log("Seeding Default Tenant for Testing...");
        const orgId = 'demo';
        const adminEmail = 'natpirkiniyavan@gmail.com';

        await db.execute({
            sql: "INSERT INTO organizations (id, name, super_admin_email) VALUES (?, ?, ?)",
            args: [orgId, 'Demo Corp', adminEmail]
        });

        const hashedPassword = await bcrypt.hash('admin123', 10);
        await db.execute({
            sql: `INSERT INTO users (organization_id, email, password_hash, full_name, role, is_active) 
                  VALUES (?, ?, ?, ?, ?, ?)`,
            args: [orgId, adminEmail, hashedPassword, 'Global Admin', 'GlobalAdmin', 1]
        });

        console.log(`Seeded Org: ${orgId}, User: ${adminEmail}`);

    } catch (e) {
        console.error("Error executing schema:", e);
    }
}

run();
