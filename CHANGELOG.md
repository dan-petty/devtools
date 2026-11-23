# Changelog

## [1.1.1](https://github.com/dan-petty/devtools/compare/v1.1.0...v1.1.1) (2026-11-23)


### Bug Fixes

* **deps:** update @devcontainers/cli to v0.91.0 ([#46](https://github.com/dan-petty/devtools/issues/46)) ([68f8555](https://github.com/dan-petty/devtools/commit/68f855522c2f4331396637503b214faf84f6c478))

## [1.1.0](https://github.com/dan-petty/devtools/compare/v1.0.0...v1.1.0) (2026-11-22)


### Features

* **image:** add the copier program ([#43](https://github.com/dan-petty/devtools/issues/43)) ([a8dfd73](https://github.com/dan-petty/devtools/commit/a8dfd737f25c9f21fbd66fc82a0ea8e8454ac3de))

## 1.0.0 (2026-11-22)


### Features

* build and publish the devtools image from debian sid ([#3](https://github.com/dan-petty/devtools/issues/3)) ([5f04251](https://github.com/dan-petty/devtools/commit/5f04251f360e037ba2f19a76e57eaace43ecb6dd))
* **ci:** version the image with release-please and semver ([#38](https://github.com/dan-petty/devtools/issues/38)) ([e1defdd](https://github.com/dan-petty/devtools/commit/e1defddb4cfe8e8a0e5f7dc178cdaf5313e42a66)), closes [#37](https://github.com/dan-petty/devtools/issues/37)


### Bug Fixes

* **ci:** annotate the image index with its description ([#27](https://github.com/dan-petty/devtools/issues/27)) ([860e1b2](https://github.com/dan-petty/devtools/commit/860e1b2770dcae515fe619c1800ea2731f10d520)), closes [#19](https://github.com/dan-petty/devtools/issues/19)
* **ci:** give each publish a tag that never moves ([#28](https://github.com/dan-petty/devtools/issues/28)) ([f6d4f81](https://github.com/dan-petty/devtools/commit/f6d4f817b139bda31c14b2461cb547120dc4d0fd)), closes [#17](https://github.com/dan-petty/devtools/issues/17)
* **deps:** ignore GHSA-53pm-wgxf-c6qf of wcmatch until 2026-11-24 ([#31](https://github.com/dan-petty/devtools/issues/31)) ([9a0da8a](https://github.com/dan-petty/devtools/commit/9a0da8ac1500d32366936f6f0f4a4ded4869189f)), closes [#2](https://github.com/dan-petty/devtools/issues/2)
* **deps:** ignore GHSA-qx49-fqc8-xw99 of mcp 1.29.0 until 2026-11-22 ([#10](https://github.com/dan-petty/devtools/issues/10)) ([fd3e768](https://github.com/dan-petty/devtools/commit/fd3e7683b3fa4163e81b98708dcc0b4f132cd706))
* **image:** install make for the task runners of the repositories ([#34](https://github.com/dan-petty/devtools/issues/34)) ([584cef0](https://github.com/dan-petty/devtools/commit/584cef0781ad53698f45a2648956f8a566b221dc))
* **image:** stop the mise install tracking of the build ([#24](https://github.com/dan-petty/devtools/issues/24)) ([9084b1a](https://github.com/dan-petty/devtools/commit/9084b1acca5c4b6e78e07aa7e81513ff53e1ee97)), closes [#20](https://github.com/dan-petty/devtools/issues/20)
* **security:** stop passing a write credential into the build ([#23](https://github.com/dan-petty/devtools/issues/23)) ([4f4a85e](https://github.com/dan-petty/devtools/commit/4f4a85ebe4f90f1a9697a0dcdc9dc5b5bcb74f0d)), closes [#18](https://github.com/dan-petty/devtools/issues/18)
