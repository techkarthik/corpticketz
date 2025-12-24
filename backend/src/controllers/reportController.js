const { createClient } = require('@libsql/client');

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

exports.getReportSummary = async (req, res) => {
    const { branch_id, department_id, category_id, requester_id, status, startDate, endDate } = req.query;
    const organization_id = req.organization_id;

    try {
        let whereClauses = ['t.organization_id = ?'];
        let args = [organization_id];

        if (branch_id) {
            whereClauses.push('t.branch_id = ?');
            args.push(branch_id);
        }
        if (department_id) {
            whereClauses.push('t.department_id = ?');
            args.push(department_id);
        }
        if (category_id) {
            whereClauses.push('t.category_id = ?');
            args.push(category_id);
        }
        if (requester_id) {
            whereClauses.push('t.requester_id = ?');
            args.push(requester_id);
        }
        if (status) {
            whereClauses.push('t.status = ?');
            args.push(status);
        }
        if (startDate) {
            whereClauses.push('t.created_at >= ?');
            args.push(startDate);
        }
        if (endDate) {
            whereClauses.push('t.created_at <= ?');
            args.push(endDate);
        }

        const whereSql = whereClauses.join(' AND ');

        // 1. Total counts by status
        const statusSummary = await db.execute({
            sql: `SELECT status, COUNT(*) as count FROM tickets t WHERE ${whereSql} GROUP BY status`,
            args
        });

        // 2. Counts by category
        const categorySummary = await db.execute({
            sql: `SELECT c.name as category_name, COUNT(*) as count 
                  FROM tickets t 
                  JOIN categories c ON t.category_id = c.id 
                  WHERE ${whereSql} GROUP BY t.category_id`,
            args
        });

        // 3. Counts by branch
        const branchSummary = await db.execute({
            sql: `SELECT b.name as branch_name, COUNT(*) as count 
                  FROM tickets t 
                  JOIN branches b ON t.branch_id = b.id 
                  WHERE ${whereSql} GROUP BY t.branch_id`,
            args
        });

        // 4. Counts by department
        const departmentSummary = await db.execute({
            sql: `SELECT d.name as department_name, COUNT(*) as count 
                  FROM tickets t 
                  JOIN departments d ON t.department_id = d.id 
                  WHERE ${whereSql} GROUP BY t.department_id`,
            args
        });

        // 5. Overall stats
        const overallStats = await db.execute({
            sql: `SELECT 
                    COUNT(*) as total_tickets,
                    SUM(CASE WHEN status IN ('Resolved', 'Closed') THEN 1 ELSE 0 END) as resolved_tickets,
                    SUM(CASE WHEN status NOT IN ('Resolved', 'Closed') THEN 1 ELSE 0 END) as open_tickets
                  FROM tickets t 
                  WHERE ${whereSql}`,
            args
        });

        res.json({
            statusSummary: statusSummary.rows,
            categorySummary: categorySummary.rows,
            branchSummary: branchSummary.rows,
            departmentSummary: departmentSummary.rows,
            overallStats: overallStats.rows[0]
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
};
