# Cash - Personal Finance Manager

A simplified macOS financial management application inspired by Gnucash, built with SwiftUI and SwiftData.

## Getting Started

### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/cash.git
cd cash
```

2. Open the project in Xcode:
```bash
open Cash.xcodeproj
```

3. Build and run the project (⌘R)

## Localization

Cash is fully localized in:
- 🇬🇧 English
- 🇮🇹 Italian

To add a new language, edit `Localizable.xcstrings` in Xcode.

## Data Persistence

All data is stored locally using SwiftData with automatic iCloud sync.

### Data Models
- **Account**: Stores account information and balances
- **Transaction**: Individual income/expense records
- **RecurringTransaction**: Recurring transaction templates
- **Category**: Custom category definitions

## Roadmap

- [ ] Budget planning and tracking
- [ ] Financial reports and charts
- [ ] Transaction import (CSV, OFX)
- [ ] Multiple currency conversion
- [ ] Split transactions
- [ ] Tags and notes
- [ ] Export data

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
