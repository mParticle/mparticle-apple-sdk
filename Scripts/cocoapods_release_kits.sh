#!/bin/bash

# This script performs the following action:
#
# * Push all the kits to CocoaPods 

set -vx
git submodule foreach 'pod trunk push $([ "$name" == "Kits/apptentive-kit" ] || [ "$name" == "Kits/revealmobile-kit" ] || echo --use-libraries) --allow-warnings'
