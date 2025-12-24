const { createClient } = require('@libsql/client');

const db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
});

// Countries
exports.getCountries = async (req, res) => {
    try {
        const result = await db.execute({
            sql: "SELECT * FROM countries WHERE organization_id = ?",
            args: [req.organization_id]
        });
        res.json(result.rows);
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.createCountry = async (req, res) => {
    const { name, code } = req.body;
    console.log(`[DEBUG] Attempting to create country: name="${name}", code="${code}" for organization_id="${req.organization_id}"`);
    try {
        const existing = await db.execute({
            sql: "SELECT id FROM countries WHERE organization_id = ? AND (name = ? OR code = ?)",
            args: [req.organization_id, name, code]
        });
        if (existing.rows.length > 0) {
            return res.status(400).json({ message: 'Country with this name or code already exists' });
        }

        const result = await db.execute({
            sql: "INSERT INTO countries (organization_id, name, code, currency, timezone) VALUES (?, ?, ?, ?, ?)",
            args: [req.organization_id, name, code, '', '']
        });
        console.log(`[DEBUG] Country created successfully:`, result);
        res.status(201).json({ message: 'Country created' });
    } catch (e) {
        console.error("[DEBUG] Error creating country:", e);
        res.status(500).json({ message: e.message });
    }
};

exports.updateCountry = async (req, res) => {
    const { id } = req.params;
    const { name, code } = req.body;
    try {
        await db.execute({
            sql: "UPDATE countries SET name = ?, code = ? WHERE id = ? AND organization_id = ?",
            args: [name, code, id, req.organization_id]
        });
        res.json({ message: 'Country updated' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.deleteCountry = async (req, res) => {
    const { id } = req.params;
    try {
        await db.execute({
            sql: "DELETE FROM countries WHERE id = ? AND organization_id = ?",
            args: [id, req.organization_id]
        });
        res.json({ message: 'Country deleted' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.seedCountries = async (req, res) => {
    const countries = [
        { name: 'Afghanistan', code: 'AF', currency: 'AFN', timezone: 'UTC+4:30' },
        { name: 'Albania', code: 'AL', currency: 'ALL', timezone: 'UTC+1' },
        { name: 'Algeria', code: 'DZ', currency: 'DZD', timezone: 'UTC+1' },
        { name: 'Andorra', code: 'AD', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Angola', code: 'AO', currency: 'AOA', timezone: 'UTC+1' },
        { name: 'Antigua and Barbuda', code: 'AG', currency: 'XCD', timezone: 'UTC-4' },
        { name: 'Argentina', code: 'AR', currency: 'ARS', timezone: 'UTC-3' },
        { name: 'Armenia', code: 'AM', currency: 'AMD', timezone: 'UTC+4' },
        { name: 'Australia', code: 'AU', currency: 'AUD', timezone: 'UTC+10' },
        { name: 'Austria', code: 'AT', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Azerbaijan', code: 'AZ', currency: 'AZN', timezone: 'UTC+4' },
        { name: 'Bahamas', code: 'BS', currency: 'BSD', timezone: 'UTC-5' },
        { name: 'Bahrain', code: 'BH', currency: 'BHD', timezone: 'UTC+3' },
        { name: 'Bangladesh', code: 'BD', currency: 'BDT', timezone: 'UTC+6' },
        { name: 'Barbados', code: 'BB', currency: 'BBD', timezone: 'UTC-4' },
        { name: 'Belarus', code: 'BY', currency: 'BYN', timezone: 'UTC+3' },
        { name: 'Belgium', code: 'BE', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Belize', code: 'BZ', currency: 'BZD', timezone: 'UTC-6' },
        { name: 'Benin', code: 'BJ', currency: 'XOF', timezone: 'UTC+1' },
        { name: 'Bhutan', code: 'BT', currency: 'BTN', timezone: 'UTC+6' },
        { name: 'Bolivia', code: 'BO', currency: 'BOB', timezone: 'UTC-4' },
        { name: 'Bosnia and Herzegovina', code: 'BA', currency: 'BAM', timezone: 'UTC+1' },
        { name: 'Botswana', code: 'BW', currency: 'BWP', timezone: 'UTC+2' },
        { name: 'Brazil', code: 'BR', currency: 'BRL', timezone: 'UTC-3' },
        { name: 'Brunei', code: 'BN', currency: 'BND', timezone: 'UTC+8' },
        { name: 'Bulgaria', code: 'BG', currency: 'BGN', timezone: 'UTC+2' },
        { name: 'Burkina Faso', code: 'BF', currency: 'XOF', timezone: 'UTC+0' },
        { name: 'Burundi', code: 'BI', currency: 'BIF', timezone: 'UTC+2' },
        { name: 'Cabo Verde', code: 'CV', currency: 'CVE', timezone: 'UTC-1' },
        { name: 'Cambodia', code: 'KH', currency: 'KHR', timezone: 'UTC+7' },
        { name: 'Cameroon', code: 'CM', currency: 'XAF', timezone: 'UTC+1' },
        { name: 'Canada', code: 'CA', currency: 'CAD', timezone: 'UTC-5' },
        { name: 'Central African Republic', code: 'CF', currency: 'XAF', timezone: 'UTC+1' },
        { name: 'Chad', code: 'TD', currency: 'XAF', timezone: 'UTC+1' },
        { name: 'Chile', code: 'CL', currency: 'CLP', timezone: 'UTC-3' },
        { name: 'China', code: 'CN', currency: 'CNY', timezone: 'UTC+8' },
        { name: 'Colombia', code: 'CO', currency: 'COP', timezone: 'UTC-5' },
        { name: 'Comoros', code: 'KM', currency: 'KMF', timezone: 'UTC+3' },
        { name: 'Congo (Congo-Brazzaville)', code: 'CG', currency: 'XAF', timezone: 'UTC+1' },
        { name: 'Costa Rica', code: 'CR', currency: 'CRC', timezone: 'UTC-6' },
        { name: 'Croatia', code: 'HR', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Cuba', code: 'CU', currency: 'CUP', timezone: 'UTC-5' },
        { name: 'Cyprus', code: 'CY', currency: 'EUR', timezone: 'UTC+2' },
        { name: 'Czechia (Czech Republic)', code: 'CZ', currency: 'CZK', timezone: 'UTC+1' },
        { name: 'Denmark', code: 'DK', currency: 'DKK', timezone: 'UTC+1' },
        { name: 'Djibouti', code: 'DJ', currency: 'DJF', timezone: 'UTC+3' },
        { name: 'Dominica', code: 'DM', currency: 'XCD', timezone: 'UTC-4' },
        { name: 'Dominican Republic', code: 'DO', currency: 'DOP', timezone: 'UTC-4' },
        { name: 'Ecuador', code: 'EC', currency: 'USD', timezone: 'UTC-5' },
        { name: 'Egypt', code: 'EG', currency: 'EGP', timezone: 'UTC+2' },
        { name: 'El Salvador', code: 'SV', currency: 'USD', timezone: 'UTC-6' },
        { name: 'Equatorial Guinea', code: 'GQ', currency: 'XAF', timezone: 'UTC+1' },
        { name: 'Eritrea', code: 'ER', currency: 'ERN', timezone: 'UTC+3' },
        { name: 'Estonia', code: 'EE', currency: 'EUR', timezone: 'UTC+2' },
        { name: 'Eswatini', code: 'SZ', currency: 'SZL', timezone: 'UTC+2' },
        { name: 'Ethiopia', code: 'ET', currency: 'ETB', timezone: 'UTC+3' },
        { name: 'Fiji', code: 'FJ', currency: 'FJD', timezone: 'UTC+12' },
        { name: 'Finland', code: 'FI', currency: 'EUR', timezone: 'UTC+2' },
        { name: 'France', code: 'FR', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Gabon', code: 'GA', currency: 'XAF', timezone: 'UTC+1' },
        { name: 'Gambia', code: 'GM', currency: 'GMD', timezone: 'UTC+0' },
        { name: 'Georgia', code: 'GE', currency: 'GEL', timezone: 'UTC+4' },
        { name: 'Germany', code: 'DE', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Ghana', code: 'GH', currency: 'GHS', timezone: 'UTC+0' },
        { name: 'Greece', code: 'GR', currency: 'EUR', timezone: 'UTC+2' },
        { name: 'Grenada', code: 'GD', currency: 'XCD', timezone: 'UTC-4' },
        { name: 'Guatemala', code: 'GT', currency: 'GTQ', timezone: 'UTC-6' },
        { name: 'Guinea', code: 'GN', currency: 'GNF', timezone: 'UTC+0' },
        { name: 'Guinea-Bissau', code: 'GW', currency: 'XOF', timezone: 'UTC+0' },
        { name: 'Guyana', code: 'GY', currency: 'GYD', timezone: 'UTC-4' },
        { name: 'Haiti', code: 'HT', currency: 'HTG', timezone: 'UTC-5' },
        { name: 'Honduras', code: 'HN', currency: 'HNL', timezone: 'UTC-6' },
        { name: 'Hungary', code: 'HU', currency: 'HUF', timezone: 'UTC+1' },
        { name: 'Iceland', code: 'IS', currency: 'ISK', timezone: 'UTC+0' },
        { name: 'India', code: 'IN', currency: 'INR', timezone: 'UTC+5:30' },
        { name: 'Indonesia', code: 'ID', currency: 'IDR', timezone: 'UTC+7' },
        { name: 'Iran', code: 'IR', currency: 'IRR', timezone: 'UTC+3:30' },
        { name: 'Iraq', code: 'IQ', currency: 'IQD', timezone: 'UTC+3' },
        { name: 'Ireland', code: 'IE', currency: 'EUR', timezone: 'UTC+0' },
        { name: 'Israel', code: 'IL', currency: 'ILS', timezone: 'UTC+2' },
        { name: 'Italy', code: 'IT', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Jamaica', code: 'JM', currency: 'JMD', timezone: 'UTC-5' },
        { name: 'Japan', code: 'JP', currency: 'JPY', timezone: 'UTC+9' },
        { name: 'Jordan', code: 'JO', currency: 'JOD', timezone: 'UTC+3' },
        { name: 'Kazakhstan', code: 'KZ', currency: 'KZT', timezone: 'UTC+6' },
        { name: 'Kenya', code: 'KE', currency: 'KES', timezone: 'UTC+3' },
        { name: 'Kiribati', code: 'KI', currency: 'AUD', timezone: 'UTC+12' },
        { name: 'Korea (North)', code: 'KP', currency: 'KPW', timezone: 'UTC+9' },
        { name: 'Korea (South)', code: 'KR', currency: 'KRW', timezone: 'UTC+9' },
        { name: 'Kuwait', code: 'KW', currency: 'KWD', timezone: 'UTC+3' },
        { name: 'Kyrgyzstan', code: 'KG', currency: 'KGS', timezone: 'UTC+6' },
        { name: 'Laos', code: 'LA', currency: 'LAK', timezone: 'UTC+7' },
        { name: 'Latvia', code: 'LV', currency: 'EUR', timezone: 'UTC+2' },
        { name: 'Lebanon', code: 'LB', currency: 'LBP', timezone: 'UTC+2' },
        { name: 'Lesotho', code: 'LS', currency: 'LSL', timezone: 'UTC+2' },
        { name: 'Liberia', code: 'LR', currency: 'LRD', timezone: 'UTC+0' },
        { name: 'Libya', code: 'LY', currency: 'LYD', timezone: 'UTC+2' },
        { name: 'Liechtenstein', code: 'LI', currency: 'CHF', timezone: 'UTC+1' },
        { name: 'Lithuania', code: 'LT', currency: 'EUR', timezone: 'UTC+2' },
        { name: 'Luxembourg', code: 'LU', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Madagascar', code: 'MG', currency: 'MGA', timezone: 'UTC+3' },
        { name: 'Malawi', code: 'MW', currency: 'MWK', timezone: 'UTC+2' },
        { name: 'Malaysia', code: 'MY', currency: 'MYR', timezone: 'UTC+8' },
        { name: 'Maldives', code: 'MV', currency: 'MVR', timezone: 'UTC+5' },
        { name: 'Mali', code: 'ML', currency: 'XOF', timezone: 'UTC+0' },
        { name: 'Malta', code: 'MT', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Marshall Islands', code: 'MH', currency: 'USD', timezone: 'UTC+12' },
        { name: 'Mauritania', code: 'MR', currency: 'MRU', timezone: 'UTC+0' },
        { name: 'Mauritius', code: 'MU', currency: 'MUR', timezone: 'UTC+4' },
        { name: 'Mexico', code: 'MX', currency: 'MXN', timezone: 'UTC-6' },
        { name: 'Micronesia', code: 'FM', currency: 'USD', timezone: 'UTC+10' },
        { name: 'Moldova', code: 'MD', currency: 'MDL', timezone: 'UTC+2' },
        { name: 'Monaco', code: 'MC', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Mongolia', code: 'MN', currency: 'MNT', timezone: 'UTC+8' },
        { name: 'Montenegro', code: 'ME', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Morocco', code: 'MA', currency: 'MAD', timezone: 'UTC+1' },
        { name: 'Mozambique', code: 'MZ', currency: 'MZN', timezone: 'UTC+2' },
        { name: 'Myanmar', code: 'MM', currency: 'MMK', timezone: 'UTC+6:30' },
        { name: 'Namibia', code: 'NA', currency: 'NAD', timezone: 'UTC+2' },
        { name: 'Nauru', code: 'NR', currency: 'AUD', timezone: 'UTC+12' },
        { name: 'Nepal', code: 'NP', currency: 'NPR', timezone: 'UTC+5:45' },
        { name: 'Netherlands', code: 'NL', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'New Zealand', code: 'NZ', currency: 'NZD', timezone: 'UTC+12' },
        { name: 'Nicaragua', code: 'NI', currency: 'NIO', timezone: 'UTC-6' },
        { name: 'Niger', code: 'NE', currency: 'XOF', timezone: 'UTC+1' },
        { name: 'Nigeria', code: 'NG', currency: 'NGN', timezone: 'UTC+1' },
        { name: 'North Macedonia', code: 'MK', currency: 'MKD', timezone: 'UTC+1' },
        { name: 'Norway', code: 'NO', currency: 'NOK', timezone: 'UTC+1' },
        { name: 'Oman', code: 'OM', currency: 'OMR', timezone: 'UTC+4' },
        { name: 'Pakistan', code: 'PK', currency: 'PKR', timezone: 'UTC+5' },
        { name: 'Palau', code: 'PW', currency: 'USD', timezone: 'UTC+9' },
        { name: 'Panama', code: 'PA', currency: 'PAB', timezone: 'UTC-5' },
        { name: 'Papua New Guinea', code: 'PG', currency: 'PGK', timezone: 'UTC+10' },
        { name: 'Paraguay', code: 'PY', currency: 'PYG', timezone: 'UTC-4' },
        { name: 'Peru', code: 'PE', currency: 'PEN', timezone: 'UTC-5' },
        { name: 'Philippines', code: 'PH', currency: 'PHP', timezone: 'UTC+8' },
        { name: 'Poland', code: 'PL', currency: 'PLN', timezone: 'UTC+1' },
        { name: 'Portugal', code: 'PT', currency: 'EUR', timezone: 'UTC+0' },
        { name: 'Qatar', code: 'QA', currency: 'QAR', timezone: 'UTC+3' },
        { name: 'Romania', code: 'RO', currency: 'RON', timezone: 'UTC+2' },
        { name: 'Russia', code: 'RU', currency: 'RUB', timezone: 'UTC+3' },
        { name: 'Rwanda', code: 'RW', currency: 'RWF', timezone: 'UTC+2' },
        { name: 'Saint Kitts and Nevis', code: 'KN', currency: 'XCD', timezone: 'UTC-4' },
        { name: 'Saint Lucia', code: 'LC', currency: 'XCD', timezone: 'UTC-4' },
        { name: 'Saint Vincent and the Grenadines', code: 'VC', currency: 'XCD', timezone: 'UTC-4' },
        { name: 'Samoa', code: 'WS', currency: 'WST', timezone: 'UTC+13' },
        { name: 'San Marino', code: 'SM', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Sao Tome and Principe', code: 'ST', currency: 'STN', timezone: 'UTC+0' },
        { name: 'Saudi Arabia', code: 'SA', currency: 'SAR', timezone: 'UTC+3' },
        { name: 'Senegal', code: 'SN', currency: 'XOF', timezone: 'UTC+0' },
        { name: 'Serbia', code: 'RS', currency: 'RSD', timezone: 'UTC+1' },
        { name: 'Seychelles', code: 'SC', currency: 'SCR', timezone: 'UTC+4' },
        { name: 'Sierra Leone', code: 'SL', currency: 'SLL', timezone: 'UTC+0' },
        { name: 'Singapore', code: 'SG', currency: 'SGD', timezone: 'UTC+8' },
        { name: 'Slovakia', code: 'SK', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Slovenia', code: 'SI', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Solomon Islands', code: 'SB', currency: 'SBD', timezone: 'UTC+11' },
        { name: 'Somalia', code: 'SO', currency: 'SOS', timezone: 'UTC+3' },
        { name: 'South Africa', code: 'ZA', currency: 'ZAR', timezone: 'UTC+2' },
        { name: 'South Sudan', code: 'SS', currency: 'SSP', timezone: 'UTC+2' },
        { name: 'Spain', code: 'ES', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Sri Lanka', code: 'LK', currency: 'LKR', timezone: 'UTC+5:30' },
        { name: 'Sudan', code: 'SD', currency: 'SDG', timezone: 'UTC+2' },
        { name: 'Suriname', code: 'SR', currency: 'SRD', timezone: 'UTC-3' },
        { name: 'Sweden', code: 'SE', currency: 'SEK', timezone: 'UTC+1' },
        { name: 'Switzerland', code: 'CH', currency: 'CHF', timezone: 'UTC+1' },
        { name: 'Syria', code: 'SY', currency: 'SYP', timezone: 'UTC+2' },
        { name: 'Taiwan', code: 'TW', currency: 'TWD', timezone: 'UTC+8' },
        { name: 'Tajikistan', code: 'TJ', currency: 'TJS', timezone: 'UTC+5' },
        { name: 'Tanzania', code: 'TZ', currency: 'TZS', timezone: 'UTC+3' },
        { name: 'Thailand', code: 'TH', currency: 'THB', timezone: 'UTC+7' },
        { name: 'Timor-Leste', code: 'TL', currency: 'USD', timezone: 'UTC+9' },
        { name: 'Togo', code: 'TG', currency: 'XOF', timezone: 'UTC+0' },
        { name: 'Tonga', code: 'TO', currency: 'TOP', timezone: 'UTC+13' },
        { name: 'Trinidad and Tobago', code: 'TT', currency: 'TTD', timezone: 'UTC-4' },
        { name: 'Tunisia', code: 'TN', currency: 'TND', timezone: 'UTC+1' },
        { name: 'Turkey', code: 'TR', currency: 'TRY', timezone: 'UTC+3' },
        { name: 'Turkmenistan', code: 'TM', currency: 'TMT', timezone: 'UTC+5' },
        { name: 'Tuvalu', code: 'TV', currency: 'AUD', timezone: 'UTC+12' },
        { name: 'Uganda', code: 'UG', currency: 'UGX', timezone: 'UTC+3' },
        { name: 'Ukraine', code: 'UA', currency: 'UAH', timezone: 'UTC+2' },
        { name: 'United Arab Emirates', code: 'AE', currency: 'AED', timezone: 'UTC+4' },
        { name: 'United Kingdom', code: 'GB', currency: 'GBP', timezone: 'UTC+0' },
        { name: 'United States', code: 'US', currency: 'USD', timezone: 'UTC-5' },
        { name: 'Uruguay', code: 'UY', currency: 'UYU', timezone: 'UTC-3' },
        { name: 'Uzbekistan', code: 'UZ', currency: 'UZS', timezone: 'UTC+5' },
        { name: 'Vanuatu', code: 'VU', currency: 'VUV', timezone: 'UTC+11' },
        { name: 'Vatican City', code: 'VA', currency: 'EUR', timezone: 'UTC+1' },
        { name: 'Venezuela', code: 'VE', currency: 'VES', timezone: 'UTC-4' },
        { name: 'Vietnam', code: 'VN', currency: 'VND', timezone: 'UTC+7' },
        { name: 'Yemen', code: 'YE', currency: 'YER', timezone: 'UTC+3' },
        { name: 'Zambia', code: 'ZM', currency: 'ZMW', timezone: 'UTC+2' },
        { name: 'Zimbabwe', code: 'ZW', currency: 'USD', timezone: 'UTC+2' }
    ];

    try {
        const batch = [];
        for (const c of countries) {
            // Check if exists logic could be here, but simpler to just insert or ignore
            // using conflict resolution if constraints were tighter.
            // Here we just insert. To prevent dups, we check first.
            const existing = await db.execute({
                sql: "SELECT id FROM countries WHERE organization_id = ? AND code = ?",
                args: [req.organization_id, c.code]
            });

            if (existing.rows.length === 0) {
                await db.execute({
                    sql: "INSERT INTO countries (organization_id, name, code, currency, timezone) VALUES (?, ?, ?, ?, ?)",
                    args: [req.organization_id, c.name, c.code, c.currency, c.timezone]
                });
            }
        }
        res.json({ message: 'Countries seeded successfully' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

// Branches
exports.getBranches = async (req, res) => {
    try {
        const result = await db.execute({
            sql: "SELECT b.*, c.name as country_name FROM branches b JOIN countries c ON b.country_id = c.id WHERE b.organization_id = ?",
            args: [req.organization_id]
        });
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.createBranch = async (req, res) => {
    const { country_id, name, address, contact_person, contact_number, contact_email } = req.body;
    try {
        const existing = await db.execute({
            sql: "SELECT id FROM branches WHERE organization_id = ? AND name = ?",
            args: [req.organization_id, name]
        });
        if (existing.rows.length > 0) {
            return res.status(400).json({ message: 'Branch with this name already exists' });
        }

        await db.execute({
            sql: "INSERT INTO branches (organization_id, country_id, name, address, contact_person, contact_number, contact_email) VALUES (?, ?, ?, ?, ?, ?, ?)",
            args: [req.organization_id, country_id, name, address, contact_person, contact_number, contact_email]
        });
        res.status(201).json({ message: 'Branch created' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.updateBranch = async (req, res) => {
    const { id } = req.params;
    const { country_id, name, address, contact_person, contact_number, contact_email } = req.body;
    try {
        await db.execute({
            sql: "UPDATE branches SET country_id = ?, name = ?, address = ?, contact_person = ?, contact_number = ?, contact_email = ? WHERE id = ? AND organization_id = ?",
            args: [country_id, name, address, contact_person, contact_number, contact_email, id, req.organization_id]
        });
        res.json({ message: 'Branch updated' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.deleteBranch = async (req, res) => {
    const { id } = req.params;
    try {
        await db.execute({
            sql: "DELETE FROM branches WHERE id = ? AND organization_id = ?",
            args: [id, req.organization_id]
        });
        res.json({ message: 'Branch deleted' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

// Holidays
exports.getHolidays = async (req, res) => {
    const { country_id } = req.query;
    try {
        let sql = 'SELECT * FROM holidays WHERE organization_id = ?';
        let args = [req.organization_id];
        if (country_id) {
            sql += ' AND country_id = ?';
            args.push(country_id);
        }
        const result = await db.execute({ sql, args });
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.createHoliday = async (req, res) => {
    const { country_id, date, description, is_recurring } = req.body;
    try {
        await db.execute({
            sql: 'INSERT INTO holidays (organization_id, country_id, date, description, is_recurring) VALUES (?, ?, ?, ?, ?)',
            args: [req.organization_id, country_id, date, description, is_recurring ? 1 : 0]
        });
        res.status(201).json({ message: 'Holiday created' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// Departments
exports.getDepartments = async (req, res) => {
    try {
        const result = await db.execute({
            sql: "SELECT * FROM departments WHERE organization_id = ?",
            args: [req.organization_id]
        });
        res.json(result.rows);
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.createDepartment = async (req, res) => {
    const { name } = req.body;
    try {
        const existing = await db.execute({
            sql: "SELECT id FROM departments WHERE organization_id = ? AND name = ?",
            args: [req.organization_id, name]
        });
        if (existing.rows.length > 0) {
            return res.status(400).json({ message: 'Department already exists' });
        }

        await db.execute({
            sql: "INSERT INTO departments (organization_id, name) VALUES (?, ?)",
            args: [req.organization_id, name]
        });
        res.status(201).json({ message: 'Department created' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.updateDepartment = async (req, res) => {
    const { id } = req.params;
    const { name } = req.body;
    try {
        await db.execute({
            sql: "UPDATE departments SET name = ? WHERE id = ? AND organization_id = ?",
            args: [name, id, req.organization_id]
        });
        res.json({ message: 'Department updated' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.deleteDepartment = async (req, res) => {
    const { id } = req.params;
    try {
        await db.execute({
            sql: "DELETE FROM departments WHERE id = ? AND organization_id = ?",
            args: [id, req.organization_id]
        });
        res.json({ message: 'Department deleted' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

// Users
exports.getUsers = async (req, res) => {
    try {
        const result = await db.execute({
            sql: `SELECT u.*, d.name as department_name, b.name as branch_name 
                  FROM users u 
                  LEFT JOIN departments d ON u.department_id = d.id 
                  LEFT JOIN branches b ON u.branch_id = b.id 
                  WHERE u.organization_id = ?`,
            args: [req.organization_id]
        });
        res.json(result.rows);
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.createUser = async (req, res) => {
    const { email, password, full_name, role, branch_id, department_id } = req.body;
    try {
        const bcrypt = require('bcrypt');
        const hashedPassword = await bcrypt.hash(password, 10);
        await db.execute({
            sql: `INSERT INTO users (organization_id, email, password_hash, full_name, role, branch_id, department_id) 
                  VALUES (?, ?, ?, ?, ?, ?, ?)`,
            args: [req.organization_id, email, hashedPassword, full_name, role, branch_id, department_id]
        });
        res.status(201).json({ message: 'User created' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.updateUser = async (req, res) => {
    const { id } = req.params;
    const { full_name, role, branch_id, department_id, is_active } = req.body;
    try {
        await db.execute({
            sql: `UPDATE users 
                  SET full_name = ?, role = ?, branch_id = ?, department_id = ?, is_active = ? 
                  WHERE id = ? AND organization_id = ?`,
            args: [full_name, role, branch_id, department_id, is_active ? 1 : 0, id, req.organization_id]
        });
        res.json({ message: 'User updated' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.deleteUser = async (req, res) => {
    const { id } = req.params;
    try {
        await db.execute({
            sql: "DELETE FROM users WHERE id = ? AND organization_id = ? AND role != 'GlobalAdmin'",
            args: [id, req.organization_id]
        });
        res.json({ message: 'User deleted' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

// Categories
exports.getCategories = async (req, res) => {
    try {
        const result = await db.execute({
            sql: "SELECT * FROM categories WHERE organization_id = ?",
            args: [req.organization_id]
        });
        res.json(result.rows);
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.createCategory = async (req, res) => {
    const { name, parent_id } = req.body;
    try {
        const existing = await db.execute({
            sql: "SELECT id FROM categories WHERE organization_id = ? AND name = ?",
            args: [req.organization_id, name]
        });
        if (existing.rows.length > 0) {
            return res.status(400).json({ message: 'Category already exists' });
        }

        await db.execute({
            sql: "INSERT INTO categories (organization_id, name, parent_id) VALUES (?, ?, ?)",
            args: [req.organization_id, name, parent_id || null]
        });
        res.status(201).json({ message: 'Category created' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.updateCategory = async (req, res) => {
    const { id } = req.params;
    const { name, parent_id } = req.body;
    try {
        await db.execute({
            sql: "UPDATE categories SET name = ?, parent_id = ? WHERE id = ? AND organization_id = ?",
            args: [name, parent_id || null, id, req.organization_id]
        });
        res.json({ message: 'Category updated' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.deleteCategory = async (req, res) => {
    const { id } = req.params;
    try {
        await db.execute({
            sql: "DELETE FROM categories WHERE id = ? AND organization_id = ?",
            args: [id, req.organization_id]
        });
        res.json({ message: 'Category deleted' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

// Priorities
exports.getPriorities = async (req, res) => {
    try {
        const result = await db.execute({
            sql: "SELECT * FROM priorities WHERE organization_id = ?",
            args: [req.organization_id]
        });
        res.json(result.rows);
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.createPriority = async (req, res) => {
    const { name, response_sla_minutes, resolution_sla_minutes } = req.body;
    try {
        const existing = await db.execute({
            sql: "SELECT id FROM priorities WHERE organization_id = ? AND name = ?",
            args: [req.organization_id, name]
        });
        if (existing.rows.length > 0) {
            return res.status(400).json({ message: 'Priority already exists' });
        }

        await db.execute({
            sql: "INSERT INTO priorities (organization_id, name, response_sla_minutes, resolution_sla_minutes) VALUES (?, ?, ?, ?)",
            args: [req.organization_id, name, response_sla_minutes, resolution_sla_minutes]
        });
        res.status(201).json({ message: 'Priority created' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.updatePriority = async (req, res) => {
    const { id } = req.params;
    const { name, response_sla_minutes, resolution_sla_minutes } = req.body;
    try {
        await db.execute({
            sql: "UPDATE priorities SET name = ?, response_sla_minutes = ?, resolution_sla_minutes = ? WHERE id = ? AND organization_id = ?",
            args: [name, response_sla_minutes, resolution_sla_minutes, id, req.organization_id]
        });
        res.json({ message: 'Priority updated' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.deletePriority = async (req, res) => {
    const { id } = req.params;
    try {
        await db.execute({
            sql: "DELETE FROM priorities WHERE id = ? AND organization_id = ?",
            args: [id, req.organization_id]
        });
        res.json({ message: 'Priority deleted' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.seedCategories = async (req, res) => {
    const categories = ['Hardware', 'Software', 'Network', 'Access Request', 'Other'];
    try {
        for (const name of categories) {
            const existing = await db.execute({
                sql: "SELECT id FROM categories WHERE organization_id = ? AND name = ?",
                args: [req.organization_id, name]
            });
            if (existing.rows.length === 0) {
                await db.execute({
                    sql: "INSERT INTO categories (organization_id, name) VALUES (?, ?)",
                    args: [req.organization_id, name]
                });
            }
        }
        res.json({ message: 'Categories seeded' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};

exports.seedPriorities = async (req, res) => {
    const priorities = [
        { name: 'P1 - Critical', response_sla_minutes: 60, resolution_sla_minutes: 240 },
        { name: 'P2 - High', response_sla_minutes: 240, resolution_sla_minutes: 480 },
        { name: 'P3 - Normal', response_sla_minutes: 480, resolution_sla_minutes: 1440 },
        { name: 'P4 - Low', response_sla_minutes: 1440, resolution_sla_minutes: 2880 }
    ];
    try {
        for (const p of priorities) {
            const existing = await db.execute({
                sql: "SELECT id FROM priorities WHERE organization_id = ? AND name = ?",
                args: [req.organization_id, p.name]
            });
            if (existing.rows.length === 0) {
                await db.execute({
                    sql: "INSERT INTO priorities (organization_id, name, response_sla_minutes, resolution_sla_minutes) VALUES (?, ?, ?, ?)",
                    args: [req.organization_id, p.name, p.response_sla_minutes, p.resolution_sla_minutes]
                });
            }
        }
        res.json({ message: 'Priorities seeded' });
    } catch (e) {
        res.status(500).json({ message: e.message });
    }
};
