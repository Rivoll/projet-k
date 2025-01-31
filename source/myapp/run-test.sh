#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting test script for static HTML site..."

# Step 1: Check if the HTML files exist
if [ ! -d "/usr/share/nginx/html" ] || [ -z "$(ls -A /usr/share/nginx/html)" ]; then
    echo "Error: HTML files are missing in /usr/share/nginx/html"
    exit 1
else
    echo "HTML files found."
fi

# Step 2: Validate HTML syntax using an HTML linter (optional)
echo "Validating HTML files..."
if command -v tidy &>/dev/null; then
    for file in /usr/share/nginx/html/*.html; do
        echo "Checking $file"
        tidy -q -e "$file"
    done
    echo "HTML validation completed."
else
    echo "Warning: 'tidy' linter is not installed. Skipping HTML validation."
fi

# Step 3: Build the Docker image
echo "Building Docker image..."
docker build -t static-html-site .

# Step 4: Run the container for testing
echo "Running container..."
CONTAINER_ID=$(docker run -d -p 8080:80 static-html-site)

# Step 5: Check if the site is accessible
echo "Testing site availability..."
sleep 2
curl -f http://localhost:8080 || { echo "Error: Site is not accessible!"; docker logs "$CONTAINER_ID"; exit 1; }

# Step 6: Stop and remove the container
echo "Stopping and cleaning up the container..."
docker stop "$CONTAINER_ID" >/dev/null
docker rm "$CONTAINER_ID" >/dev/null

echo "All tests passed successfully!"
