#!/bin/bash

# This script performs the following actions:
#
# * Push core to CocoaPods
# * Push all the kits to CocoaPods 

pod trunk push
git submodule foreach 'pod trunk push $([ "$name" == "Kits/apptentive-kit" ] || echo --use-libraries) --allow-warnings'
