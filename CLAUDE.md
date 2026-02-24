# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AmiKo/CoMed for macOS — a Swiss medical application for healthcare professionals. Manages medication information (AIPS compendium), drug interactions, prescriptions, and patient data. Built entirely in Objective-C targeting macOS 10.12+. Licensed under GPLv3.0 (ywesee GmbH).

Two build targets exist: **AmiKo Desitin** (German-oriented) and **CoMed Desitin** (French-oriented), sharing the same codebase with different branding/assets.

## Build Commands

### Prerequisites — Download Databases

Databases must be placed in `AmiKoOSX/` before building:

```bash
cd AmiKoOSX
for f in amiko_db_full_idx_de amiko_db_full_idx_fr amiko_frequency_de.db amiko_frequency_fr.db; do
  curl -O http://pillbox.oddb.org/${f}.zip && unzip ${f}.zip && rm ${f}.zip
done
for f in drug_interactions_csv_de drug_interactions_csv_fr; do
  curl -O http://pillbox.oddb.org/${f}.zip && unzip ${f}.zip && rm ${f}.zip
done
curl -o amiko_report_de.html http://pillbox.oddb.org/amiko_report_de.html
curl -o amiko_report_fr.html http://pillbox.oddb.org/amiko_report_fr.html
```

### Credential Files

Copy sample credential headers before building:
```bash
cp HINClient/MLHINClientCredential.sample.h HINClient/MLHINClientCredential.h
cp Medidata/MedidataCredential.sample.h Medidata/MedidataCredential.h
```

### Sign Certifaction Binaries

```bash
cd HINClient
codesign -s - -i "amikoosx.certifaction" --entitlements Certifaction.entitlements -f ./certifaction-arm64
codesign -s - -i "amikoosx.certifaction" --entitlements Certifaction.entitlements -f ./certifaction-x86
```

### Build

```bash
# Build AmiKo (without code signing)
xcodebuild clean build -project AmiKo.xcodeproj -scheme AmiKo CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# Build CoMed (without code signing)
xcodebuild clean build -project AmiKo.xcodeproj -scheme CoMed CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
```

Full automated build/archive/upload: `cd scripts && ./build.sh`

### Tests

No unit test suite exists. CI uses GitHub Actions (`.github/workflows/build.yml`) to verify both targets compile. CodeQL analysis runs via `.github/workflows/codeql.yml`.

## Architecture

### App Lifecycle

`main.m` → `MLAppDelegate` → `MLMainWindowController` (primary UI controller, manages all tabs and search).

### Main Window Tabs

The main window (`MLAmiKoMainWindow.xib`) switches between four modes controlled by `MLMainWindowController`:
- **Compendium** (`kAips`) — medication database search and expert info display
- **Favorites** (`kFavorites`) — starred medications
- **Interactions** (`kInteractions`) — drug interaction checker
- **Prescriptions** — prescription creation/management via `MLPrescriptionView`

Search states: `kTitle`, `kAuthor`, `kAtcCode`, `kRegNr`, `kTherapy`, `kWebView`, `kFullText`.

### Data Layer

**SQLite databases** (embedded, downloaded at build time):
- `MLDBAdapter` — queries the AIPS medication database
- `MLFullTextDBAdapter` — full-text search across medication info
- `MLInteractionsAdapter` — drug-drug interaction lookups
- `MLPrescriptionsAdapter` — prescription file management (`.amk` format, base64-encoded JSON)

**Core Data + CloudKit**:
- `MLPersistenceManager` — central persistence for patient data
- `MLPatientSync` / `MLiCloudToLocalMigration` — iCloud sync and migration
- `PatientModel+CoreDataClass` — generated Core Data entity

### Model Classes

- `MLMedication` — medication record (name, ATC, packages, content)
- `MLPatient` — patient demographics, insurance, health card data
- `MLOperator` — prescribing doctor information
- `MLPrescriptionItem` — single item in a prescription

### External Integrations

**HIN Client** (`HINClient/`): OAuth2-based e-prescription system for Swiss healthcare. Uses SAML auth (`MLHINADSwissSaml`), token management (`MLHINTokens`), and Certifaction binaries (arm64 + x86) for encryption. URL schemes: `amiko://` and `comed://` for OAuth redirects.

**Medidata** (`Medidata/`): Invoice generation/upload system. `MedidataXMLGenerator` produces XSD-validated XML invoices (`generalInvoiceRequest_450.xsd`). `MedidataClient` handles HTTP communication.

**Smart Card Reader**: `HealthCard` class reads patient insurance cards via `CryptoTokenKit.framework`. Data published via NSNotification.

**macOS Contacts**: `MLContacts` imports patients from the system address book.

### UI Layer

All UI is XIB-based (no storyboards). Key XIB files:
- `MLAmiKoMainWindow.xib` — main window (156KB, all primary controls)
- `MLAmiKoPatientSheet.xib` — patient management sheet
- `MLAmiKoOperatorIDSheet.xib` — doctor ID form

Medication detail views use `MLCustomWebView` (WebKit) with `WebViewJavascriptBridge` for JS↔ObjC communication. CSS supports both light and dark mode.

### Localization

Three languages: German (`de.lproj`), English (`en.lproj`), French (`fr.lproj`). Language detection via `MLUtilities` (`appLanguage`, `isGermanApp`, `isFrenchApp`). AmiKo defaults to German, CoMed to French.

## Code Conventions

- All classes use the `ML` prefix (e.g., `MLDBAdapter`, `MLPatient`)
- Instance variables prefixed with `m` (e.g., `mTableView`)
- Constants use `UPPER_SNAKE_CASE` (e.g., `KEY_AMK_PAT_ID`)
- String properties use `copy` semantics
- No third-party dependency managers — all dependencies are system frameworks or bundled source (`SSZipArchive`, `minizip`, `WebViewJavascriptBridge`)
