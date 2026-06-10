# Changelog

All notable changes to `odoo_view_builder_flutter` are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For extended technical notes on each release see
[`doc/changelog_detail.md`](doc/changelog_detail.md).

---

## [Unreleased]

### Planned
- Search view type editor (`<filter>`, `<group by>`, `<separator>`)
- `<notebook>` / `<page>` visual layout in the form canvas
- Inline domain builder (visual boolean expression editor)
- Compatibility validator blocking/warning UI in the export flow
- Dark mode polish pass
- `freezed` code generation for all domain models

---

## [1.0.0+1] — 2026-06-10

Patch release — resolves `dart pub publish --dry-run` validation errors and
adds an ultra-advanced example application covering every package feature.

### Fixed
- Added `logging: ^1.2.0` to `dependencies` — required by `CrashReporter`,
  `AnalyticsService`, and `main.dart` (fixes 3 pub-validation errors)
- Added `repository` and `homepage` fields to `pubspec.yaml`
- Removed `publish_to: 'none'` to enable pub.dev publishing
- Added `fields` / `editableTree` alias parameters to `OdooView.copyWith()`
  for backward compatibility with test and example code
- Fixed `group.groups` → `group.subGroups` in `OdooCompatibilityValidator`
  (was `String?`, not iterable — caused runtime crash in deep-validation paths)
- Fixed `BoolSettingNotifier.overrideWith` signature for Riverpod 2.6.1
  (`(ref) =>` required)
- Fixed `RenderFlex` overflow in `HomeScreen` side-panel by wrapping `Text`
  in `Flexible(overflow: TextOverflow.ellipsis)`
- Fixed `pumpAndSettle` timeout in `widget_test.dart` — replaced with
  `pump()` because `SharedPreferences._load()` never settles in tests

### Added
- Ultra-advanced example application (`example/`) with 8 demo screens:
  - **Full Form Builder** — all 14 field types, 3 group levels, notebooks,
    live XML preview, copy-to-clipboard, round-trip validation
  - **XML Generation Gallery** — Form / Tree / Kanban / Inherit variants,
    multi-view `generateFile()`, arch-only mode, `validateXml()` check
  - **Validation Dashboard** — `FieldNameValidator`, `XmlStructureValidator`,
    `OdooCompatibilityValidator` for all 5 Odoo versions with issue inspector
  - **Import & Round-Trip** — parse raw Odoo XML, inspect model graph,
    re-generate and diff against original, edit & export
  - **Template Library Browser** — all 10 built-in templates with live
    preview and one-tap clone & edit
  - **Odoo API Live Connect** — connect to a real Odoo 14–18 server, fetch
    live field metadata, build views from live schema
  - **Field & Formatting Helpers** — interactive palette for all 14 field
    types, widget compatibility matrix, `FormattingHelper` demo
  - **Settings & Analytics Inspector** — `SharedPreferences` settings
    viewer, crash log tail, event log viewer

---

## [1.0.0] — 2026-06-10

Initial public release.

### Added

#### Application
- Cross-platform Flutter app targeting Android, iOS, Web, macOS, Windows, Linux
- Material 3 theming with light and dark mode support
- Named route navigation with global `NavigatorKey`
- Full Riverpod 2 state management with `StateNotifierProvider`
- 50-step undo/redo history for all editor actions
- Auto-save to SQLite every 30 seconds (configurable)

#### Visual Editor
- **Form editor** — drag-and-drop fields and groups, group nesting up to 3 levels
- **Tree (list) editor** — column reordering, aggregation (`sum`/`avg`), `optional` columns, `decoration-*` rules
- **Kanban editor** — card section drop zones (header/body/footer), group-by field selection
- 3-panel layout: palette / canvas / properties, responsive to screen width
- Dotted-border drop zones with visual feedback during drag

#### Field Types (14 supported)
`char` · `integer` · `float` · `boolean` · `date` · `datetime` · `text` · `html` · `binary` · `selection` · `many2one` · `many2many` · `one2many` · `reference`

#### XML Pipeline
- `XmlGenerator` — generates standard Odoo module XML via `package:xml` `XmlBuilder`
- `XmlParser` — parses Odoo XML back to `OdooForm` for import
- `XmlValidator` — semantic field/model validation
- `XmlFormatter` — 4-space pretty-print and minify

#### Export
- Download `.xml` file (Downloads on desktop, Documents on mobile, blob on web)
- Copy to clipboard
- Native share sheet (`share_plus`)
- Multi-view batch export with `<odoo><data>` wrapper

#### Import
- Import single or multiple `<record model="ir.ui.view">` from any `.xml` file
- Automatic view type detection from the arch root element

#### Template Library
- 10 built-in templates: Contact Form/List, Sales Order Form/List, Products Kanban, Invoice Form, Employee Form, Blank Form/Tree/Kanban

#### Odoo API Integration
- JSON-RPC session authentication (`/web/session/authenticate`)
- Live field metadata fetch (`fields_get`) from any Odoo 14–18 instance
- API key authentication support

#### Validation
- `FieldNameValidator` — 9 rules (FN001–FN009) including reserved name detection and `autoFix()`
- `XmlStructureValidator` — 19 rules (XS001–XS019) for raw XML structural integrity
- `OdooCompatibilityValidator` — 13 rules (OC001–OC013) for Odoo 14/15/16/17/18 compatibility

#### Analytics & Crash Reporting
- `AnalyticsService` — local event log + optional Firebase Analytics
- `CrashReporter` — local log file + optional Firebase Crashlytics
- `FlutterError.onError` hook, `runZonedGuarded`, isolate error port

#### Local Persistence
- `sqflite` database (`views`, `fields`, `xml_cache` tables)
- `SharedPreferences` for user settings and preferences

#### Helpers & Utilities
- `FieldHelper` — widget compatibility matrix, UI icons/colours, type utilities
- `ValidationHelper` — composable string validators, form/field validators
- `FormattingHelper` — date/size/number/string/filename formatters
- `XmlHelper` — low-level XML string utilities
- String extensions: `capitalize`, `toSnakeCase`, `toOdooFieldName`
- List extensions: `move`, `insertAt`, `removeAt`, `replaceAt`

#### Documentation
- `README.md` — project overview, quick start, features table
- `CHANGELOG.md` — this file
- `doc/architecture.md` — Clean Architecture layers, data flow, design decisions
- `doc/setup.md` — platform setup, Firebase activation, Odoo API config
- `doc/usage_guide.md` — full feature walkthrough, keyboard shortcuts
- `doc/api_reference.md` — complete public API with signatures and error codes
- `doc/contributing.md` — contribution guide, coding standards, PR process
- `doc/changelog_detail.md` — extended technical notes per release
- `doc/roadmap.md` — planned features and version targets

#### Testing
- Unit tests: `OdooField`, `OdooForm`, `OdooGroup`, `XmlGenerator`, `XmlParser`, `XmlValidator`, `FieldNameValidator`, `XmlStructureValidator`, `OdooCompatibilityValidator`, `FieldHelper`, `ValidationHelper`, `FormattingHelper`
- Widget tests: `CanvasArea`, `FieldPalette`, `XmlPreviewWidget`
- Integration test: export round-trip

#### Example App
- `example/` — standalone Flutter app demonstrating core API usage

---

[Unreleased]: https://github.com/Brah-Timo/packages/compare/v1.0.0+1...HEAD
[1.0.0+1]: https://github.com/Brah-Timo/packages/compare/v1.0.0...v1.0.0+1
[1.0.0]: https://github.com/Brah-Timo/packages/releases/tag/v1.0.0
