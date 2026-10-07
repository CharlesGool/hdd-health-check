---
name: project-third-party-notices
description: Third-party software and asset notices
metadata:
  version: "0.1.0"
  lang: "zh-CN"
---

# 第三方声明

本清单记录可选 Web UI 使用的第三方材料.

## 多语言

**简体中文** | [English](en/THIRD_PARTY_NOTICES.md) | [Español](es/THIRD_PARTY_NOTICES.md)

## 文档

- 项目概览: [README](../README.md)

- 设计思路: [DESIGN](DESIGN.md)

- 项目状态: [LOG](LOG.md)
- 历史记录: [HISTORY](HISTORY.md)
- 变更日志: [CHANGELOG](CHANGELOG.md)

- 第三方声明: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## 第三方声明

### 组件清单

本表按 npm 锁文件列出生产依赖及其传递依赖, 包括构建过程中可能被消除的模块. Vue, Markdown 渲染器, Lucide 图标, Reka UI 控件与样式合并工具用于浏览器前端; Tailwind CSS 仅在构建时生成样式. 当前界面采用系统字体, 不再分发字体文件.

| 组件名称 | 版本或哈希 | 上游地址 | 许可证类型 | 使用方式 | 版权归属 | 发布合规义务 | 核验日期 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| @babel/helper-string-parser | 7.29.7 | [上游](https://github.com/babel/babel) | MIT | npm 前端依赖 | Copyright (c) 2014-present Sebastian McKenzie and other contributors; The above copyright notice and this permission notice shall be | 保留完整许可及声明 | 2026-10-08 |
| @babel/helper-validator-identifier | 7.29.7 | [上游](https://github.com/babel/babel) | MIT | npm 前端依赖 | Copyright (c) 2014-present Sebastian McKenzie and other contributors; The above copyright notice and this permission notice shall be | 保留完整许可及声明 | 2026-10-08 |
| @babel/parser | 7.29.9 | [上游](https://github.com/babel/babel) | MIT | npm 前端依赖 | Copyright (C) 2012-2014 by various contributors (see AUTHORS); The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| @babel/types | 7.29.8 | [上游](https://github.com/babel/babel) | MIT | npm 前端依赖 | Copyright (c) 2014-present Sebastian McKenzie and other contributors; The above copyright notice and this permission notice shall be | 保留完整许可及声明 | 2026-10-08 |
| @floating-ui/core | 1.8.0 | [上游](https://github.com/floating-ui/floating-ui) | MIT | npm 前端依赖 | Copyright (c) 2021-present Floating UI contributors; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| @floating-ui/dom | 1.8.0 | [上游](https://github.com/floating-ui/floating-ui) | MIT | npm 前端依赖 | Copyright (c) 2021-present Floating UI contributors; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| @floating-ui/utils | 0.2.12 | [上游](https://github.com/floating-ui/floating-ui) | MIT | npm 前端依赖 | Copyright (c) 2021-present Floating UI contributors; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| @floating-ui/vue | 2.0.1 | [上游](https://github.com/floating-ui/floating-ui) | MIT | npm 前端依赖 | Copyright (c) 2021 Floating UI contributors; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| @internationalized/date | 3.12.4 | [上游](https://github.com/adobe/react-spectrum/tree/main/packages/@internationalized/date) | Apache-2.0 | npm 前端依赖 |       "Licensor" shall mean the copyright owner or entity authorized by;       the copyright owner that is granting the License. | 保留完整许可及声明 | 2026-10-08 |
| @internationalized/number | 3.6.8 | [上游](https://github.com/adobe/react-spectrum) | Apache-2.0 | npm 前端依赖 |       "Licensor" shall mean the copyright owner or entity authorized by;       the copyright owner that is granting the License. | 保留完整许可及声明 | 2026-10-08 |
| @jridgewell/sourcemap-codec | 1.6.0 | [上游](https://github.com/jridgewell/sourcemaps) | MIT | npm 前端依赖 | Copyright 2024 Justin Ridgewell <justin@ridgewell.name>; The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| @lucide/vue | 1.52.0 | [上游](https://github.com/lucide-icons/lucide) | ISC | npm 前端依赖 | Copyright (c) 2026 Lucide Icons and Contributors; copyright notice and this permission notice appear in all copies. | 保留完整许可及声明 | 2026-10-08 |
| @swc/helpers | 0.5.23 | [上游](https://github.com/swc-project/swc) | Apache-2.0 | npm 前端依赖 |    "Licensor" shall mean the copyright owner or entity authorized by;    the copyright owner that is granting the License. | 保留完整许可及声明 | 2026-10-08 |
| @tanstack/virtual-core | 3.17.11 | [上游](https://github.com/TanStack/virtual) | MIT | npm 前端依赖 | Copyright (c) 2021-present Tanner Linsley; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| @tanstack/vue-virtual | 3.13.39 | [上游](https://github.com/TanStack/virtual) | MIT | npm 前端依赖 | Copyright (c) 2021-present Tanner Linsley; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| @types/web-bluetooth | 0.0.21 | [上游](https://github.com/DefinitelyTyped/DefinitelyTyped) | MIT | npm 前端依赖 |     Copyright (c) Microsoft Corporation.;     The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| @vue/compiler-core | 3.5.43 | [上游](https://github.com/vuejs/core) | MIT | npm 前端依赖 | Copyright (c) 2018-present, Yuxi (Evan) You; The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| entities | 7.0.1 | [上游](https://github.com/fb55/entities) | BSD-2-Clause | npm 前端依赖 | Copyright (c) Felix Böhm; Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. | 保留完整许可及声明 | 2026-10-08 |
| @vue/compiler-dom | 3.5.43 | [上游](https://github.com/vuejs/core) | MIT | npm 前端依赖 | Copyright (c) 2018-present, Yuxi (Evan) You; The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| @vue/compiler-sfc | 3.5.43 | [上游](https://github.com/vuejs/core) | MIT | npm 前端依赖 | Copyright (c) 2018-present, Yuxi (Evan) You; The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| @vue/compiler-ssr | 3.5.43 | [上游](https://github.com/vuejs/core) | MIT | npm 前端依赖 | Copyright (c) 2018-present, Yuxi (Evan) You; The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| @vue/reactivity | 3.5.43 | [上游](https://github.com/vuejs/core) | MIT | npm 前端依赖 | Copyright (c) 2018-present, Yuxi (Evan) You; The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| @vue/runtime-core | 3.5.43 | [上游](https://github.com/vuejs/core) | MIT | npm 前端依赖 | Copyright (c) 2018-present, Yuxi (Evan) You; The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| @vue/runtime-dom | 3.5.43 | [上游](https://github.com/vuejs/core) | MIT | npm 前端依赖 | Copyright (c) 2018-present, Yuxi (Evan) You; The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| @vue/server-renderer | 3.5.43 | [上游](https://github.com/vuejs/core) | MIT | npm 前端依赖 | Copyright (c) 2018-present, Yuxi (Evan) You; The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| @vue/shared | 3.5.43 | [上游](https://github.com/vuejs/core) | MIT | npm 前端依赖 | Copyright (c) 2018-present, Yuxi (Evan) You; The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| @vueuse/core | 14.4.0 | [上游](https://github.com/vueuse/vueuse) | MIT | npm 前端依赖 | Copyright (c) 2019-PRESENT Anthony Fu<https://github.com/antfu>; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| @vueuse/metadata | 14.4.0 | [上游](https://github.com/vueuse/vueuse) | MIT | npm 前端依赖 | Copyright (c) 2019-PRESENT Anthony Fu<https://github.com/antfu>; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| @vueuse/shared | 14.4.0 | [上游](https://github.com/vueuse/vueuse) | MIT | npm 前端依赖 | Copyright (c) 2019-PRESENT Anthony Fu<https://github.com/antfu>; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| argparse | 3.0.2 | [上游](https://github.com/nodeca/argparse) | PSF-2.0 | npm 前端依赖 | provided, however, that PSF's License Agreement and PSF's notice of copyright,; i.e., "Copyright (c) 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, | 保留完整许可及声明 | 2026-10-08 |
| aria-hidden | 1.2.6 | [上游](https://github.com/theKashey/aria-hidden) | MIT | npm 前端依赖 | Copyright (c) 2017 Anton Korzunov; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| class-variance-authority | 0.7.1 | [上游](https://github.com/joe-bell/cva) | Apache-2.0 | npm 前端依赖 |       "Licensor" shall mean the copyright owner or entity authorized by;       the copyright owner that is granting the License. | 保留完整许可及声明 | 2026-10-08 |
| clsx | 2.1.1 | [上游](https://github.com/lukeed/clsx) | MIT | npm 前端依赖 | Copyright (c) Luke Edwards <luke.edwards05@gmail.com> (lukeed.com); The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. | 保留完整许可及声明 | 2026-10-08 |
| csstype | 3.2.3 | [上游](https://github.com/frenic/csstype) | MIT | npm 前端依赖 | Copyright (c) 2017-2018 Fredrik Nicol; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| defu | 6.1.7 | [上游](https://github.com/unjs/defu) | MIT | npm 前端依赖 | Copyright (c) Pooya Parsa <pooya@pi0.io>; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| entities | 8.1.0 | [上游](https://github.com/fb55/entities) | BSD-2-Clause | npm 前端依赖 | Copyright (c) Felix Böhm; Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. | 保留完整许可及声明 | 2026-10-08 |
| estree-walker | 2.0.2 | [上游](https://github.com/Rich-Harris/estree-walker) | MIT | npm 前端依赖 | Copyright (c) 2015-20 [these people](https://github.com/Rich-Harris/estree-walker/graphs/contributors); The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. | 保留完整许可及声明 | 2026-10-08 |
| linkify-it | 6.1.0 | [上游](https://github.com/markdown-it/linkify-it) | MIT | npm 前端依赖 | Copyright (c) 2015 Vitaly Puzrin.; The above copyright notice and this permission notice shall be | 保留完整许可及声明 | 2026-10-08 |
| magic-string | 0.30.21 | [上游](https://github.com/Rich-Harris/magic-string) | MIT | npm 前端依赖 | Copyright 2018 Rich Harris; The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. | 保留完整许可及声明 | 2026-10-08 |
| markdown-it | 15.0.2 | [上游](https://github.com/markdown-it/markdown-it) | MIT | npm 前端依赖 | Copyright (c) 2014 Vitaly Puzrin, Alex Kocharin.; The above copyright notice and this permission notice shall be | 保留完整许可及声明 | 2026-10-08 |
| mdurl | 2.1.0 | [上游](https://github.com/markdown-it/mdurl) | MIT | npm 前端依赖 | Copyright (c) 2015 Vitaly Puzrin, Alex Kocharin.; The above copyright notice and this permission notice shall be | 保留完整许可及声明 | 2026-10-08 |
| nanoid | 3.3.20 | [上游](https://github.com/ai/nanoid) | MIT | npm 前端依赖 | Copyright 2017 Andrey Sitnik <andrey@sitnik.ru>; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| ohash | 2.0.12 | [上游](https://github.com/unjs/ohash) | MIT | npm 前端依赖 | Copyright (c) Pooya Parsa <pooya@pi0.io>; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| picocolors | 1.1.1 | [上游](https://github.com/alexeyraspopov/picocolors) | ISC | npm 前端依赖 | Copyright (c) 2021-2024 Oleksii Raspopov, Kostiantyn Denysov, Anton Verinov; copyright notice and this permission notice appear in all copies. | 保留完整许可及声明 | 2026-10-08 |
| postcss | 8.5.29 | [上游](https://github.com/postcss/postcss) | MIT | npm 前端依赖 | Copyright 2013 Andrey Sitnik <andrey@sitnik.es>; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| punycode.js | 2.3.1 | [上游](https://github.com/mathiasbynens/punycode.js) | MIT | npm 前端依赖 | Copyright Mathias Bynens <https://mathiasbynens.be/>; The above copyright notice and this permission notice shall be | 保留完整许可及声明 | 2026-10-08 |
| reka-ui | 2.11.0 | [上游](https://github.com/unovue/reka-ui) | MIT | npm 前端依赖 | Copyright (c) 2023 UnoVue <https://github.com/unovue>; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| source-map-js | 1.2.2 | [上游](https://github.com/7rulnik/source-map-js) | BSD-3-Clause | npm 前端依赖 | Copyright (c) 2009-2011, Mozilla Foundation and contributors; * Redistributions of source code must retain the above copyright notice, this | 保留完整许可及声明 | 2026-10-08 |
| tailwind-merge | 3.7.0 | [上游](https://github.com/dcastil/tailwind-merge) | MIT | npm 前端依赖 | Copyright (c) 2021 Dany Castillo; The above copyright notice and this permission notice shall be included in all | 保留完整许可及声明 | 2026-10-08 |
| tslib | 2.8.1 | [上游](https://github.com/Microsoft/tslib) | 0BSD | npm 前端依赖 | Copyright (c) Microsoft Corporation. | 保留完整许可及声明 | 2026-10-08 |
| typescript | 5.9.3 | [上游](https://github.com/microsoft/TypeScript) | Apache-2.0 | npm 前端依赖 | "Licensor" shall mean the copyright owner or entity authorized by the copyright owner that is granting the License.; "Work" shall mean the work of authorship, whether in Source or Object form, made available under the License, as indicated by a copyright notice that is included in or attached to the work (an example is provided in the Appendix below). | 保留完整许可及声明 | 2026-10-08 |
| uc.micro | 3.0.0 | [上游](https://github.com/markdown-it/uc.micro) | MIT | npm 前端依赖 | Copyright Mathias Bynens <https://mathiasbynens.be/>; The above copyright notice and this permission notice shall be | 保留完整许可及声明 | 2026-10-08 |
| vue | 3.5.43 | [上游](https://github.com/vuejs/core) | MIT | npm 前端依赖 | Copyright (c) 2018-present, Yuxi (Evan) You; The above copyright notice and this permission notice shall be included in | 保留完整许可及声明 | 2026-10-08 |
| Tailwind CSS | 4.3.3 | [上游](https://github.com/tailwindlabs/tailwindcss) | MIT | 构建样式 | Tailwind Labs, Inc. | 保留许可 | 2026-10-08 |

### 许可证文本

- [完整依赖许可与声明](../src/web/public/licenses/Dependencies.txt), 自动汇总本次安装的 npm 包内原文, 随生产 UI 的 `/licenses/Dependencies.txt` 分发.
- [Tailwind CSS 原文](../src/web/public/licenses/Tailwind-CSS-MIT.txt).
- `src/web/public/licenses/` 中保留此前版本的许可文本, 旧字体文件不属于当前构建输出.

### 源代码提供

依赖的确切版本及完整性哈希记录在 `src/web/package-lock.json`; 上游地址列于表中. 当前生产依赖不要求提供项目源码. 主机单独安装的 `smartctl`, `lsblk`, `dd`, `badblocks` 和 systemd 不随本仓库或前端包分发.

### 合规审查

本次生产清单为 MIT, ISC, BSD 和 Apache 等许可, 没有随包分发的 Copyleft 依赖. npm 包原文中的版权及 NOTICE 与许可一起保存. 项目自身的 [MIT 许可证](../LICENSE) 与第三方许可独立.
