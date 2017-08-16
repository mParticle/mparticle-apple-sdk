#!/usr/bin/env ruby

# This script performs the following actions:
#
# * Replace version numbers in the core and kits, update changelog
# * Update the version of core that the kits require
# * Commit the version changes and submodule updates 

version=ARGV[0]
unless version && version.length > 0 then puts "Usage: ./Scripts/update_version.rb <version>"; exit 1; end

versionComponents = version.split '.'
versionComponents[2] = '0'
lastZeroVersion = versionComponents.join '.'

def command_lines
    <<-HEREDOC
set -vx
podspec-bump -w -i VERSION
cat mParticle-Apple-SDK/MPIConstants.m | sed 's/NSString \\*const kMParticleSDKVersion = @".*/NSString *const kMParticleSDKVersion = @"VERSION";/' > tmp; mv tmp mParticle-Apple-SDK/MPIConstants.m
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString VERSION" Framework/Info.plist
git submodule foreach $'sed -i \\'\\' -e "s/dependency\\\\([ ]*\\\\)\\'mParticle-Apple-SDK\\\\/mParticle.*/dependency\\\\1\\'mParticle-Apple-SDK\\\\/mParticle\\', \\'~> DEPENDENCY_VERSION\\'/g" *.podspec'
git submodule foreach podspec-bump -w -i VERSION
git submodule foreach "git add .; git commit -m 'Update version to VERSION'"
git add .; git commit -m 'Update version to VERSION'
    HEREDOC
end

def sub(str, toReplace, replacement)
  array = str.split "\n"
  array.each { |line| line.gsub! toReplace, replacement; }
  str = array.join "\n"
  str
end

lines = command_lines
lines = sub(lines, 'DEPENDENCY_VERSION', lastZeroVersion)
lines = sub(lines, 'VERSION', version)


`#{lines}`
