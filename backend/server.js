require('dotenv').config();
const express = require('express');
const { createClient } = require('@libsql/client');
const cors = require('cors');

const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();

// Security Middleware
app.use(helmet());
app.use(express.json());

// General Rate Limiting
const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again after 15 minutes'
});
app.use('/api/', generalLimiter);

// Stricter Rate Limiting for Auth
const authLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 10, // limit each IP to 10 requests per hour for auth routes
    message: 'Too many auth attempts, please try again after an hour'
});

app.use(cors());

// Request logging middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});

const url = process.env.TURSO_DATABASE_URL;
const authToken = process.env.TURSO_AUTH_TOKEN;

const authRoutes = require('./src/routes/authRoutes');
const masterDataRoutes = require('./src/routes/masterDataRoutes');

console.log(`Connecting to Turso: ${url}`);

const db = createClient({
    url,
    authToken,
});

app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/master', masterDataRoutes);
app.use('/api/tickets', require('./src/routes/ticketRoutes'));
app.use('/api/reports', require('./src/routes/reportRoutes'));

app.get('/', (req, res) => {
    res.send('Ticketing System API is running');
});

app.get('/test-db', async (req, res) => {
    try {
        const result = await db.execute('SELECT 1 as val');
        res.json({ success: true, validation: result.rows[0] });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: error.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
