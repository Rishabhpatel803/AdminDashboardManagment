const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
  ...jestConfig,
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver"],
  moduleNameMapper: {
    // accStyles is a CSS-only LWC module (shared style rules imported with
    // `@import 'c/accStyles'`). The platform compiler resolves this
    // natively, but Jest's generic `c/*` mapping expects a JS module, so
    // point it at the stylesheet directly. Must precede the generic rule.
    "^c/accStyles$":
      "<rootDir>/force-app/main/default/lwc/accStyles/accStyles.css",
    ...jestConfig.moduleNameMapper
  }
};
