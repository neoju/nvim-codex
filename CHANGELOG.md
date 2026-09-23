# Changelog

## [1.3.0](https://github.com/neoju/nvim-codex/compare/v1.2.0...v1.3.0) (2026-09-23)


### Features

* add prompt presets and compose boundaries ([713b65e](https://github.com/neoju/nvim-codex/commit/713b65e9f36444f3b54f15d690753256f03d25b7))
* add prompt presets and simplify task parsing ([2e2ac05](https://github.com/neoju/nvim-codex/commit/2e2ac05a2486bb038090d159819197e32c792c62))


### Bug Fixes

* verify fix workflow and deduplicate prompt boundaries ([570bfc1](https://github.com/neoju/nvim-codex/commit/570bfc1cfc55d1ed481ddd1ee56a370dedc42435))

## [1.2.0](https://github.com/neoju/nvim-codex/compare/v1.1.1...v1.2.0) (2026-09-23)


### Features

* add task-based prompt definitions and modifiers ([11e26e6](https://github.com/neoju/nvim-codex/commit/11e26e65d83a5ffc5d814e3092c9f0f6e7cb48fd))
* complete prompt modifiers with trailing space ([c08668a](https://github.com/neoju/nvim-codex/commit/c08668aeb3cd02b9d63719addfa146cc706ac40d))
* enhance prompt commands and completion ([2a1dc08](https://github.com/neoju/nvim-codex/commit/2a1dc08cc024605d4d18ee841c555548ad7a66cc))
* expand prompt commands and completion ([ada1534](https://github.com/neoju/nvim-codex/commit/ada15349d72e4d65ae70a3c7dd081bbf318f97ed))


### Bug Fixes

* submit tmux prompt after trailing command ([36434d8](https://github.com/neoju/nvim-codex/commit/36434d854a4f2eb14fc5855b98f2463a522abec4))

## [1.1.1](https://github.com/neoju/nvim-codex/compare/v1.1.0...v1.1.1) (2026-09-22)


### Bug Fixes

* reject empty [@ask](https://github.com/ask) prompts ([5b64aa9](https://github.com/neoju/nvim-codex/commit/5b64aa976687468da4cc10277e7201acd8b71c11))
* reject empty [@ask](https://github.com/ask) prompts ([d773ec8](https://github.com/neoju/nvim-codex/commit/d773ec89a65c17bfd768754cc5116f25e5db3863))

## [1.1.0](https://github.com/neoju/nvim-codex/compare/v1.0.0...v1.1.0) (2026-09-21)


### Features

* add new config options ([3b9f42d](https://github.com/neoju/nvim-codex/commit/3b9f42d9f4e9be2a583688003805b88fd5857da3))


### Bug Fixes

* tmux commands overlapping ([50d24f9](https://github.com/neoju/nvim-codex/commit/50d24f990622eebdc3e7e3c06e40ac120ae140bb))

## 1.0.0 (2026-09-21)


### ⚠ BREAKING CHANGES

* renew template ([#22](https://github.com/neoju/nvim-codex/issues/22))
* improve template helpers and state manager ([#14](https://github.com/neoju/nvim-codex/issues/14))

### Features

* add doc generation check to CI ([#2](https://github.com/neoju/nvim-codex/issues/2)) ([15d4d14](https://github.com/neoju/nvim-codex/commit/15d4d1462f0bf99349ddd626d8f1a4b1b95f8a14))
* add release script ([144c732](https://github.com/neoju/nvim-codex/commit/144c732b598c01c52f81d89f085ff5a5aefe1a1f))
* add setup script ([#1](https://github.com/neoju/nvim-codex/issues/1)) ([fbffb71](https://github.com/neoju/nvim-codex/commit/fbffb71deea4fafb4e76c5901fa263b155ab8e94))
* **cd:** add release action ([#4](https://github.com/neoju/nvim-codex/issues/4)) ([85cb257](https://github.com/neoju/nvim-codex/commit/85cb257bfe0c2770364541044cfc478cecf58a2a))
* **cd:** remove homemade release script ([#6](https://github.com/neoju/nvim-codex/issues/6)) ([316de3d](https://github.com/neoju/nvim-codex/commit/316de3d10be0f704bdfecde3d889efe9c2e57570))
* **ci:** add luals checks on CI ([#16](https://github.com/neoju/nvim-codex/issues/16)) ([2d0ecc4](https://github.com/neoju/nvim-codex/commit/2d0ecc406f7b8a2c4fab5a7ed83967f6a35cbd5d))
* **ci:** bump stylua ([#18](https://github.com/neoju/nvim-codex/issues/18)) ([d97ea98](https://github.com/neoju/nvim-codex/commit/d97ea98e85fb55a57e2ff9618982261e7d1a33d0))
* improve template helpers and state manager ([#14](https://github.com/neoju/nvim-codex/issues/14)) ([9cc87ad](https://github.com/neoju/nvim-codex/commit/9cc87add9fffd7e54b9f37573ed105f2234c7ccd))
* make setup.sh more reliable ([6c2f360](https://github.com/neoju/nvim-codex/commit/6c2f360be9acd1c747f9cce112c6a0205e76532c))
* renew template ([#22](https://github.com/neoju/nvim-codex/issues/22)) ([ca72698](https://github.com/neoju/nvim-codex/commit/ca726988e6711508ada1ee0e554824827d00e3be))
* template cleanup and improvements ([#11](https://github.com/neoju/nvim-codex/issues/11)) ([af2fcb0](https://github.com/neoju/nvim-codex/commit/af2fcb0ffcac54eb9e4092bb860c22e29d2579dc))


### Bug Fixes

* CI diff documentation ([#9](https://github.com/neoju/nvim-codex/issues/9)) ([c4b9836](https://github.com/neoju/nvim-codex/commit/c4b98367f82a6fe47d7268ac7a3887643831eac8))
* easier replace ([0d686ea](https://github.com/neoju/nvim-codex/commit/0d686eab4a45c4437bfaa3fdf8365de305587dff))
* missing README.md mention ([97b16e0](https://github.com/neoju/nvim-codex/commit/97b16e028283cc7a47421da518cd51c3db206427))
* missing steps in README.md ([6ac7c6f](https://github.com/neoju/nvim-codex/commit/6ac7c6fab61fd9af968ad476161b06406692ca87))
* remove 0.7 nvim support ([99911e6](https://github.com/neoju/nvim-codex/commit/99911e6b5778dc8dc659bca590d17afed937dc3c))
* remove changelog on setup ([2923468](https://github.com/neoju/nvim-codex/commit/2923468a74fcab00e605a6588cfca2bd229808b2))
* test helpers ([d65dd73](https://github.com/neoju/nvim-codex/commit/d65dd73119ec466bdd99d9833f27c4f6a936fe1e))
