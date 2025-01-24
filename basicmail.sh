#!/bin/bash

# Function to send an email with an attached image
send_email() {
  local recipient="$1"
  local subject="$2"
  local body="$3"
  local attachment="$4"

  # Construct the mail command
  mail -s "$subject" "$recipient" <<EOF
From: Your Name <your_email@example.com>

$body

EOF
  # Attach the image
  uuencode "$attachment" "image.png" | mail -s "$subject" "$recipient" -a "image.png"
}

# Read data from CSV file
while IFS=, read -r dept email png_path
do
  # Create HTML content with image
  html_body=$(cat <<EOF
<!DOCTYPE html>
<html>
<head>
  <style>
    img {
      max-width: 100%;
      height: auto;
    }
  </style>
</head>
<body>
  <h2>Department: ${dept}</h2>
  <img src="cid:image.png" alt="Image">
</body>
</html>
EOF
  )

  # Send email with attachment
  send_email "$email" "Image from ${dept}" "$html_body" "$png_path"

done < "your_data.csv"

echo "Emails sent successfully."
