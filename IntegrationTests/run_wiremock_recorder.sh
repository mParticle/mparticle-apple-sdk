# === Parameters ===
HTTP_PORT=${1:-8080}
HTTPS_PORT=${2:-443}
MAPPINGS_DIR=${3:-"./wiremock-recordings"}
TARGET_URL=${4:-"https://config2.mparticle.com"}

# === Prepare local directory for mappings ===
mkdir -p "${MAPPINGS_DIR}/mappings"
mkdir -p "${MAPPINGS_DIR}/__files"

echo "Starting WireMock in recording mode..."
echo "HTTP port: ${HTTP_PORT}"
echo "HTTPS port: ${HTTPS_PORT}"
echo "Recordings directory: ${MAPPINGS_DIR}"
echo "Target API: ${TARGET_URL}"

# === Run Docker container ===
docker run -it --rm \
  -p ${HTTP_PORT}:8080 \
  -p ${HTTPS_PORT}:8443 \
  -v "$(pwd)/${MAPPINGS_DIR}":/home/wiremock \
  wiremock/wiremock:3.9.1 \
  --enable-browser-proxying \
  --preserve-host-header \
  --record-mappings \
  --proxy-all="${TARGET_URL}" \
  --https-port 8443
