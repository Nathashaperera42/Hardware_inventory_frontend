# Hardware Inventory Management System — Frontend

A Flutter desktop/web frontend for managing hardware and building-supplies inventory: stock levels, stock in/out movements, categories, suppliers, and low-stock alerts, backed by a REST API.

## Features

- **Dashboard** — live stats, recent stock in/out activity, and low-stock alerts
- **Items** — catalog with barcode, quantity-in-hand, category/supplier filters, and pagination
- **Stock In / Stock Out** — record stock movements with a full history log
- **Stock Balance** — consolidated view of quantity, status, category, and supplier per item
- **Low Stock Alerts** — items nearing or below their reorder threshold
- **Categories & Suppliers** — manage reference data used across the catalog
- **Reports** — export stock reports to PDF or print directly
- **Users & Settings** — administration screens for account and app configuration

## Tech Stack

- [Flutter](https://flutter.dev) (Material 3)
- [http](https://pub.dev/packages/http) for REST communication
- [pdf](https://pub.dev/packages/pdf) / [printing](https://pub.dev/packages/printing) for report export
- [intl](https://pub.dev/packages/intl) for formatting

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0 <4.0.0`
- A running instance of the backend API

### Installation

```bash
git clone https://github.com/Nathashaperera42/Hardware_inventory_frontend.git
cd Hardware_inventory_frontend
flutter pub get
```

### Configuration

Set the backend base URL in [`lib/core/constants.dart`](lib/core/constants.dart):

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:5000/api';
}
```

| Target             | Base URL                     |
| ------------------ | ----------------------------- |
| Android emulator    | `http://10.0.2.2:5000`        |
| Desktop / Web       | `http://localhost:5000`       |
| Physical device     | `http://<your-pc-ip>:5000`    |

### Run

```bash
flutter run
```

## Project Structure

```
lib/
├── core/       # API client, theme, and app-wide configuration
├── models/     # Data models
├── screens/    # Feature screens (dashboard, items, stock in/out, etc.)
├── services/   # API service layer
└── widgets/    # Shared/reusable UI components
```
