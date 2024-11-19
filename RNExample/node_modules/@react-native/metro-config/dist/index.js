"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true,
});
exports.getDefaultConfig = getDefaultConfig;
Object.defineProperty(exports, "mergeConfig", {
  enumerable: true,
  get: function () {
    return _metroConfig.mergeConfig;
  },
});
var _metroConfig = require("metro-config");
const INTERNAL_CALLSITES_REGEX = new RegExp(
  [
    "/Libraries/BatchedBridge/MessageQueue\\.js$",
    "/Libraries/Core/.+\\.js$",
    "/Libraries/LogBox/.+\\.js$",
    "/Libraries/Network/.+\\.js$",
    "/Libraries/Pressability/.+\\.js$",
    "/Libraries/Renderer/implementations/.+\\.js$",
    "/Libraries/Utilities/.+\\.js$",
    "/Libraries/vendor/.+\\.js$",
    "/Libraries/WebSocket/.+\\.js$",
    "/Libraries/YellowBox/.+\\.js$",
    "/src/private/renderer/errorhandling/.+\\.js$",
    "/metro-runtime/.+\\.js$",
    "/node_modules/@babel/runtime/.+\\.js$",
    "/node_modules/@react-native/js-polyfills/.+\\.js$",
    "/node_modules/event-target-shim/.+\\.js$",
    "/node_modules/invariant/.+\\.js$",
    "/node_modules/react-devtools-core/.+\\.js$",
    "/node_modules/react-native/index.js$",
    "/node_modules/react-refresh/.+\\.js$",
    "/node_modules/scheduler/.+\\.js$",
    "^\\[native code\\]$",
  ]
    .map((pathPattern) => pathPattern.replaceAll("/", "[/\\\\]"))
    .join("|")
);
function getDefaultConfig(projectRoot) {
  const config = {
    resolver: {
      resolverMainFields: ["react-native", "browser", "main"],
      platforms: ["android", "ios"],
      unstable_conditionNames: ["require", "import", "react-native"],
    },
    serializer: {
      getModulesRunBeforeMainModule: () => [
        require.resolve("react-native/Libraries/Core/InitializeCore"),
      ],
      getPolyfills: () => require("@react-native/js-polyfills")(),
      isThirdPartyModule({ path: modulePath }) {
        return (
          INTERNAL_CALLSITES_REGEX.test(modulePath) ||
          /(?:^|[/\\])node_modules[/\\]/.test(modulePath)
        );
      },
    },
    server: {
      port: Number(process.env.RCT_METRO_PORT) || 8081,
    },
    symbolicator: {
      customizeFrame: (frame) => {
        const collapse = Boolean(
          frame.file != null && INTERNAL_CALLSITES_REGEX.test(frame.file)
        );
        return {
          collapse,
        };
      },
    },
    transformer: {
      allowOptionalDependencies: true,
      assetRegistryPath: "react-native/Libraries/Image/AssetRegistry",
      asyncRequireModulePath: require.resolve(
        "metro-runtime/src/modules/asyncRequire"
      ),
      babelTransformerPath: require.resolve(
        "@react-native/metro-babel-transformer"
      ),
      hermesParser: true,
      getTransformOptions: async () => ({
        transform: {
          experimentalImportSupport: false,
          inlineRequires: true,
        },
      }),
    },
    watchFolders: [],
  };
  global.__REACT_NATIVE_METRO_CONFIG_LOADED = true;
  return (0, _metroConfig.mergeConfig)(
    _metroConfig.getDefaultConfig.getDefaultValues(projectRoot),
    config
  );
}
