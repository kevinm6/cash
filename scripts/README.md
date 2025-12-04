# Localization Manager

## Overview
This script automates the identification and completion of missing localizations for Cash App.
It reads the project's `Localizable.xcstrings` (source language = English) and:

- Detects keys missing in the target languages (it, fr, de, es)
- Copies format/pattern keys (percent-format specifiers, symbols, currency codes, etc.) as-is
- Translates text strings using `deep-translator` (Google Translate) in batches for speed
- Preserves format specifiers during translations
- Writes updates to the `Localizable.xcstrings` file (unless you use `--dry-run`)

## Features
- Batch translation to speed up API usage
- tqdm progress bar to show progress during translation
- Detailed logging to an optional file
- Export missing keys as JSON for manual review

## Prerequisites
- Python 3.8+ (the repo uses a venv at `.venv`)
- An environment with `deep-translator` and `tqdm` installed

## Install
Create and activate a virtual environment then install dependencies (recommended):

```bash
# From repository root:
python -m venv .venv
source .venv/bin/activate
python -m pip install -U pip
python -m pip install deep-translator tqdm
```

## Usage
The script is located at `scripts/localization_manager.py`. The following examples assume you're in the repository root.

Analyze and display a summary (no changes):

```bash
python scripts/localization_manager.py --analyze
```

Verbose analysis (show up to 20 missing keys per language):

```bash
python scripts/localization_manager.py --analyze --verbose
```

Export missing keys for manual review to `missing.json`:

```bash
python scripts/localization_manager.py --export missing.json
```

Dry-run translation for French only (will not save changes):

```bash
python scripts/localization_manager.py --translate --language fr --dry-run --verbose
```

Translate and save translations for all supported languages (writes to `Localizable.xcstrings`):

```bash
python scripts/localization_manager.py --translate
```

Translate a single language and save, writing logs to `fr_translation.log`:

```bash
python scripts/localization_manager.py --translate --language fr --log fr_translation.log
```

## Options
`--dry-run` (or `-n`): Do not write changes to the `Localizable.xcstrings`. Useful to preview translations.
`--verbose` (or `-v`): Enable debug-level logging to stdout and log file if provided.
`--language` (or `-l`): Process a single language (e.g. `--language fr`). If omitted, the script processes `it`, `fr`, `de`, and `es`.
`--export` (or `-e`): Export a JSON report of missing keys for the specified languages.
`--file` (or `-f`): Use a custom path to `Localizable.xcstrings`.
`--log`: Specify a custom log file. If omitted and `--translate` is used, a timestamped default is created.

## Technical details
- The script treats some keys as "patterns" and copies them to the target language without translation. Patterns include purely formatting strings (e.g. `%@`, `-`, currency codes, `%lld`), punctuation strings, numbers, or symbols.
- Strings containing format specifiers (e.g. `%@`, `%1$@`, `%lld`) are protected during translation: we replace specifiers with placeholders, translate the rest, and restore specifiers afterward.
- The script uses `deep-translator`'s Google translator for translation. For high-volume or production usage, consider using a paid translation API (Google Cloud Translation, DeepL, etc.) for reliability, or add rate-limiting/backoff.
- Batch size is currently set to 50 strings per batch. You can tune `BATCH_SIZE` inside `scripts/localization_manager.py` for speed vs. API limits.

## Best practices
- Run with `--dry-run` to preview changes.
- Run `--export` to create an audit-friendly report of entries that will be modified.
- Keep a copy of `Localizable.xcstrings` before running a full translation pass (or use git commit/branch to revert if needed).
- Review translations manually for accuracy, especially where placeholders or domain-specific words are used.

## Acknowledgements

This script was created to help finalize localizations for Cash App.

If you want enhancements later (e.g., custom translation provider, string selection filters), open a new issue or PR in the repository.
