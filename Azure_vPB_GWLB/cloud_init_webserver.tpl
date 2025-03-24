#!/bin/bash
apt update
apt install -y nginx

# Create an HTML file with larger, centered, and colored text
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
    <style>
        body {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background-color: #f0f0f0; /* Light gray background */
            font-family: Arial, sans-serif;
            margin: 0;
        }
        .welcome-text {
            font-size: 50px;
            font-weight: bold;
            color:rgb(0, 136, 255); /* Orange text color */
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
        }
    </style>
</head>
<body>
    <div class="welcome-text">Hello from $(hostname)</div>
</body>
</html>
EOF

systemctl enable nginx
systemctl start nginx
