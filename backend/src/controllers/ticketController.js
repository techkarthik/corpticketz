const { createClient } = require('@libsql/client');
const emailService = require('../services/emailService');

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

exports.createTicket = async (req, res) => {
    const { subject, description, category_id, priority_id, branch_id, department_id, assigned_to } = req.body;
    const requester_id = req.user.id;

    try {
        // Calculate due_date (Simple version: now + 24h)
        const dueDate = new Date();
        dueDate.setHours(dueDate.getHours() + 24);

        const result = await db.execute({
            sql: `INSERT INTO tickets (organization_id, subject, description, requester_id, status, priority_id, category_id, branch_id, department_id, assigned_to, due_date) 
                  VALUES (?, ?, ?, ?, 'New', ?, ?, ?, ?, ?, ?) RETURNING id`,
            args: [
                req.organization_id,
                subject,
                description,
                requester_id,
                priority_id,
                category_id,
                branch_id,
                department_id,
                assigned_to,
                dueDate.toISOString()
            ]
        });

        const ticketId = result.rows[0]?.id || result.lastInsertRowid;

        // Fetch info for email
        const infoRes = await db.execute({
            sql: `
                SELECT 
                    u.email as requester_email, u.full_name as requester_name,
                    b.contact_email as branch_email, b.name as branch_name
                FROM users u
                LEFT JOIN branches b ON b.id = ?
                WHERE u.id = ?
            `,
            args: [branch_id, requester_id]
        });

        if (infoRes.rows.length > 0) {
            const info = infoRes.rows[0];
            const emails = [info.requester_email];
            if (info.branch_email) emails.push(info.branch_email);

            // Async send (don't block response)
            emailService.sendTicketCreatedEmail({
                to: emails,
                ticketId,
                subject,
                description,
                requesterName: info.requester_name,
                branchName: info.branch_name || 'N/A'
            }).catch(console.error);
        }

        res.status(201).json({ message: 'Ticket created', ticketId });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
};

exports.getTickets = async (req, res) => {
    const { role, id, branch_id } = req.user;

    let sql = `
        SELECT 
            t.*, 
            u.full_name as requester_name,
            ast.full_name as assigned_to_name,
            b.name as branch_name,
            d.name as department_name,
            p.name as priority_name,
            c.name as category_name
        FROM tickets t 
        JOIN users u ON t.requester_id = u.id 
        LEFT JOIN users ast ON t.assigned_to = ast.id
        LEFT JOIN branches b ON t.branch_id = b.id
        LEFT JOIN departments d ON t.department_id = d.id
        LEFT JOIN priorities p ON t.priority_id = p.id
        LEFT JOIN categories c ON t.category_id = c.id
        WHERE t.organization_id = ?
    `;
    let args = [req.organization_id];

    if (role === 'Employee') {
        sql += ' AND t.requester_id = ?';
        args.push(id);
    } else if (role === 'Agent' || role === 'Lead') {
        sql += ' AND t.branch_id = ?';
        args.push(branch_id);
    } else if (role === 'BranchManager') {
        sql += ' AND t.branch_id = ?';
        args.push(branch_id);
    }

    sql += ' ORDER BY t.created_at DESC';

    try {
        const result = await db.execute({ sql, args });
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
};

const recordHistory = async (ticket_id, changed_by, field, old_val, new_val) => {
    if (old_val == new_val) return;
    await db.execute({
        sql: "INSERT INTO ticket_history (ticket_id, changed_by, field_changed, old_value, new_value) VALUES (?, ?, ?, ?, ?)",
        args: [ticket_id, changed_by, field, String(old_val), String(new_val)]
    });
};

exports.updateTicket = async (req, res) => {
    const { id } = req.params;
    const { status, assigned_to, priority_id, category_id, description } = req.body;
    const changed_by = req.user.id;

    try {
        // Fetch current values and related info for email
        const currentTicketResponse = await db.execute({
            sql: `
                SELECT t.*, u.email as requester_email, u.full_name as requester_name,
                       b.contact_email as branch_email, b.name as branch_name,
                       cb.full_name as changed_by_name
                FROM tickets t
                JOIN users u ON t.requester_id = u.id
                LEFT JOIN branches b ON t.branch_id = b.id
                JOIN users cb ON cb.id = ?
                WHERE t.id = ? AND t.organization_id = ?
            `,
            args: [changed_by, id, req.organization_id]
        });

        if (currentTicketResponse.rows.length === 0) {
            return res.status(404).json({ message: 'Ticket not found' });
        }

        const old = currentTicketResponse.rows[0];

        // Perform updates and record history
        const updates = [];
        const args = [];

        if (status && status !== old.status) {
            updates.push("status = ?");
            args.push(status);
            await recordHistory(id, changed_by, 'status', old.status, status);

            // Notify status update
            const destEmails = [old.requester_email];
            if (old.branch_email) destEmails.push(old.branch_email);

            emailService.sendTicketStatusUpdatedEmail({
                to: destEmails,
                ticketId: id,
                subject: old.subject,
                oldStatus: old.status,
                newStatus: status,
                changedBy: old.changed_by_name
            }).catch(console.error);

            if (status === 'Resolved' || status === 'Closed') {
                updates.push("resolved_at = ?");
                args.push(new Date().toISOString());
            }
        }

        if (assigned_to !== undefined && assigned_to !== old.assigned_to) {
            updates.push("assigned_to = ?");
            args.push(assigned_to);
            await recordHistory(id, changed_by, 'assigned_to', old.assigned_to, assigned_to);

            // If assigned, fetch new assignee name and notify
            if (assigned_to) {
                const assigneeRes = await db.execute({
                    sql: "SELECT full_name, email FROM users WHERE id = ?",
                    args: [assigned_to]
                });
                if (assigneeRes.rows.length > 0) {
                    const assignee = assigneeRes.rows[0];
                    emailService.sendTicketAssignedEmail({
                        to: [assignee.email, old.requester_email],
                        ticketId: id,
                        subject: old.subject,
                        assignedToName: assignee.full_name,
                        changedBy: old.changed_by_name
                    }).catch(console.error);
                }
            }
        }

        if (priority_id !== undefined && priority_id !== old.priority_id) {
            updates.push("priority_id = ?");
            args.push(priority_id);
            await recordHistory(id, changed_by, 'priority_id', old.priority_id, priority_id);
        }

        if (category_id !== undefined && category_id !== old.category_id) {
            updates.push("category_id = ?");
            args.push(category_id);
            await recordHistory(id, changed_by, 'category_id', old.category_id, category_id);
        }

        if (description !== undefined && description !== old.description) {
            updates.push("description = ?");
            args.push(description);
            await recordHistory(id, changed_by, 'description', 'Updated', 'Updated');
        }

        if (updates.length > 0) {
            args.push(id, req.organization_id);
            await db.execute({
                sql: `UPDATE tickets SET ${updates.join(', ')} WHERE id = ? AND organization_id = ?`,
                args
            });
        }

        res.json({ message: 'Ticket updated successfully' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
};

exports.getTicketHistory = async (req, res) => {
    const { id } = req.params;
    try {
        const result = await db.execute({
            sql: `
                SELECT 
                    h.*, 
                    u.full_name as changed_by_name 
                FROM ticket_history h
                LEFT JOIN users u ON h.changed_by = u.id
                WHERE h.ticket_id = ?
                ORDER BY h.timestamp DESC
            `,
            args: [id]
        });
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
};
