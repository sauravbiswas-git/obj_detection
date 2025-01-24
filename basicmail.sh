#!/bin/bash

# Define the input CSV file
CSV_FILE="input.csv"

# Define a temporary HTML file
HTML_FILE="email_body.html"

# Check if the CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
  echo "Error: CSV file not found!"
  exit 1
fi

# Read CSV line by line (skipping the header)
tail -n +2 "$CSV_FILE" | while IFS=',' read -r BU email file_path; do
  # Check if the file path exists
  if [[ ! -f "$file_path" ]]; then
    echo "Error: File path $file_path not found for $email!"
    continue
  fi

  # Generate the HTML content
  cat > "$HTML_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 20px;
      padding: 20px;
      background-color: #f4f4f4;
      border: 1px solid #ddd;
    }
    .image-container {
      text-align: center;
      margin-top: 20px;
    }
    img {
      max-width: 100%;
      height: auto;
      border: 1px solid #ccc;
    }
  </style>
  <title>Email</title>
</head>
<body>
  <h1>Hello ${BU} Team,</h1>
  <p>Please find the image below:</p>
  <div class="image-container">
    <img src="cid:image1" alt="Embedded Image">
  </div>
  <p>Best regards,<br>Your Automation Script</p>
</body>
</html>
EOF

  # Send the email with the embedded image
  (
    echo "To: $email"
    echo "Subject: Image Email for $BU"
    echo "MIME-Version: 1.0"
    echo "Content-Type: multipart/related; boundary=\"boundary\""
    echo
    echo "--boundary"
    echo "Content-Type: text/html; charset=UTF-8"
    echo "Content-Transfer-Encoding: 7bit"
    echo
    cat "$HTML_FILE"
    echo "--boundary"
    echo "Content-Type: image/jpeg"
    echo "Content-Disposition: inline; filename=$(basename "$file_path")"
    echo "Content-ID: <image1>"
    echo "Content-Transfer-Encoding: base64"
    echo
    base64 "$file_path"
    echo "--boundary--"
  ) | sendmail -t

  echo "Email sent to $email with image $file_path."
done

# Cleanup
rm -f "$HTML_FILE"
