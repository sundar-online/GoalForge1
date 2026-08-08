{
  "env": {
    "es6": true,
    "node": true
  },
  "parserOptions": {
    "ecmaVersion": 2020
  },
  "extends": ["eslint:recommended", "google"],
  "rules": {
    "max-len": ["warn", { "code": 120 }],
    "quotes": ["error", "double"],
    "no-unused-vars": ["warn"]
  }
}
