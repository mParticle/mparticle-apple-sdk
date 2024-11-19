"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true,
});
exports.default = void 0;
var _RootPathUtils = require("./RootPathUtils");
class MockMap {
  #raw;
  #rootDir;
  #pathUtils;
  constructor({ rawMockMap, rootDir }) {
    this.#raw = rawMockMap;
    this.#rootDir = rootDir;
    this.#pathUtils = new _RootPathUtils.RootPathUtils(rootDir);
  }
  getMockModule(name) {
    const mockPath = this.#raw.get(name) || this.#raw.get(name + "/index");
    return mockPath != null ? this.#pathUtils.normalToAbsolute(mockPath) : null;
  }
}
exports.default = MockMap;
