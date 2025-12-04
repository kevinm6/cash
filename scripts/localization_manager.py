#!/usr/bin/env python3
"""
Localization Manager for Cash App
================================

This script analyzes and manages localizations in the Localizable.xcstrings file.

Features:
1. Analyzes keys from the source language (en) and identifies missing translations
2. For patterns/formatting strings, copies them directly to the target language
3. For text strings, translates them using Google Translate API (batch mode for speed)

Usage:
    python localization_manager.py --analyze          # Analyze missing translations
    python localization_manager.py --translate        # Translate missing strings
    python localization_manager.py --dry-run          # Preview changes without saving
    python localization_manager.py --language fr      # Process only French

Author: Cash App Team
Date: December 2024
"""

import json
import re
import argparse
import sys
import logging
from pathlib import Path
from typing import Optional
from dataclasses import dataclass, field
from datetime import datetime

# Try to import tqdm for progress bar
try:
    from tqdm import tqdm

    TQDM_AVAILABLE = True
except ImportError:
    TQDM_AVAILABLE = False

# Try to import deep_translator for translation
try:
    from deep_translator import GoogleTranslator

    TRANSLATOR_AVAILABLE = True
except ImportError:
    TRANSLATOR_AVAILABLE = False


# Configure logging
def setup_logging(log_file: Optional[str] = None, verbose: bool = False):
    """Setup logging configuration."""
    log_format = "%(asctime)s [%(levelname)s] %(message)s"
    date_format = "%Y-%m-%d %H:%M:%S"

    level = logging.DEBUG if verbose else logging.INFO

    handlers = [logging.StreamHandler(sys.stdout)]

    if log_file:
        handlers.append(logging.FileHandler(log_file, encoding="utf-8"))

    logging.basicConfig(
        level=level, format=log_format, datefmt=date_format, handlers=handlers
    )

    return logging.getLogger(__name__)


logger = logging.getLogger(__name__)


@dataclass
class LocalizationStats:
    """Statistics for a single language."""

    language: str
    total_keys: int = 0
    translated: int = 0
    missing: int = 0
    patterns_copied: int = 0
    texts_translated: int = 0
    errors: int = 0
    missing_keys: list = field(default_factory=list)


@dataclass
class TranslationTask:
    """A single translation task."""

    key: str
    source_value: str
    is_pattern: bool
    has_specifiers: bool
    string_data: dict


