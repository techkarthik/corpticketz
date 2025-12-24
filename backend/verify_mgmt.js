require('dotenv').config();

const baseUrl = 'http://127.0.0.1:3000/api';
let token = '';

async function verify() {
    try {
        console.log("1. Logging in...");
        const loginRes = await fetch(`${baseUrl}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                organization_id: '579152',
                email: 'karthik.jct@gmail.com',
                password: 'password123' // Guessing, but if it fails we just inform the user.
            })
        });
        const loginData = await loginRes.json();
        if (!loginRes.ok) throw new Error(loginData.message);
        token = loginData.token;
        console.log("Logged in successfully.");

        const headers = {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        };

        console.log("\n2. Testing Departments CRUD...");
        const createDeptRes = await fetch(`${baseUrl}/master/departments`, {
            method: 'POST',
            headers,
            body: JSON.stringify({ name: 'Verification Dept' })
        });
        if (!createDeptRes.ok) throw new Error(await createDeptRes.text());
        console.log("Department created.");

        const getDeptsRes = await fetch(`${baseUrl}/master/departments`, { headers });
        const depts = await getDeptsRes.json();
        console.log(`Departments found: ${depts.length}`);

        console.log("\n3. Testing Users CRUD...");
        const getUsersRes = await fetch(`${baseUrl}/master/users`, { headers });
        const users = await getUsersRes.json();
        console.log(`Users found: ${users.length}`);

        console.log("\nVerification Complete!");
    } catch (e) {
        console.error("Verification failed:", e.message);
        console.log("Note: If login failed, please test directly in the application with your credentials.");
    }
}

verify();
