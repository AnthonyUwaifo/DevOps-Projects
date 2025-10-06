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
sudo usermod -aG docker adminuser

# ===== Setup DuckDNS =====
sudo mkdir -p /home/adminuser/duckdns
sudo tee /home/adminuser/duckdns/duck.sh > /dev/null <<'EOF'
#!/bin/bash
IP=$(curl -s ifconfig.me || echo "0.0.0.0")
echo url="https://www.duckdns.org/update?domains=anthonyuwaifo&token=20b89a1b-4d97-4d0b-9a0f-e7cd1d4dd3ae&ip=$IP" | curl -k -o /home/adminuser/duckdns/duck.log -K -
EOF

sudo chmod 700 /home/adminuser/duckdns/duck.sh
sudo chown -R adminuser:adminuser /home/adminuser/duckdns
sudo -u adminuser bash -c '(crontab -l 2>/dev/null; echo "*/5 * * * * /home/adminuser/duckdns/duck.sh >/dev/null 2>&1") | crontab -'
sudo -u adminuser /home/adminuser/duckdns/duck.sh

# ===== Deploy Application =====
sudo docker pull anthonyuwaifo/tic-tac-toe-app
sudo docker run -d --name tic-tac-toe --restart unless-stopped -p 127.0.0.1:5050:5050 anthonyuwaifo/tic-tac-toe-app

# ===== Install NGINX =====
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

sudo tee /etc/nginx/sites-available/tictactoe > /dev/null <<EOF
server {
    listen 80;
    server_name anthonyuwaifo.duckdns.org;

    location {
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

# ===== Install Certbot & Obtain Certificate =====
sudo apt install -y certbot python3-certbot-nginx

# Non-interactive certificate request (update email!)
sudo certbot --nginx -d anthonyuwaifo.duckdns.org --non-interactive --agree-tos --email email@example.com --redirect
