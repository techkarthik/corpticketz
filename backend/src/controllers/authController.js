const { createClient } = require('@libsql/client');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const emailService = require('../services/emailService');

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

exports.register = async (req, res) => {
    const { email } = req.body;
    // Generate OTP cryptographically securely
    const otp = crypto.randomInt(100000, 999999).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString(); // 15 mins

    try {
        // Upsert pending registration
        await db.execute({
            sql: `INSERT INTO pending_registrations (email, otp, expires_at) 
                  VALUES (?, ?, ?) 
                  ON CONFLICT(email) DO UPDATE SET otp=excluded.otp, expires_at=excluded.expires_at`,
            args: [email, otp, expiresAt]
        });

        // Send Email
        await emailService.sendEmail(
            email,
            'Your Verification Code',
            `<p>Your OTP for CorpTicketz registration is: <b>${otp}</b></p>`
        );

        res.json({ message: 'Verification code sent to email.' });
    } catch (e) {
        console.error('Registration error:', e);
        res.status(500).json({ message: e.message });
    }
};

exports.verifyEmail = async (req, res) => {
    const { email, otp } = req.body;
    try {
        const result = await db.execute({
            sql: 'SELECT * FROM pending_registrations WHERE email = ?',
            args: [email]
        });

        if (result.rows.length === 0) return res.status(400).json({ message: 'Request not found.' });

        const pending = result.rows[0];
        if (pending.otp !== otp) return res.status(400).json({ message: 'Invalid OTP.' });
        if (new Date(pending.expires_at) < new Date()) return res.status(400).json({ message: 'OTP Expired.' });

        res.json({ message: 'Email verified.', email: email });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.createOrganization = async (req, res) => {
    const { email, otp, orgName, orgId, password, fullName } = req.body;

    try {
        const pendingRes = await db.execute({
            sql: 'SELECT * FROM pending_registrations WHERE email = ? AND otp = ?',
            args: [email, otp]
        });
        if (pendingRes.rows.length === 0) return res.status(400).json({ message: 'Invalid or expired verification.' });

        // Check if Org ID exists
        const orgRes = await db.execute({
            sql: 'SELECT id FROM organizations WHERE id = ?',
            args: [orgId]
        });
        if (orgRes.rows.length > 0) return res.status(400).json({ message: 'Organization ID is taken.' });

        // Create Org & User Transactionally
        const hashedPassword = await bcrypt.hash(password, 10);

        await db.execute({
            sql: 'INSERT INTO organizations (id, name, super_admin_email) VALUES (?, ?, ?)',
            args: [orgId, orgName, email]
        });

        await db.execute({
            sql: 'INSERT INTO users (organization_id, email, password_hash, full_name, role) VALUES (?, ?, ?, ?, ?)',
            args: [orgId, email, hashedPassword, fullName, 'GlobalAdmin']
        });

        // Cleanup pending
        await db.execute({ sql: 'DELETE FROM pending_registrations WHERE email = ?', args: [email] });

        // Send Welcome Email
        await emailService.sendEmail(
            email,
            'Welcome to CorpTicketz - Your Organization ID',
            `<h1>Welcome to CorpTicketz!</h1><p>Your Organization <b>${orgName}</b> has been created.</p><p>Organization ID: <b>${orgId}</b></p><p>Please keep this ID safe as it is required for login.</p>`
        );

        // Auto Login
        const token = jwt.sign({ id: 1, email, role: 'GlobalAdmin', organization_id: orgId }, process.env.JWT_SECRET, { expiresIn: '8h' });

        res.json({ message: 'Organization created!', token, user: { email, role: 'GlobalAdmin', organization_id: orgId } });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.login = async (req, res) => {
    const { organization_id, email, password } = req.body;
    try {
        const result = await db.execute({
            sql: 'SELECT * FROM users WHERE email = ? AND organization_id = ?',
            args: [email, organization_id]
        });

        if (result.rows.length === 0) {
            return res.status(401).json({ message: 'Invalid credentials or Organization ID' });
        }

        const user = result.rows[0];
        const match = await bcrypt.compare(password, user.password_hash);

        if (!match) return res.status(401).json({ message: 'Invalid credentials' });
        if (!user.is_active) return res.status(403).json({ message: 'Account is inactive' });

        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role, organization_id: user.organization_id },
            process.env.JWT_SECRET,
            { expiresIn: '8h' }
        );

        res.json({ token, user: { ...user, password_hash: undefined } });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.requestPasswordReset = async (req, res) => {
    const { organization_id, email } = req.body;
    try {
        const userRes = await db.execute({
            sql: 'SELECT * FROM users WHERE email = ? AND organization_id = ?',
            args: [email, organization_id]
        });
        if (userRes.rows.length === 0) return res.status(404).json({ message: 'User not found in this Organization.' });

        const otp = crypto.randomInt(100000, 999999).toString();
        const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();

        await db.execute({
            sql: `INSERT INTO otps (email, organization_id, otp, purpose, expires_at) 
                  VALUES (?, ?, ?, 'PASSWORD_RESET', ?)
                  ON CONFLICT(email, organization_id, purpose) DO UPDATE SET otp=excluded.otp, expires_at=excluded.expires_at`,
            args: [email, organization_id, otp, expiresAt]
        });

        await emailService.sendEmail(email, 'Password Reset OTP', `<p>Your OTP to reset password is: <b>${otp}</b></p>`);

        res.json({ message: 'OTP sent to email.' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.resetPassword = async (req, res) => {
    const { organization_id, email, otp, newPassword } = req.body;
    try {
        const otpRes = await db.execute({
            sql: "SELECT * FROM otps WHERE email = ? AND organization_id = ? AND purpose = 'PASSWORD_RESET'",
            args: [email, organization_id]
        });

        if (otpRes.rows.length === 0) return res.status(400).json({ message: 'No OTP request found.' });
        const record = otpRes.rows[0];

        if (record.otp !== otp) return res.status(400).json({ message: 'Invalid OTP' });
        if (new Date(record.expires_at) < new Date()) return res.status(400).json({ message: 'OTP Expired' });

        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await db.execute({
            sql: 'UPDATE users SET password_hash = ? WHERE email = ? AND organization_id = ?',
            args: [hashedPassword, email, organization_id]
        });

        await db.execute({
            sql: "DELETE FROM otps WHERE email = ? AND organization_id = ? AND purpose = 'PASSWORD_RESET'",
            args: [email, organization_id]
        });

        res.json({ message: 'Password updated successfully. Please login.' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.requestOrgIdRecovery = async (req, res) => {
    const { email } = req.body;
    try {
        const otp = crypto.randomInt(100000, 999999).toString();
        const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();

        await db.execute({
            sql: `INSERT INTO otps (email, organization_id, otp, purpose, expires_at) 
                  VALUES (?, 'GLOBAL', ?, 'ORG_ID_RECOVERY', ?)
                  ON CONFLICT(email, organization_id, purpose) DO UPDATE SET otp=excluded.otp, expires_at=excluded.expires_at`,
            args: [email, otp, expiresAt]
        });

        await emailService.sendEmail(email, 'Recover Organization ID', `<p>Your OTP to recover Org IDs is: <b>${otp}</b></p>`);

        res.json({ message: 'OTP sent to email.' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.verifyOrgIdRecovery = async (req, res) => {
    const { email, otp } = req.body;
    try {
        const otpRes = await db.execute({
            sql: "SELECT * FROM otps WHERE email = ? AND organization_id = 'GLOBAL' AND purpose = 'ORG_ID_RECOVERY'",
            args: [email]
        });

        if (otpRes.rows.length === 0) return res.status(400).json({ message: 'No OTP request found.' });
        const record = otpRes.rows[0];

        if (record.otp !== otp) return res.status(400).json({ message: 'Invalid OTP' });
        if (new Date(record.expires_at) < new Date()) return res.status(400).json({ message: 'OTP Expired.' });

        const userRes = await db.execute({
            sql: 'SELECT organization_id, role FROM users WHERE email = ?',
            args: [email]
        });

        const orgs = userRes.rows.map(r => `${r.organization_id} (${r.role})`).join(', ');

        await emailService.sendEmail(email, 'Your Organization IDs', `<p>Here are your associated Organization IDs: </p><p><b>${orgs}</b></p>`);

        await db.execute({
            sql: "DELETE FROM otps WHERE email = ? AND organization_id = 'GLOBAL' AND purpose = 'ORG_ID_RECOVERY'",
            args: [email]
        });

        res.json({ message: 'Verified.', orgs: userRes.rows.map(r => r.organization_id) });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.getMe = async (req, res) => {
    res.json({ user: req.user });
};
