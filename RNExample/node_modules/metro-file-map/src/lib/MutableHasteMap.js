"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true,
});
exports.default = void 0;
var _constants = _interopRequireDefault(require("../constants"));
var _DuplicateError = require("./DuplicateError");
var _DuplicateHasteCandidatesError = require("./DuplicateHasteCandidatesError");
var _getPlatformExtension = _interopRequireDefault(
  require("./getPlatformExtension")
);
var _RootPathUtils = require("./RootPathUtils");
var _path = _interopRequireDefault(require("path"));
function _interopRequireDefault(e) {
  return e && e.__esModule ? e : { default: e };
}
const EMPTY_OBJ = {};
const EMPTY_MAP = new Map();
class MutableHasteMap {
  #rootDir;
  #map = new Map();
  #duplicates = new Map();
  #console;
  #pathUtils;
  #platforms;
  #throwOnModuleCollision;
  constructor(options) {
    this.#console = options.console ?? null;
    this.#platforms = options.platforms;
    this.#rootDir = options.rootDir;
    this.#pathUtils = new _RootPathUtils.RootPathUtils(options.rootDir);
    this.#throwOnModuleCollision = options.throwOnModuleCollision;
  }
  static fromDeserializedSnapshot(deserializedData, options) {
    const hasteMap = new MutableHasteMap(options);
    hasteMap.#map = deserializedData.map;
    hasteMap.#duplicates = deserializedData.duplicates;
    return hasteMap;
  }
  getSerializableSnapshot() {
    const mapMap = (map, mapFn) => {
      return new Map(
        Array.from(map.entries(), ([key, val]) => [key, mapFn(val)])
      );
    };
    return {
      duplicates: mapMap(this.#duplicates, (v) =>
        mapMap(v, (v2) => new Map(v2.entries()))
      ),
      map: mapMap(this.#map, (v) =>
        Object.assign(
          Object.create(null),
          Object.fromEntries(
            Array.from(Object.entries(v), ([key, val]) => [key, [...val]])
          )
        )
      ),
    };
  }
  getModule(name, platform, supportsNativePlatform, type) {
    const module = this._getModuleMetadata(
      name,
      platform,
      !!supportsNativePlatform
    );
    if (
      module &&
      module[_constants.default.TYPE] === (type ?? _constants.default.MODULE)
    ) {
      const modulePath = module[_constants.default.PATH];
      return modulePath && this.#pathUtils.normalToAbsolute(modulePath);
    }
    return null;
  }
  getPackage(name, platform, _supportsNativePlatform) {
    return this.getModule(name, platform, null, _constants.default.PACKAGE);
  }
  getRawHasteMap() {
    return {
      duplicates: this.#duplicates,
      map: this.#map,
    };
  }
  _getModuleMetadata(name, platform, supportsNativePlatform) {
    const map = this.#map.get(name) || EMPTY_OBJ;
    const dupMap = this.#duplicates.get(name) || EMPTY_MAP;
    if (platform != null) {
      this._assertNoDuplicates(
        name,
        platform,
        supportsNativePlatform,
        dupMap.get(platform)
      );
      if (map[platform] != null) {
        return map[platform];
      }
    }
    if (supportsNativePlatform) {
      this._assertNoDuplicates(
        name,
        _constants.default.NATIVE_PLATFORM,
        supportsNativePlatform,
        dupMap.get(_constants.default.NATIVE_PLATFORM)
      );
      if (map[_constants.default.NATIVE_PLATFORM]) {
        return map[_constants.default.NATIVE_PLATFORM];
      }
    }
    this._assertNoDuplicates(
      name,
      _constants.default.GENERIC_PLATFORM,
      supportsNativePlatform,
      dupMap.get(_constants.default.GENERIC_PLATFORM)
    );
    if (map[_constants.default.GENERIC_PLATFORM]) {
      return map[_constants.default.GENERIC_PLATFORM];
    }
    return null;
  }
  _assertNoDuplicates(name, platform, supportsNativePlatform, relativePathSet) {
    if (relativePathSet == null) {
      return;
    }
    const duplicates = new Map();
    for (const [relativePath, type] of relativePathSet) {
      const duplicatePath = this.#pathUtils.normalToAbsolute(relativePath);
      duplicates.set(duplicatePath, type);
    }
    throw new _DuplicateHasteCandidatesError.DuplicateHasteCandidatesError(
      name,
      platform,
      supportsNativePlatform,
      duplicates
    );
  }
  setModule(id, module) {
    let hasteMapItem = this.#map.get(id);
    if (!hasteMapItem) {
      hasteMapItem = Object.create(null);
      this.#map.set(id, hasteMapItem);
    }
    const platform =
      (0, _getPlatformExtension.default)(
        module[_constants.default.PATH],
        this.#platforms
      ) || _constants.default.GENERIC_PLATFORM;
    const existingModule = hasteMapItem[platform];
    if (
      existingModule &&
      existingModule[_constants.default.PATH] !==
        module[_constants.default.PATH]
    ) {
      if (this.#console) {
        const method = this.#throwOnModuleCollision ? "error" : "warn";
        this.#console[method](
          [
            "metro-file-map: Haste module naming collision: " + id,
            "  The following files share their name; please adjust your hasteImpl:",
            "    * <rootDir>" +
              _path.default.sep +
              existingModule[_constants.default.PATH],
            "    * <rootDir>" +
              _path.default.sep +
              module[_constants.default.PATH],
            "",
          ].join("\n")
        );
      }
      if (this.#throwOnModuleCollision) {
        throw new _DuplicateError.DuplicateError(
          existingModule[_constants.default.PATH],
          module[_constants.default.PATH]
        );
      }
      delete hasteMapItem[platform];
      if (Object.keys(hasteMapItem).length === 0) {
        this.#map.delete(id);
      }
      let dupsByPlatform = this.#duplicates.get(id);
      if (dupsByPlatform == null) {
        dupsByPlatform = new Map();
        this.#duplicates.set(id, dupsByPlatform);
      }
      const dups = new Map([
        [module[_constants.default.PATH], module[_constants.default.TYPE]],
        [
          existingModule[_constants.default.PATH],
          existingModule[_constants.default.TYPE],
        ],
      ]);
      dupsByPlatform.set(platform, dups);
      return;
    }
    const dupsByPlatform = this.#duplicates.get(id);
    if (dupsByPlatform != null) {
      const dups = dupsByPlatform.get(platform);
      if (dups != null) {
        dups.set(
          module[_constants.default.PATH],
          module[_constants.default.TYPE]
        );
      }
      return;
    }
    hasteMapItem[platform] = module;
  }
  removeModule(moduleName, relativeFilePath) {
    const platform =
      (0, _getPlatformExtension.default)(relativeFilePath, this.#platforms) ||
      _constants.default.GENERIC_PLATFORM;
    const hasteMapItem = this.#map.get(moduleName);
    if (hasteMapItem != null) {
      delete hasteMapItem[platform];
      if (Object.keys(hasteMapItem).length === 0) {
        this.#map.delete(moduleName);
      } else {
        this.#map.set(moduleName, hasteMapItem);
      }
    }
    this._recoverDuplicates(moduleName, relativeFilePath);
  }
  setThrowOnModuleCollision(shouldThrow) {
    this.#throwOnModuleCollision = shouldThrow;
  }
  _recoverDuplicates(moduleName, relativeFilePath) {
    let dupsByPlatform = this.#duplicates.get(moduleName);
    if (dupsByPlatform == null) {
      return;
    }
    const platform =
      (0, _getPlatformExtension.default)(relativeFilePath, this.#platforms) ||
      _constants.default.GENERIC_PLATFORM;
    let dups = dupsByPlatform.get(platform);
    if (dups == null) {
      return;
    }
    dupsByPlatform = new Map(dupsByPlatform);
    this.#duplicates.set(moduleName, dupsByPlatform);
    dups = new Map(dups);
    dupsByPlatform.set(platform, dups);
    dups.delete(relativeFilePath);
    if (dups.size !== 1) {
      return;
    }
    const uniqueModule = dups.entries().next().value;
    if (!uniqueModule) {
      return;
    }
    let dedupMap = this.#map.get(moduleName);
    if (dedupMap == null) {
      dedupMap = Object.create(null);
      this.#map.set(moduleName, dedupMap);
    }
    dedupMap[platform] = uniqueModule;
    dupsByPlatform.delete(platform);
    if (dupsByPlatform.size === 0) {
      this.#duplicates.delete(moduleName);
    }
  }
}
exports.default = MutableHasteMap;
