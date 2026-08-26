# App files

[Fork](../FORK.md). I use AI here.

The app stores persistent data in the app storage. This document aims to provide an overview of the purpose and structure of the files stored.

## Current files

The live measurement store is `{databases}/health.db`, a PowerSync local-only SQLite file. See [data-package.md](data-package.md).

App settings (Edadat) live in SharedPreferences. Export, CSV, PDF, XLS, interval, and column settings also live in SharedPreferences (`export`, `csv-export`, `pdf-export`, `xsl-export`, `export-columns`, `intervall-store`).

A leftover `edadat.json` next to the old settings directory is imported into prefs only when `last_version` is still 0 (prefs have not been used yet), then deleted. Later launches skip that copy so a leftover file cannot overwrite live prefs.

After a successful upgrade, the previous measurement file may remain as `{databases}/bp.legacy.db`.

## Exported files

Exporting records as a SQLite DB checkpoints `health.db` then writes that file. Import sniffs tables with read-only sqflite: `Timestamps` is the old `bp.db` layout; a `blood_pressure` table or view is the live PowerSync schema. Unknown files are left untouched.

Settings export is a zip. It contains the SharedPreferences keys above plus an `edadat.json` entry built from the live Edadat controller. Old zips that contain a real `edadat.json` file still import.

When exporting as CSV, the file will use standard platform newlines (`\r\n`) unless configured differently, and a headline with the names of all exported columns delimited by the `,` character. Unlike the config suggests note strings are not always wrapped in `'` characters. Fields without any value are either empty or contain a lowercase `null`.

## Legacy data

### Until the PowerSync cutover

Measurements were in `{databases}/bp.db` through the retired `health_data_store` package (timestamp hub + EAV tables). That file is upserted into `health.db` on each launch until the row-count check passes and the file is renamed to `bp.legacy.db`.

### Until settings moved to SharedPreferences

Export and interval objects were JSON files in the settings directory. `FileSettingsLoader` still understands that layout for zip import.

Edadat lived in `edadat.json` in the same directory. First launch after the prefs cutover copies that map into `SharedPreferencesStorage` and deletes the file.

### Until [#189](https://github.com/derdilla/blood-pressure-monitor-fl/pull/189) and [#195](https://github.com/derdilla/blood-pressure-monitor-fl/pull/195) ([v1.5.5](https://github.com/derdilla/blood-pressure-monitor-fl/tree/v1.5.5))

Settings were stored in Android SharedPreferences as many individual keys. Update code lived in `update_legacy_settings.dart`. Support was dropped in October 2024.

### Until [#332](https://github.com/derdilla/blood-pressure-monitor-fl/pull/332/)

In a `dbPath`/`blood_pressure.db` SQLite3 database a `bloodPressureModel` table contains entries with the blood pressure records and notes including a json representation of the color in the ("needlePin") column.

The `await getDatabasesPath()`/`medicine.intakes` File consists of a plain text csv like representation of medicine intakes.
