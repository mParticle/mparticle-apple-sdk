"use strict";

const chalk = require("chalk");
const stripAnsi = require("strip-ansi");
const util = require("util");
function logWarning(terminal, format, ...args) {
  const str = util.format(format, ...args);
  terminal.log("%s %s", chalk.yellow.inverse.bold(" WARN "), str);
}
function logError(terminal, format, ...args) {
  terminal.log(
    "%s %s",
    chalk.red.inverse.bold(" ERROR "),
    util.format(chalk.supportsColor ? format : stripAnsi(format), ...args)
  );
}
function logInfo(terminal, format, ...args) {
  const str = util.format(format, ...args);
  terminal.log("%s %s", chalk.cyan.inverse.bold(" INFO "), str);
}
const nullReporter = {
  update() {},
};
module.exports = {
  logWarning,
  logError,
  logInfo,
  nullReporter,
};
