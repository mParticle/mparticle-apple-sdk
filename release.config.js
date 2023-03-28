module.exports = {
    branches: ["main"],
    tagFormat: "v${version}",
    plugins: [
      [
        "@semantic-release/commit-analyzer",
        {
          preset: "angular",
        },
      ],
      [
        "@semantic-release/release-notes-generator",
        {
          preset: "angular",
        },
      ],
      [
        "@semantic-release/changelog",
        {
          changelogFile: "CHANGELOG.md",
        },
      ],
      [
        "@semantic-release/exec",
        {
          prepareCmd: "sh ./Scripts/release.sh ${nextRelease.version} \"${nextRelease.notes}\"",
        },
      ],
      [
        "@semantic-release/github",
        {
          assets: [
            "mParticle_Apple_SDK.framework.zip",
            "mParticle_Apple_SDK_NoLocation.framework.zip",
            "mParticle_Apple_SDK.xcframework.zip",
            "mParticle_Apple_SDK_NoLocation.xcframework.zip",
            "generated-docs.zip",
          ],
        },
      ],
    ],
  };
