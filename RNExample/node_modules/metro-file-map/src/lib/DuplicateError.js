"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true,
});
exports.DuplicateError = void 0;
class DuplicateError extends Error {
  constructor(mockPath1, mockPath2) {
    super("Duplicated files or mocks. Please check the console for more info");
    this.mockPath1 = mockPath1;
    this.mockPath2 = mockPath2;
  }
}
exports.DuplicateError = DuplicateError;
