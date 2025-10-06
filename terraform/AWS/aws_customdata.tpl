#!/bin/bash

# ===== Install Docker =====
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker ubuntu

# ===== Setup DuckDNS =====
sudo mkdir -p /home/ubuntu/duckdns
sudo tee /home/ubuntu/duckdns/duck.sh > /dev/null <<'EOF'
#!/bin/bash
IP=$(curl -s ifconfig.me || echo "0.0.0.0")
echo url="https://www.duckdns.org/update?domains=anthonyuwaifo&token=20b89a1b-4d97-4d0b-9a0f-e7cd1d4dd3ae&ip=$IP" | curl -k -o /home/ubuntu/duckdns/duck.log -K -
EOF

sudo chmod 700 /home/ubuntu/duckdns/duck.sh
sudo chown -R ubuntu:ubuntu /home/ubuntu/duckdns
sudo -u ubuntu bash -c '(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ubuntu/duckdns/duck.sh >/dev/null 2>&1") | crontab -'
sudo -u ubuntu /home/ubuntu/duckdns/duck.sh

# ===== Deploy Application =====
sudo docker pull anthonyuwaifo/tic-tac-toe-app
sudo docker run -d --name tic-tac-toe --restart unless-stopped -p 127.0.0.1:5050:5050 anthonyuwaifo/tic-tac-toe-app

# ===== Install NGINX =====
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

sudo tee /etc/nginx/sites-available/tictactoe > /dev/null <<EOF
server {
    listen 443 ssl;
    server_name anthonyuwaifo.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/anthonyuwaifo.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/anthonyuwaifo.duckdns.org/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:5050;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

[ ! -f /etc/nginx/sites-enabled/tictactoe ] && sudo ln -s /etc/nginx/sites-available/tictactoe /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# ===== Install Certbot (DNS Challenge with DuckDNS) =====
sudo apt install -y certbot

# Create hook scripts for DNS-01 challenge
sudo tee /home/ubuntu/duckdns/auth.sh > /dev/null <<'EOF'
#!/bin/bash
echo "Updating DuckDNS TXT record..."
echo "url=https://www.duckdns.org/update?domains=anthonyuwaifo&token=20b89a1b-4d97-4d0b-9a0f-e7cd1d4dd3ae&txt=$CERTBOT_VALIDATION" | curl -k -o /tmp/duck.log -K -
sleep 15  # wait for DNS to propagate
EOF


sudo tee /home/ubuntu/duckdns/cleanup.sh > /dev/null <<'EOF'
#!/bin/bash
echo "Clearing DuckDNS TXT record..."
echo "url=https://www.duckdns.org/update?domains=anthonyuwaifo&token=20b89a1b-4d97-4d0b-9a0f-e7cd1d4dd3ae&txt=" | curl -k -o /tmp/duck.log -K -
EOF

sudo chmod +x /home/ubuntu/duckdns/auth.sh /home/ubuntu/duckdns/cleanup.sh

# Obtain certificate using DNS-01 challenge (non-interactive)
sudo certbot certonly \
  --manual \
  --preferred-challenges dns \
  --manual-auth-hook /home/ubuntu/duckdns/auth.sh \
  --manual-cleanup-hook /home/ubuntu/duckdns/cleanup.sh \
  --non-interactive --agree-tos --manual-public-ip-logging-ok \
  --email auwaifostudy@outlook.com \
  -d anthonyuwaifo.duckdns.org

# Configure NGINX SSL paths
sudo sed -i '/ssl_certificate/d;/ssl_certificate_key/d' /etc/nginx/sites-available/tictactoe
sudo sed -i '/server_name anthonyuwaifo.duckdns.org;/a \ \n    ssl_certificate /etc/letsencrypt/live/anthonyuwaifo.duckdns.org/fullchain.pem;\n    ssl_certificate_key /etc/letsencrypt/live/anthonyuwaifo.duckdns.org/privkey.pem;' /etc/nginx/sites-available/tictactoe

sudo nginx -t && sudo systemctl reload nginx

# ===== Auto Renewal =====
echo "0 3 * * * root certbot renew --quiet --manual-auth-hook /home/ubuntu/duckdns/auth.sh --manual-cleanup-hook /home/ubuntu/duckdns/cleanup.sh --deploy-hook 'systemctl reload nginx'" | sudo tee /etc/cron.d/certbot-renew
