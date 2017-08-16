#!/usr/bin/env ruby

# This script performs the following actions:
#
# * Tag and push all the kits to GitHub
# * Merge, tag, and push the core SDK to GitHub
# * Create the GitHub release
# * Build a Carthage artifact and attach it to the core GitHub release

version=ARGV[0]
token=ENV['GITHUB_ACCESS_TOKEN']

unless version && token && version.length > 0 && token.length > 0 then puts "Usage: export GITHUB_ACCESS_TOKEN=<token>; ./Scripts/github_release.rb <version>"; exit 1; end

def command_lines
    <<-HEREDOC
set -vx
git remote remove public || true
git remote add public git@github.com:mparticle/mparticle-apple-sdk
git push origin development
git tag VERSION
git submodule foreach "git tag VERSION; git push origin master; git push origin VERSION"
git push public HEAD:master
git push public VERSION
git push origin HEAD:master
git push origin VERSION
curl -v --data '{"tag_name": "VERSION","target_commitish": "master","name": "Version VERSION","body": "","draft": false,"prerelease": false}' https://api.github.com/repos/mparticle/mparticle-apple-sdk/releases?access_token=GITHUB_ACCESS_TOKEN | grep '^  "id": ' | sed 's/"id":[ ]*\([^,]*\),/\1/' > /tmp/release-id
carthage build --no-skip-current mParticle-Apple-SDK.xcodeproj
carthage archive
curl -v "https://uploads.github.com/repos/mparticle/mparticle-apple-sdk/releases/$(cat /tmp/release-id | sed 's/[ ]*//g')/assets?access_token=GITHUB_ACCESS_TOKEN&name=mParticle_Apple_SDK.framework.zip" --header 'Content-Type: application/zip' --upload-file mParticle_Apple_SDK.framework.zip -X POST
rm /tmp/release-id
    HEREDOC
end

def sub(str, toReplace, replacement)
  array = str.split "\n"
  array.each { |line| line.gsub! toReplace, replacement; }
  str = array.join "\n"
  str
end

lines = command_lines
lines = sub(lines, 'VERSION', version)
lines = sub(lines, 'GITHUB_ACCESS_TOKEN', token)

`#{lines}`
