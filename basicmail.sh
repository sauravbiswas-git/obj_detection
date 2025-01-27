#!/bin/bash

# CSV file path
CSV_FILE="data.csv"

# Check if the CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
  echo "CSV file not found: $CSV_FILE"
  exit 1
fi

# Loop through the CSV file line by line (excluding the header row)
tail -n +2 "$CSV_FILE" | while IFS=, read -r BU email file_path; do

  # Check if all required fields are available
  if [[ -z "$BU" || -z "$email" || -z "$file_path" ]]; then
    echo "Missing data in CSV row. Skipping..."
    continue
  fi

  # Create the HTML content
  HTML_CONTENT=$(cat <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Image for $BU</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      text-align: center;
      padding: 20px;
    }
    img {
      max-width: 100%;
      height: auto;
    }
  </style>
</head>
<body>
  <h1>Business Unit: $BU</h1>
  <p>Attached is the image for BU $BU.</p>
  <img src="$file_path" alt="Image for $BU">
</body>
</html>
EOF
  )

  # Send the email using `mail` or `sendmail`
  echo "$HTML_CONTENT" | mail -a "Content-Type: text/html" -s "Image for $BU" "$email"

  echo "Email sent to $email for BU: $BU"
done














#!/bin/bash

# Variables
TO_EMAIL="recipient@example.com"
SUBJECT="Subject of the Email"
FROM_EMAIL="sender@example.com"
HTML_CONTENT="<html><body><h1>Hello!</h1><p>This is an email with a PNG attachment.</p></body></html>"
ATTACHMENT="image.png"

# Boundary for separating content
BOUNDARY="====$(date +%s)===="

# Create the email content
{
echo "From: $FROM_EMAIL"
echo "To: $TO_EMAIL"
echo "Subject: $SUBJECT"
echo "MIME-Version: 1.0"
echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
echo
echo "--$BOUNDARY"
echo "Content-Type: text/html; charset=\"utf-8\""
echo "Content-Transfer-Encoding: 7bit"
echo
echo "$HTML_CONTENT"
echo
echo "--$BOUNDARY"
echo "Content-Type: image/png"
echo "Content-Transfer-Encoding: base64"
echo "Content-Disposition: attachment; filename=\"$(basename $ATTACHMENT)\""
echo
base64 "$ATTACHMENT"
echo
echo "--$BOUNDARY--"
} | sendmail -t

echo "Email sent to $TO_EMAIL with attachment $ATTACHMENT."
