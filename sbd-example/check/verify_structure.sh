#!/bin/bash

# Script to check SPM package structure

echo "Checking package structure..."
echo ""

# Check for Package.swift
if [ ! -f "Package.swift" ]; then
	echo "❌ Package.swift not found!"
	exit 1
fi
echo "✅ Package.swift found"

# Check Sources structure
echo ""
echo "Checking Sources/..."

for target in B BObjC A; do
	if [ ! -d "Sources/$target" ]; then
		echo "❌ Sources/$target not found!"
		exit 1
	fi
	echo "✅ Sources/$target found"
done

# Check module B files
echo ""
echo "Checking module B..."
if [ ! -f "Sources/B/PricingEngine.swift" ]; then
	echo "❌ Sources/B/PricingEngine.swift not found!"
	exit 1
fi
echo "✅ Sources/B/PricingEngine.swift found"

# Check module BObjC files
echo ""
echo "Checking module BObjC..."
if [ ! -f "Sources/BObjC/BPricingEngineObjC.swift" ]; then
	echo "❌ Sources/BObjC/BPricingEngineObjC.swift not found!"
	exit 1
fi
echo "✅ Sources/BObjC/BPricingEngineObjC.swift found"

# Check module A files
echo ""
echo "Checking module A..."
if [ ! -f "Sources/A/AThing.h" ]; then
	echo "❌ Sources/A/AThing.h not found!"
	exit 1
fi
echo "✅ Sources/A/AThing.h found"

if [ ! -f "Sources/A/AThing.m" ]; then
	echo "❌ Sources/A/AThing.m not found!"
	exit 1
fi
echo "✅ Sources/A/AThing.m found"

# Check tests
echo ""
echo "Checking tests..."
if [ ! -d "Tests/MyModulesTests" ]; then
	echo "⚠️  Tests/MyModulesTests not found (not critical)"
else
	echo "✅ Tests/MyModulesTests found"
fi

echo ""
echo "✅ Package structure is correct!"
echo ""
echo "Try opening project:"
echo "  open Package.swift"
echo "or"
echo "  xed ."
