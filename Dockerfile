FROM node:18

# Install system dependencies for both applications
RUN apt-get update && apt-get install -y \
    chromium \
    ffmpeg \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Set Puppeteer envs to use installed Chromium
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Create directories for both applications
WORKDIR /app
RUN mkdir -p /app/ws4kp /app/ws4channels /app/shared

# Install ws4channels dependencies
COPY package*.json ./
RUN npm install --verbose

# Copy ws4channels application files
COPY . /app/ws4channels/

# Prepare ws4channels assets
RUN mkdir -p /app/music /app/logo /app/output
COPY music/*.mp3 /app/music/
COPY logo/*.png /app/logo/

# Clone and setup WS4KP
RUN git clone https://github.com/netbymatt/ws4kp.git /app/ws4kp
WORKDIR /app/ws4kp
RUN npm install
RUN npm run build

# Create nginx configuration for both services
RUN cat > /etc/nginx/sites-available/default << 'EOF'
server {
listen 80;
server_name _;

# WS4KP application (port 8080)
location / {
proxy_pass http://localhost:8080;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
}

# ws4channels streaming endpoints
location /stream/ {
proxy_pass http://localhost:9798;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
}

location /playlist.m3u {
proxy_pass http://localhost:9798;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
}

location /guide.xml {
proxy_pass http://localhost:9798;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
}

location /health {
proxy_pass http://localhost:9798;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
}

location /logo/ {
proxy_pass http://localhost:9798;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
}
}
EOF

# Create startup script
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash

# Start WS4KP in background
echo "Starting WS4KP..."
cd /app/ws4kp
node index.mjs &
WS4KP_PID=$!

# Wait for WS4KP to start
sleep 5

# Start ws4channels in background
echo "Starting ws4channels..."
cd /app/ws4channels
node index.js &
WS4CHANNELS_PID=$!

# Start nginx
echo "Starting nginx..."
nginx -g "daemon off;" &
NGINX_PID=$!

# Function to handle shutdown
cleanup() {
echo "Shutting down services..."
kill $WS4KP_PID 2>/dev/null
kill $WS4CHANNELS_PID 2>/dev/null
kill $NGINX_PID 2>/dev/null
exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Wait for all processes
wait
EOF

RUN chmod +x /app/start.sh

# Set working directory back to ws4channels
WORKDIR /app/ws4channels

# Expose ports
EXPOSE 80 8080 9798

# Start both services
CMD ["/app/start.sh"] 