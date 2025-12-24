const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT),
    secure: process.env.SMTP_PORT == '465',
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
    },
});

const sendEmail = async (to, subject, html) => {
    try {
        const info = await transporter.sendMail({
            from: `"CorpTicketz" <${process.env.SMTP_USER}>`,
            to,
            subject,
            html,
        });
        console.log('Email sent: %s', info.messageId);
        return info;
    } catch (error) {
        console.error('Error sending email:', error);
        throw error; // Throw so caller knows it failed
    }
};

const sendTicketCreatedEmail = async ({ to, ticketId, subject, description, requesterName, branchName }) => {
    const html = `
        <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
            <h2 style="color: #0056D2;">New Ticket Created: #${ticketId}</h2>
            <p><strong>Subject:</strong> ${subject}</p>
            <p><strong>Requester:</strong> ${requesterName}</p>
            <p><strong>Branch:</strong> ${branchName}</p>
            <hr>
            <p><strong>Description:</strong></p>
            <p>${description}</p>
            <hr>
            <p style="color: #666; font-size: 12px;">This is an automated notification from CorpTicketz.</p>
        </div>
    `;
    return sendEmail(to, `New Ticket Created: #${ticketId} - ${subject}`, html);
};

const sendTicketStatusUpdatedEmail = async ({ to, ticketId, subject, oldStatus, newStatus, changedBy }) => {
    const html = `
        <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
            <h2 style="color: #0056D2;">Ticket Status Updated: #${ticketId}</h2>
            <p><strong>Ticket:</strong> ${subject}</p>
            <p><strong>Status Change:</strong> <span style="color: #666; text-decoration: line-through;">${oldStatus}</span> &rarr; <strong style="color: #28a745;">${newStatus}</strong></p>
            <p><strong>Updated By:</strong> ${changedBy}</p>
            <hr>
            <p style="color: #666; font-size: 12px;">This is an automated notification from CorpTicketz.</p>
        </div>
    `;
    return sendEmail(to, `Ticket #${ticketId} Status Updated to ${newStatus}`, html);
};

const sendTicketAssignedEmail = async ({ to, ticketId, subject, assignedToName, changedBy }) => {
    const html = `
        <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
            <h2 style="color: #0056D2;">Ticket Assigned: #${ticketId}</h2>
            <p><strong>Ticket:</strong> ${subject}</p>
            <p><strong>Assigned To:</strong> ${assignedToName}</p>
            <p><strong>Assigned By:</strong> ${changedBy}</p>
            <hr>
            <p style="color: #666; font-size: 12px;">This is an automated notification from CorpTicketz.</p>
        </div>
    `;
    return sendEmail(to, `Ticket #${ticketId} Assigned to ${assignedToName}`, html);
};

module.exports = {
    sendEmail,
    sendTicketCreatedEmail,
    sendTicketStatusUpdatedEmail,
    sendTicketAssignedEmail
};
