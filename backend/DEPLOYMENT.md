# Deployment Guide: Linux VPS

To deploy the backend to your Linux VPS (on port 3005), follow these steps:

### 1. Transfer Files
Upload the following files/directories to your VPS:
- `src/`
- `server.js`
- `package.json`
- `.env` (Update if database OR other credentials change)

> [!NOTE]
> Do NOT upload `node_modules`. You will install them on the VPS.

### 2. Install Dependencies
Run this command inside the project directory on your VPS:
```bash
npm install --production
```

### 3. Run with PM2 (Recommended)
To keep the server running in the background and auto-restart on crashes or reboots:
```bash
# Install PM2 globally
sudo npm install -g pm2

# Start the server
pm2 start server.js --name "corpticktez-backend"

# Ensure it starts on system boot
pm2 save
pm2 startup
```

### 4. Firewall Setup
Ensure port 3005 is open on your VPS firewall (e.g., UFW):
```bash
sudo ufw allow 3005
```

### 5. Verify
Test the API by visiting `http://your-vps-ip:3005/` in your browser.

---

# Part 2: Flutter Web Deployment (Option 1: Nginx)

To host your web app on the same VPS, Nginx is the best choice for performance.

### 1. Build and Upload
1. Run `flutter build web --release` on your PC.
2. Upload the entire contents of `frontend/build/web/` to a folder on your VPS (e.g., `/var/www/corpticketz`).

### 2. Install Nginx
On your VPS:
```bash
sudo apt update
sudo apt install nginx
```

### 3. Configure Nginx
Create a new configuration:
```bash
sudo nano /etc/nginx/sites-available/corpticketz
```
Paste this configuration (replace `your-domain.com` or `your-vps-ip`):
```nginx
server {
    listen 80;
    server_name your-vps-ip;

    root /var/www/corpticketz;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy API requests to the Node.js backend
    location /api/ {
        proxy_pass http://localhost:3005;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 4. Enable the Site
```bash
sudo ln -s /etc/nginx/sites-available/corpticketz /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 5. Firewall Setup
Allow HTTP/HTTPS traffic:
```bash
sudo ufw allow 'Nginx Full'
```

---

# Part 3: Simple Web Hosting (Option 2: Node.js)
If you don't want to use Nginx, you can use the `serve` package:
```bash
sudo npm install -g serve
serve -s /var/www/corpticketz -l 80
```
