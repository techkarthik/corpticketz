// using native fetch

// If node-fetch is not installed, use native fetch (available in Node 21, maybe 18 experimental)
// Or just use http.
// Getting 'require' for fetch is safer if I install it. Or just rely on modern node.
// Node v22 has native fetch.

const BASE_URL = 'http://localhost:3000/api';

async function run() {
    try {
        console.log("1. Logging in...");
        const loginRes = await fetch(`${BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                organization_id: 'demo',
                email: 'natpirkiniyavan@gmail.com',
                password: 'admin123'
            })
        });

        if (!loginRes.ok) {
            console.error("Login failed:", await loginRes.text());
            return;
        }

        const authData = await loginRes.json();
        const token = authData.token;
        console.log("Login successful. Token acquired.");

        console.log("2. Creating Country...");
        const countryRes = await fetch(`${BASE_URL}/master/countries`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ name: 'India', code: 'IN', currency: 'INR', timezone: 'Asia/Kolkata' })
        });

        if (countryRes.ok) {
            console.log("Country created.");
        } else {
            console.log("Country creation failed (maybe exists):", await countryRes.text());
        }

        console.log("3. Fetching Countries...");
        const countriesRes = await fetch(`${BASE_URL}/master/countries`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const countries = await countriesRes.json();
        console.log("Countries:", countries);

        if (countries.length > 0) {
            console.log("4. Creating Branch...");
            const india = countries.find(c => c.code === 'IN');
            if (india) {
                const branchRes = await fetch(`${BASE_URL}/master/branches`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
                    body: JSON.stringify({ country_id: india.id, name: 'India HQ', address: 'Bangalore', contact_info: 'contact@in.corp' })
                });
                console.log("Branch creation status:", branchRes.status);
            }
        }

        console.log("Done.");

    } catch (e) {
        console.error("Error:", e);
    }
}

run();
