# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2021-05-13

### Changed

- Decreased RubyGems version requirement from `>= 2.6` to `>= 2.5`.

## [0.2.0] - 2021-05-11

### Changed

- BREAKING CHANGE: Changed the activation alias from `memorb!` to `memoize`.
- No longer keep a global registry of instance agents to reduce the risk of memory leakage.
- Updated Gemfile source to HTTPS.

### Removed

- Removed undocumented `purge` method.

## [0.1.0] - 2020-06-08

Initial release.
