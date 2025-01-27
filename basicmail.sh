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
TO="recipient@example.com"
SUBJECT="Here is your PNG file"
PNG_FILE="/path/to/image.png"
TMP_HTML="/tmp/email.html"

# Create the HTML content
cat <<EOF > $TMP_HTML
<html>
<body>
    <h1>Hello,</h1>
    <p>Please find the PNG file attached below:</p>
    <img src="cid:image.png" alt="PNG Image">
</body>
</html>
EOF

# Send the email with inline image
(
echo "To: $TO"
echo "Subject: $SUBJECT"
echo "Content-Type: multipart/related; boundary=\"boundary\""
echo
echo "--boundary"
echo "Content-Type: text/html; charset=UTF-8"
echo
cat $TMP_HTML
echo "--boundary"
echo "Content-Type: image/png; name=\"image.png\""
echo "Content-Transfer-Encoding: base64"
echo "Content-Disposition: inline; filename=\"image.png\""
echo "Content-ID: <image.png>"
echo
base64 $PNG_FILE
echo "--boundary--"
) | sendmail -t

# Cleanup
rm -f $TMP_HTML

echo "Email sent to $TO"








#!/bin/bash

# CSV file path
CSV_FILE="email_data.csv"

# Check if CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file not found."
    exit 1
fi

# Read the CSV file (skip the header)
tail -n +2 "$CSV_FILE" | while IFS=',' read -r FROM TO SUBJECT PNG_FILE; do
    # Remove quotes from SUBJECT and PNG_FILE if present
    SUBJECT=$(echo "$SUBJECT" | sed 's/^"//;s/"$//')
    PNG_FILE=$(echo "$PNG_FILE" | sed 's/^"//;s/"$//')

    # Check if the PNG file exists
    if [[ ! -f "$PNG_FILE" ]]; then
        echo "Error: PNG file '$PNG_FILE' not found."
        continue
    fi

    # Boundary for email parts
    BOUNDARY="=====BOUNDARY====="

    # Encode the PNG file in base64
    ENCODED_PNG=$(base64 "$PNG_FILE")

    # Create the email
    (
    echo "From: $FROM"
    echo "To: $TO"
    echo "Subject: $SUBJECT"
    echo "MIME-Version: 1.0"
    echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
    echo
    echo "--$BOUNDARY"
    echo "Content-Type: text/html; charset=\"utf-8\""
    echo "Content-Transfer-Encoding: 7bit"
    echo
    echo "<html><body><p>This is a test email with an attachment.</p></body></html>"
    echo
    echo "--$BOUNDARY"
    echo "Content-Type: image/png; name=\"$(basename "$PNG_FILE")\""
    echo "Content-Transfer-Encoding: base64"
    echo "Content-Disposition: attachment; filename=\"$(basename "$PNG_FILE")\""
    echo
    echo "$ENCODED_PNG"
    echo
    echo "--$BOUNDARY--"
    ) | sendmail -t

    echo "Email sent to $TO with subject '$SUBJECT'."
done





