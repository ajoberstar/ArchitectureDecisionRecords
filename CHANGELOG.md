# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_None_

## [1.0.0] - 2022-08-13

### Enhancements

- Add MIT license (mistakenly left off a LICENSE file in earlier versions)

## [0.2.1] - 2022-02-15

### Enhancements

- Adds `-Target` parameter to `Initialize-Adr` allowing you to set the `.adr-dir` immediately
- Add example to help for `Add-AdrLink`

### Fixes

- Fix support of PowerShell 5.1 by falling back to `ASCII` encoding (instead of `UTF8NoBOM`) on that version
- Removed stray `}` inserted into ADR when using `Add-AdrLink` -- thanks to [Patrice Tremblay](https://github.com/Hummer311)

## [0.1.1] - 2018-07-01

### Fixes

- Fixed module manifest

## [0.1.0] - 2018-07-01

Initial release

[unreleased]: https://github.com/ajoberstar/ArchitectureDecisionRecords/compare/1.0.0...main
[1.0.0]: https://github.com/ajoberstar/ArchitectureDecisionRecords/compare/0.2.1...1.0.0
[0.2.1]: https://github.com/ajoberstar/ArchitectureDecisionRecords/compare/0.1.1...0.2.1
[0.1.1]: https://github.com/ajoberstar/ArchitectureDecisionRecords/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/ajoberstar/ArchitectureDecisionRecords/releases/tag/0.1.0
