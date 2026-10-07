---
name: project-third-party-notices-ar
description: Third-party software and asset notices
metadata:
  version: "0.1.0"
  lang: "ar"
---

# إشعارات الأطراف الثالثة

تسجّل هذه القائمة مواد الأطراف الثالثة التي تستخدمها واجهة Web الاختيارية.

## تعدد اللغات

[English](../en/THIRD_PARTY_NOTICES.md) | [简体中文](../THIRD_PARTY_NOTICES.md) | [繁體中文(台灣)](../zh-TW/THIRD_PARTY_NOTICES.md) | [繁體中文(香港)](../zh-HK/THIRD_PARTY_NOTICES.md) | [हिन्दी](../hi/THIRD_PARTY_NOTICES.md) | [Español](../es/THIRD_PARTY_NOTICES.md) | **العربية** | [Français](../fr/THIRD_PARTY_NOTICES.md)

## الوثائق

- نظرة عامة على المشروع: [README](README.md)

- مبررات التصميم: [DESIGN](DESIGN.md)

- سجل الإصدارات: [LOG](LOG.md)

- إشعارات الجهات الخارجية: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## إشعارات الجهات الخارجية

تضم حزمة Web إطار Vue (MIT), ومكتبة markdown-it (MIT), وأيقونات Lucide (ISC), ومخرجات Tailwind CSS (MIT). وتستضيف خطوط Inter وNoto Sans SC وNoto Sans Arabic وNoto Sans Devanagari محليًا بموجب ترخيص SIL Open Font License 1.1. تتوفر نصوص تراخيص Vue وTailwind CSS وmarkdown-it والأيقونات والخطوط في `src/web/public/licenses/` وتُضمّن في الواجهة المبنية. تُسجّل اعتماديات البناء وإصداراتها الدقيقة في `src/web/package-lock.json`.

تُوفَّر أدوات النظام المستخدمة أثناء التشغيل (`smartctl`, `lsblk`, `dd`, `badblocks`, `systemd-run`) منفصلةً من المضيف ولا يوزعها هذا المستودع. ولا يدّعي المشروع هنا نيابةً عنها وجود ترخيص أو إسناد إلى المصدر الأصلي. [ترخيص MIT](../../LICENSE) الخاص بالمشروع منفصل عنها.
