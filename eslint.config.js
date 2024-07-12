import globals from 'globals'

import babelParser from '@babel/eslint-parser'
import eslintPluginPrettierRecommended from 'eslint-plugin-prettier/recommended'
import unusedImports from 'eslint-plugin-unused-imports'

export default [
  {
    ignores: ['**/node_modules/**', '**/tests/**', '**/*.pub'],
    languageOptions: {
      globals: { ...globals.node },
      ecmaVersion: 'latest',
      parser: babelParser,
      parserOptions: {
        requireConfigFile: false,
        presets: [['@babel/preset-env', { shippedProposals: true, targets: { node: 'current' } }]],
      },
    },
    rules: {
      'arrow-body-style': 'off',
      'comma-dangle': ['error', 'only-multiline'],
      complexity: ['warn', { max: 20 }],
      indent: 'off',
      'no-await-in-loop': 'error',
      'no-console': 'warn',
      'no-dupe-keys': 'error',
      'no-empty': 'error',
      'no-extend-native': ['error', { exceptions: ['RegExp'] }],
      'no-invalid-regexp': 'error',
      'no-redeclare': 'error',
      'no-return-assign': 'error',
      'no-self-assign': 'warn',
      'no-self-compare': 'warn',
      'no-undef': 'error',
      'no-unused-vars': 'off',
      quotes: ['error', 'single', { allowTemplateLiterals: true }],
      'prefer-arrow-callback': 'warn',
      'prettier/prettier': 'warn',
      'space-before-function-paren': [
        'error',
        { anonymous: 'always', named: 'never', asyncArrow: 'always' },
      ],
      'unused-imports/no-unused-imports': 'error',
      'unused-imports/no-unused-vars': [
        'warn',
        {
          vars: 'all',
          varsIgnorePattern: '^(_|fun|mod|err)$',
          args: 'after-used',
          argsIgnorePattern: '^(_|req|reply|res|next|fun|mod|err)$',
        },
      ],
    },
    plugins: { 'unused-imports': unusedImports },
  },
  eslintPluginPrettierRecommended,
]