class LocalizationManager:
    """Manages localizations for the Cash App."""

    TARGET_LANGUAGES = ["it", "fr", "de", "es"]
    SOURCE_LANGUAGE = "en"
    BATCH_SIZE = 50  # Number of strings to translate in one batch

    # Patterns that should be copied as-is
    COPY_PATTERNS = [
        r"^[\s]*$",
        r"^[%@\d\.\-\+\/\#\•\→\←]+$",
        r"^%[@lld]+$",
        r"^%\d*\$?[@lld]+$",
        r"^[\(\)\[\]\{\}]+$",
        r"^\d+(\.\d+)?$",
        r"^[©®™]+.*\d{4}",
        r"^https?://",
        r"^[A-Z]{2,3}$",
        r"^\d+(\.\d+)?%$",
    ]

    FORMAT_SPECIFIERS = [
        r"%@",
        r"%\d*\$?@",
        r"%lld",
        r"%\d*\$?lld",
        r"%d",
        r"%\d*\$?d",
        r"%f",
        r"%\d*\.\d*f",
        r"%%",
    ]

    def __init__(self, xcstrings_path: str):
        """Initialize the manager."""
        self.xcstrings_path = Path(xcstrings_path)
        self.data: dict = {}
        self.translators: dict = {}

    def load(self) -> bool:
        """Load the xcstrings file."""
        try:
            with open(self.xcstrings_path, "r", encoding="utf-8") as f:
                self.data = json.load(f)
            logger.info(f"✅ Loaded {self.xcstrings_path}")
            return True
        except FileNotFoundError:
            logger.error(f"❌ File not found: {self.xcstrings_path}")
            return False
        except json.JSONDecodeError as e:
            logger.error(f"❌ Invalid JSON: {e}")
            return False

    def save(self) -> bool:
        """Save the xcstrings file."""
        try:
            with open(self.xcstrings_path, "w", encoding="utf-8") as f:
                json.dump(self.data, f, ensure_ascii=False, indent=2)
            logger.info(f"✅ Saved {self.xcstrings_path}")
            return True
        except Exception as e:
            logger.error(f"❌ Error saving file: {e}")
            return False

    def is_pattern_only(self, key: str) -> bool:
        """Check if a key is a pattern that should be copied as-is."""
        for pattern in self.COPY_PATTERNS:
            if re.match(pattern, key):
                return True
        return False

    def has_format_specifiers(self, text: str) -> bool:
        """Check if text contains format specifiers."""
        for pattern in self.FORMAT_SPECIFIERS:
            if re.search(pattern, text):
                return True
        return False

    def get_source_value(self, key: str, string_data: dict) -> str:
        """Get the source (English) value for a key."""
        localizations = string_data.get("localizations", {})
        if self.SOURCE_LANGUAGE in localizations:
            en_data = localizations[self.SOURCE_LANGUAGE]
            if "stringUnit" in en_data:
                return en_data["stringUnit"].get("value", key)
        return key

    def is_translated(self, string_data: dict, language: str) -> bool:
        """Check if a string is translated for a given language."""
        localizations = string_data.get("localizations", {})
        if language not in localizations:
            return False
        lang_data = localizations[language]
        if "stringUnit" not in lang_data:
            return False
        state = lang_data["stringUnit"].get("state", "")
        return state == "translated"

    def analyze(self, languages: Optional[list] = None) -> dict[str, LocalizationStats]:
        """Analyze missing translations for each language."""
        if not self.data:
            logger.error("❌ No data loaded. Call load() first.")
            return {}

        target_langs = languages or self.TARGET_LANGUAGES
        strings = self.data.get("strings", {})
        stats = {lang: LocalizationStats(language=lang) for lang in target_langs}

        for key, string_data in strings.items():
            if not key.strip():
                continue
            for lang in target_langs:
                stats[lang].total_keys += 1
                if self.is_translated(string_data, lang):
                    stats[lang].translated += 1
                else:
                    stats[lang].missing += 1
                    stats[lang].missing_keys.append(key)

        return stats

    def print_analysis(
        self, stats: dict[str, LocalizationStats], verbose: bool = False
    ):
        """Print analysis results."""
        print("\n" + "=" * 60)
        print("📊 LOCALIZATION ANALYSIS REPORT")
        print("=" * 60)

        for lang, stat in stats.items():
            percentage = (
                (stat.translated / stat.total_keys * 100) if stat.total_keys > 0 else 0
            )
            print(f"\n🌍 {lang.upper()} ({self._get_language_name(lang)})")
            print(f"   Total keys:     {stat.total_keys}")
            print(f"   Translated:     {stat.translated} ({percentage:.1f}%)")
            print(f"   Missing:        {stat.missing}")

            bar_width = 30
            filled = int(bar_width * percentage / 100)
            bar = "█" * filled + "░" * (bar_width - filled)
            print(f"   Progress:       [{bar}] {percentage:.1f}%")

            if verbose and stat.missing_keys:
                print(
                    f"\n   Missing keys ({min(20, len(stat.missing_keys))} of {len(stat.missing_keys)}):"
                )
                for key in stat.missing_keys[:20]:
                    display_key = key[:50] + "..." if len(key) > 50 else key
                    key_type = "📋" if self.is_pattern_only(key) else "📝"
                    print(f"      {key_type} {display_key}")
                if len(stat.missing_keys) > 20:
                    print(f"      ... and {len(stat.missing_keys) - 20} more")

        print("\n" + "=" * 60)
        print("Legend: 📋 = Pattern (copy as-is), 📝 = Text (needs translation)")
        print("=" * 60)

    def _get_language_name(self, code: str) -> str:
        """Get the full name of a language from its code."""
        names = {
            "en": "English",
            "it": "Italian",
            "fr": "French",
            "de": "German",
            "es": "Spanish",
            "pt-PT": "Portuguese",
            "nl": "Dutch",
        }
        return names.get(code, code)

    def _get_translator(self, target_lang: str) -> GoogleTranslator:
        """Get or create a translator for the target language."""
        lang_map = {"pt-PT": "pt"}
        dest = lang_map.get(target_lang, target_lang)

        if dest not in self.translators:
            self.translators[dest] = GoogleTranslator(source="en", target=dest)
        return self.translators[dest]

    def _protect_format_specifiers(self, text: str) -> tuple[str, list]:
        """Replace format specifiers with placeholders."""
        specifier_pattern = r"(%\d*\$?[@lld]+|%%)"
        specifiers = re.findall(specifier_pattern, text)

        if not specifiers:
            return text, []

        protected_text = text
        placeholders = []
        for i, spec in enumerate(specifiers):
            placeholder = f"⟨{i}⟩"  # Use special brackets that won't be translated
            placeholders.append((placeholder, spec))
            protected_text = protected_text.replace(spec, placeholder, 1)

        return protected_text, placeholders

    def _restore_format_specifiers(self, text: str, placeholders: list) -> str:
        """Restore format specifiers from placeholders."""
        result = text
        for placeholder, spec in placeholders:
            result = result.replace(placeholder, spec)
        return result

    def translate_batch(
        self, texts: list[str], target_lang: str
    ) -> list[Optional[str]]:
        """Translate a batch of texts at once."""
        if not TRANSLATOR_AVAILABLE or not texts:
            return [None] * len(texts)

        try:
            translator = self._get_translator(target_lang)

            # Protect format specifiers
            protected_texts = []
            all_placeholders = []
            for text in texts:
                protected, placeholders = self._protect_format_specifiers(text)
                protected_texts.append(protected)
                all_placeholders.append(placeholders)

            # Batch translate
            results = translator.translate_batch(protected_texts)

            # Restore format specifiers
            final_results = []
            for i, result in enumerate(results):
                if result and all_placeholders[i]:
                    result = self._restore_format_specifiers(
                        result, all_placeholders[i]
                    )
                final_results.append(result)

            return final_results

        except Exception as e:
            logger.error(f"Batch translation error: {e}")
            return [None] * len(texts)

    def process_missing_translations(
        self,
        languages: Optional[list] = None,
        dry_run: bool = False,
        verbose: bool = True,
    ) -> dict[str, LocalizationStats]:
        """Process missing translations with batch translation and progress bar."""
        if not self.data:
            logger.error("❌ No data loaded. Call load() first.")
            return {}

        target_langs = languages or self.TARGET_LANGUAGES
        strings = self.data.get("strings", {})
        stats = {lang: LocalizationStats(language=lang) for lang in target_langs}

        for lang in target_langs:
            logger.info(
                f"\n🌍 Processing {lang.upper()} ({self._get_language_name(lang)})..."
            )

            # Collect tasks
            tasks: list[TranslationTask] = []
            for key, string_data in strings.items():
                if not key.strip():
                    continue

                stats[lang].total_keys += 1

                if self.is_translated(string_data, lang):
                    stats[lang].translated += 1
                    continue

                stats[lang].missing += 1
                source_value = self.get_source_value(key, string_data)

                tasks.append(
                    TranslationTask(
                        key=key,
                        source_value=source_value,
                        is_pattern=self.is_pattern_only(source_value),
                        has_specifiers=self.has_format_specifiers(source_value),
                        string_data=string_data,
                    )
                )

            if not tasks:
                logger.info(f"   ✅ All strings already translated!")
                continue

            logger.info(f"   📝 {len(tasks)} strings to process")

            # Separate patterns from texts to translate
            patterns = [t for t in tasks if t.is_pattern]
            to_translate = [t for t in tasks if not t.is_pattern]

            # Process patterns (copy as-is)
            for task in patterns:
                stats[lang].patterns_copied += 1
                if not dry_run:
                    self._apply_translation(task.string_data, lang, task.source_value)
                if verbose:
                    logger.debug(
                        f"   📋 Copied: '{task.source_value[:40]}...' "
                        if len(task.source_value) > 40
                        else f"   📋 Copied: '{task.source_value}'"
                    )

            logger.info(f"   📋 Copied {len(patterns)} patterns")

            # Batch translate texts
            if to_translate and TRANSLATOR_AVAILABLE:
                texts_to_translate = [t.source_value for t in to_translate]

                # Process in batches with progress bar
                all_translations = []
                total_batches = (
                    len(texts_to_translate) + self.BATCH_SIZE - 1
                ) // self.BATCH_SIZE

                if TQDM_AVAILABLE:
                    pbar = tqdm(
                        total=len(texts_to_translate),
                        desc=f"   🔄 Translating",
                        unit="str",
                        ncols=80,
                    )
                else:
                    logger.info(
                        f"   🔄 Translating {len(texts_to_translate)} strings in {total_batches} batches..."
                    )

                for batch_idx in range(0, len(texts_to_translate), self.BATCH_SIZE):
                    batch = texts_to_translate[batch_idx : batch_idx + self.BATCH_SIZE]
                    translations = self.translate_batch(batch, lang)
                    all_translations.extend(translations)

                    if TQDM_AVAILABLE:
                        pbar.update(len(batch))
                    else:
                        current_batch = batch_idx // self.BATCH_SIZE + 1
                        logger.info(
                            f"      Batch {current_batch}/{total_batches} completed"
                        )

                if TQDM_AVAILABLE:
                    pbar.close()

                # Apply translations
                for task, translation in zip(to_translate, all_translations):
                    if translation:
                        stats[lang].texts_translated += 1
                        if not dry_run:
                            self._apply_translation(task.string_data, lang, translation)
                        if verbose:
                            logger.debug(
                                f"   🔄 '{task.source_value[:30]}' → '{translation[:30]}'"
                            )
                    else:
                        stats[lang].errors += 1
                        stats[lang].patterns_copied += 1
                        if not dry_run:
                            self._apply_translation(
                                task.string_data, lang, task.source_value
                            )
                        logger.warning(
                            f"   ⚠️ Failed to translate: '{task.source_value[:40]}'"
                        )

                logger.info(f"   🔄 Translated {stats[lang].texts_translated} strings")
                if stats[lang].errors > 0:
                    logger.warning(f"   ⚠️ {stats[lang].errors} translation errors")

            elif to_translate:
                logger.warning("   ⚠️ Translator not available, copying texts as-is")
                for task in to_translate:
                    stats[lang].patterns_copied += 1
                    if not dry_run:
                        self._apply_translation(
                            task.string_data, lang, task.source_value
                        )

        return stats

    def _apply_translation(self, string_data: dict, lang: str, value: str):
        """Apply a translation to the string data."""
        if "localizations" not in string_data:
            string_data["localizations"] = {}
        string_data["localizations"][lang] = {
            "stringUnit": {"state": "translated", "value": value}
        }

    def print_processing_summary(self, stats: dict[str, LocalizationStats]):
        """Print summary of processing results."""
        print("\n" + "=" * 60)
        print("📊 PROCESSING SUMMARY")
        print("=" * 60)

        total_processed = 0
        total_translated = 0
        total_errors = 0

        for lang, stat in stats.items():
            processed = stat.patterns_copied + stat.texts_translated
            total_processed += processed
            total_translated += stat.texts_translated
            total_errors += stat.errors

            print(f"\n🌍 {lang.upper()} ({self._get_language_name(lang)})")
            print(f"   Patterns copied:     {stat.patterns_copied}")
            print(f"   Texts translated:    {stat.texts_translated}")
            print(f"   Errors:              {stat.errors}")
            print(f"   Total processed:     {processed}")

        print("\n" + "-" * 60)
        print(f"📈 TOTALS")
        print(f"   Total processed:     {total_processed}")
        print(f"   Total translated:    {total_translated}")
        print(f"   Total errors:        {total_errors}")
        print("=" * 60)

    def export_missing_keys(self, output_path: str, languages: Optional[list] = None):
        """Export missing keys to a JSON file."""
        stats = self.analyze(languages)
        export_data = {}

        for lang, stat in stats.items():
            export_data[lang] = {
                "stats": {
                    "total": stat.total_keys,
                    "translated": stat.translated,
                    "missing": stat.missing,
                    "percentage": round(stat.translated / stat.total_keys * 100, 1)
                    if stat.total_keys > 0
                    else 0,
                },
                "missing_keys": [],
            }
            for key in stat.missing_keys:
                source_value = self.get_source_value(
                    key, self.data["strings"].get(key, {})
                )
                export_data[lang]["missing_keys"].append(
                    {
                        "key": key,
                        "source_value": source_value,
                        "is_pattern": self.is_pattern_only(source_value),
                        "has_format_specifiers": self.has_format_specifiers(
                            source_value
                        ),
                    }
                )

        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(export_data, f, ensure_ascii=False, indent=2)

        logger.info(f"✅ Exported missing keys to {output_path}")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Localization Manager for Cash App",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --analyze                    # Analyze all languages
  %(prog)s --analyze --verbose          # Detailed analysis with missing keys
  %(prog)s --translate                  # Translate all missing strings
  %(prog)s --translate --language fr    # Translate only French
  %(prog)s --dry-run --translate        # Preview translations without saving
  %(prog)s --export missing.json        # Export missing keys to JSON
  %(prog)s --translate --log trans.log  # Save log to file
        """,
    )

    parser.add_argument(
        "--analyze", "-a", action="store_true", help="Analyze missing translations"
    )
    parser.add_argument(
        "--translate", "-t", action="store_true", help="Translate missing strings"
    )
    parser.add_argument(
        "--dry-run", "-n", action="store_true", help="Preview changes without saving"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true", help="Show detailed output"
    )
    parser.add_argument(
        "--language",
        "-l",
        type=str,
        help="Process only specific language (it, fr, de, es)",
    )
    parser.add_argument(
        "--export",
        "-e",
        type=str,
        metavar="FILE",
        help="Export missing keys to JSON file",
    )
    parser.add_argument(
        "--file", "-f", type=str, default=None, help="Path to Localizable.xcstrings"
    )
    parser.add_argument("--log", type=str, default=None, help="Log file path")

    args = parser.parse_args()

    # Setup logging
    log_file = args.log or (
        f"localization_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        if args.translate
        else None
    )
    setup_logging(log_file=log_file, verbose=args.verbose)

    # Check dependencies
    if not TQDM_AVAILABLE:
        logger.warning("⚠️ tqdm not installed. Install with: pip install tqdm")
    if not TRANSLATOR_AVAILABLE:
        logger.warning(
            "⚠️ deep-translator not installed. Install with: pip install deep-translator"
        )

    # Auto-detect xcstrings file
    if args.file:
        xcstrings_path = args.file
    else:
        script_dir = Path(__file__).parent
        possible_paths = [
            script_dir.parent / "Cash" / "Localizable.xcstrings",
            Path.cwd() / "Cash" / "Localizable.xcstrings",
            Path.cwd() / "Localizable.xcstrings",
        ]
        xcstrings_path = None
        for path in possible_paths:
            if path.exists():
                xcstrings_path = str(path)
                break
        if not xcstrings_path:
            logger.error("❌ Could not find Localizable.xcstrings")
            logger.error("   Please specify the path with --file")
            sys.exit(1)

    # Initialize manager
    manager = LocalizationManager(xcstrings_path)
    if not manager.load():
        sys.exit(1)

    languages = [args.language] if args.language else None

    # Execute actions
    if args.analyze:
        stats = manager.analyze(languages)
        manager.print_analysis(stats, verbose=args.verbose)

    if args.export:
        manager.export_missing_keys(args.export, languages)

    if args.translate:
        if not TRANSLATOR_AVAILABLE:
            logger.error("❌ Translation requires deep-translator library")
            logger.error("   Install with: pip install deep-translator")
            sys.exit(1)

        logger.info("\n🚀 Starting translation process...")
        if args.dry_run:
            logger.info("   (DRY RUN - no changes will be saved)")

        stats = manager.process_missing_translations(
            languages=languages, dry_run=args.dry_run, verbose=args.verbose
        )
        manager.print_processing_summary(stats)

        if not args.dry_run:
            manager.save()

        if log_file:
            logger.info(f"📄 Log saved to: {log_file}")

    if not (args.analyze or args.translate or args.export):
        parser.print_help()


if __name__ == "__main__":
    main()
