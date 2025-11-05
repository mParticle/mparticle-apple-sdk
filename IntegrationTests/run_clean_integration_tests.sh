#!/bin/bash
set -e

# === 🔧 Настройки ===
APP_NAME="IntegrationTests"
SCHEME="IntegrationTests"
BUNDLE_ID="com.mparticle.IntegrationTests"
DEVICE_NAME="iPhone 16"                # Симулятор
CONFIGURATION="Debug"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
WIREMOCK_URL="https://localhost:443"   # Твой локальный WireMock endpoint

# === 🧹 Полная очистка симулятора ===
echo "🧹 Сброс симуляторов..."
xcrun simctl shutdown all || true
xcrun simctl erase all || true
killall Simulator || true

echo "✅ Симуляторы очищены."

# === 🧱 Сборка проекта ===
echo "📦 Сборка приложения '$APP_NAME'..."
xcodebuild \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
  -derivedDataPath "$DERIVED_DATA" \
  build || { echo "❌ Ошибка сборки"; exit 1; }

# === 🔍 Поиск устройства ===
DEVICE_ID=$(xcrun simctl list devices | grep "$DEVICE_NAME" | grep -v "unavailable" | awk -F '[()]' '{print $2}' | head -1)
if [ -z "$DEVICE_ID" ]; then
  echo "❌ Симулятор '$DEVICE_NAME' не найден. Проверь Xcode > Devices & Simulators."
  exit 1
fi

# === 🔍 Поиск .app файла ===
APP_PATH=$(find "$DERIVED_DATA" -type d -path "*/Build/Products/${CONFIGURATION}-iphonesimulator/${APP_NAME}.app" | head -1)
if [ ! -d "$APP_PATH" ]; then
  echo "❌ .app не найден. Проверь схему и путь сборки."
  exit 1
fi

# === 📱 Запуск симулятора ===
echo "📱 Запуск симулятора $DEVICE_NAME..."
xcrun simctl boot "$DEVICE_ID" || true
open -a Simulator

# Подождём, пока симулятор загрузится
echo "⏳ Ожидание запуска симулятора..."
sleep 50

# === 📲 Установка приложения ===
echo "📲 Установка '$APP_NAME'..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

sleep 30

# === ⚙️ Настройка переменной окружения / API URL ===
# Если приложение читает из UserDefaults
echo "⚙️ Настройка APIBaseURL -> $WIREMOCK_URL"
defaults write "$BUNDLE_ID" APIBaseURL "$WIREMOCK_URL"

# === ▶️ Запуск приложения ===
echo "▶️ Запуск приложения..."
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"

echo "✅ Приложение '$APP_NAME' запущено на чистом '$DEVICE_NAME'."

