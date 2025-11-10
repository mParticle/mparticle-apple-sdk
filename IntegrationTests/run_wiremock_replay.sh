docker run -it --rm \
  --name wiremock-verify \
  -p 8080:8080 \
  -p 443:8443 \
  -v "$(pwd)/wiremock-recordings":/home/wiremock \
  wiremock/wiremock:3.9.1 \
  --https-port 8443 \
  --verbose
