# Software-Assignment by Murfid Dzakwan Kamil

## Description

This is a Flutter application designed to allow users to upload and view device data in CSV format. The app reads CSV files, parses their data, stores the data in a local SQLite database, and displays the device data grouped by device name. It also includes features like pie chart visualization of devices and the option to view detailed device data.

## Features

- Upload and parse CSV files.
- Store parsed device data in an SQLite database.
- Display devices in a grouped format by name
- Visualize device data using a pie chart
- View detailed device data with the option to delete records
- Real-time updates after uploading new data

## Prerequisites

Before running the project, ensure you have the following tools and dependencies installed:

- Android Studio or Visual Studio Code with Flutter and Dart plugins
- An emulator or physical device for testing
- Dart SDK
- Flutter SDK (version 2.0 or above)
- CSV file for testing (with device data in the following format):
  - Serial, Name, DateTime, CO, SO, PM2.5

### Setup for Dependencies

To install required dependencies, use the following command in your project directory:

```bash
git clone https://github.com/prinzzy/Software-Assignment.git
cd Software-Assignment
flutter pub get
flutter run
```

### Release App
[Download the Example File](https://raw.githubusercontent.com/prinzzy/Software-Assignment/main/app-release.apk)

