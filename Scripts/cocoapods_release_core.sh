#!/bin/bash

# This script performs the following actions:
#
# * Push core to CocoaPods
# * Update the local CocoaPods specs repo

set -vx
pod trunk push
pod repo update
