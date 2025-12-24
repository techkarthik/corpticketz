const bcrypt = require('bcrypt');

async function run() {
    const hash = '$2b$10$6fo.ul1FNfhhY693bHbnFef2o.nSIEBcSlzdVwmDOeHQ4cv5.sNTO';
    const pass = 'admin123';
    const match = await bcrypt.compare(pass, hash);
    console.log(`Match: ${match}`);

    const newHash = await bcrypt.hash(pass, 10);
    console.log(`New Hash: ${newHash}`);
    const matchNew = await bcrypt.compare(pass, newHash);
    console.log(`Match New: ${matchNew}`);
}
run();
