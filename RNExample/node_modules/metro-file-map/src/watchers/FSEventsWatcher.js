"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true,
});
exports.default = void 0;
var _common = require("./common");
var _anymatch = _interopRequireDefault(require("anymatch"));
var _events = _interopRequireDefault(require("events"));
var _fs = require("fs");
var path = _interopRequireWildcard(require("path"));
var _walker = _interopRequireDefault(require("walker"));
function _getRequireWildcardCache(e) {
  if ("function" != typeof WeakMap) return null;
  var r = new WeakMap(),
    t = new WeakMap();
  return (_getRequireWildcardCache = function (e) {
    return e ? t : r;
  })(e);
}
function _interopRequireWildcard(e, r) {
  if (!r && e && e.__esModule) return e;
  if (null === e || ("object" != typeof e && "function" != typeof e))
    return { default: e };
  var t = _getRequireWildcardCache(r);
  if (t && t.has(e)) return t.get(e);
  var n = { __proto__: null },
    a = Object.defineProperty && Object.getOwnPropertyDescriptor;
  for (var u in e)
    if ("default" !== u && {}.hasOwnProperty.call(e, u)) {
      var i = a ? Object.getOwnPropertyDescriptor(e, u) : null;
      i && (i.get || i.set) ? Object.defineProperty(n, u, i) : (n[u] = e[u]);
    }
  return (n.default = e), t && t.set(e, n), n;
}
function _interopRequireDefault(e) {
  return e && e.__esModule ? e : { default: e };
}
const debug = require("debug")("Metro:FSEventsWatcher");
let fsevents = null;
try {
  fsevents = require("fsevents");
} catch {}
const CHANGE_EVENT = "change";
const DELETE_EVENT = "delete";
const ADD_EVENT = "add";
const ALL_EVENT = "all";
class FSEventsWatcher extends _events.default {
  static isSupported() {
    return fsevents != null;
  }
  static _normalizeProxy(callback) {
    return (filepath, stats) => callback(path.normalize(filepath), stats);
  }
  static _recReaddir(
    dir,
    dirCallback,
    fileCallback,
    symlinkCallback,
    endCallback,
    errorCallback,
    ignored
  ) {
    (0, _walker.default)(dir)
      .filterDir(
        (currentDir) => !ignored || !(0, _anymatch.default)(ignored, currentDir)
      )
      .on("dir", FSEventsWatcher._normalizeProxy(dirCallback))
      .on("file", FSEventsWatcher._normalizeProxy(fileCallback))
      .on("symlink", FSEventsWatcher._normalizeProxy(symlinkCallback))
      .on("error", errorCallback)
      .on("end", endCallback);
  }
  constructor(dir, opts) {
    if (!fsevents) {
      throw new Error(
        "`fsevents` unavailable (this watcher can only be used on Darwin)"
      );
    }
    super();
    this.dot = opts.dot || false;
    this.ignored = opts.ignored;
    this.glob = Array.isArray(opts.glob) ? opts.glob : [opts.glob];
    this.doIgnore = opts.ignored
      ? (0, _anymatch.default)(opts.ignored)
      : () => false;
    this.root = path.resolve(dir);
    this.fsEventsWatchStopper = fsevents.watch(this.root, (path) => {
      this._handleEvent(path).catch((error) => {
        this.emit("error", error);
      });
    });
    debug(`Watching ${this.root}`);
    this._tracked = new Set();
    const trackPath = (filePath) => {
      this._tracked.add(filePath);
    };
    this.watcherInitialReaddirPromise = new Promise((resolve) => {
      FSEventsWatcher._recReaddir(
        this.root,
        trackPath,
        trackPath,
        trackPath,
        () => {
          this.emit("ready");
          resolve();
        },
        (...args) => {
          this.emit("error", ...args);
          resolve();
        },
        this.ignored
      );
    });
  }
  async close(callback) {
    await this.watcherInitialReaddirPromise;
    await this.fsEventsWatchStopper();
    this.removeAllListeners();
    await new Promise((resolve) => {
      setTimeout(() => {
        if (typeof callback === "function") {
          callback();
        }
        resolve();
      }, 100);
    });
  }
  async _handleEvent(filepath) {
    const relativePath = path.relative(this.root, filepath);
    try {
      const stat = await _fs.promises.lstat(filepath);
      const type = (0, _common.typeFromStat)(stat);
      if (!type) {
        return;
      }
      if (
        !(0, _common.isIncluded)(
          type,
          this.glob,
          this.dot,
          this.doIgnore,
          relativePath
        )
      ) {
        return;
      }
      const metadata = {
        type,
        modifiedTime: stat.mtime.getTime(),
        size: stat.size,
      };
      if (this._tracked.has(filepath)) {
        this._emit(CHANGE_EVENT, relativePath, metadata);
      } else {
        this._tracked.add(filepath);
        this._emit(ADD_EVENT, relativePath, metadata);
      }
    } catch (error) {
      if (error?.code !== "ENOENT") {
        this.emit("error", error);
        return;
      }
      if (!this._tracked.has(filepath)) {
        return;
      }
      this._emit(DELETE_EVENT, relativePath);
      this._tracked.delete(filepath);
    }
  }
  _emit(type, file, metadata) {
    this.emit(type, file, this.root, metadata);
    this.emit(ALL_EVENT, type, file, this.root, metadata);
  }
  getPauseReason() {
    return null;
  }
}
exports.default = FSEventsWatcher;
