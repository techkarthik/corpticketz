const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1]; // Bearer <token>

    if (!token) {
        return res.status(403).json({ message: 'No token provided' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        console.log(`[DEBUG] Token verified for: ${decoded.email}, role: ${decoded.role}, org: ${decoded.organization_id}`);
        req.user = decoded; // { id, email, role, branch_id }
        req.organization_id = decoded.organization_id; // critical for tenant isolation
        next();
    } catch (err) {
        console.error(`[DEBUG] Token verification failed: ${err.message}`);
        return res.status(401).json({ message: 'Unauthorized' });
    }
};

const authorizeRoles = (...roles) => {
    return (req, res, next) => {
        console.log(`[DEBUG] Authorizing roles: ${roles.join(', ')} against user role: ${req.user.role}`);
        if (!roles.includes(req.user.role)) {
            console.error(`[DEBUG] Access denied for role: ${req.user.role}`);
            return res.status(403).json({ message: 'Access denied' });
        }
        next();
    };
};

module.exports = { verifyToken, authorizeRoles };
