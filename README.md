<div align="center">
  <img src="lib/assets/images/hike_logo.png" alt="M-Hike logo" width="120" />

  <h1>M-Hike Hybrid App</h1>

  <p>
    A Flutter hiking companion for planning trips, recording observations,
    tracking weather, and generating AI-powered hike suggestions.
  </p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-3.9.2-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/Database-SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite" />
    <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License" />
  </p>
</div>

---

## Overview

<table>
  <tr>
    <td width="60%">
      <strong>M-Hike Hybrid App</strong> helps hikers manage the full journey from planning to reflection. Users can create hike records, attach observations and media, view route/map information, save weather forecasts, and request AI-generated preparation advice.
    </td>
    <td width="40%">
      <ul>
        <li>Offline-first local data</li>
        <li>Map and weather integration</li>
        <li>AI hike recommendation support</li>
        <li>Light and dark theme support</li>
      </ul>
    </td>
  </tr>
</table>

## Features

<table>
  <tr>
    <th>Module</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><strong>Hike Management</strong></td>
    <td>Create, edit, delete, search, and filter hike records.</td>
  </tr>
  <tr>
    <td><strong>Planning</strong></td>
    <td>Organize hikes into planned, completed, and remarkable trips.</td>
  </tr>
  <tr>
    <td><strong>Hike Details</strong></td>
    <td>Store location, date, distance, difficulty, parking, duration, description, coordinates, and hike type.</td>
  </tr>
  <tr>
    <td><strong>Observations</strong></td>
    <td>Add captions, notes, images, and videos to each hike.</td>
  </tr>
  <tr>
    <td><strong>Maps</strong></td>
    <td>Pick hike locations and support map-derived route distance.</td>
  </tr>
  <tr>
    <td><strong>Weather</strong></td>
    <td>Save multi-day weather forecasts through OpenWeatherMap.</td>
  </tr>
  <tr>
    <td><strong>AI Suggestions</strong></td>
    <td>Generate preparation advice, packing lists, weather guidance, risk notes, and start-time hints.</td>
  </tr>
  <tr>
    <td><strong>Settings</strong></td>
    <td>View basic statistics and switch between light and dark themes.</td>
  </tr>
</table>

## Tech Stack

<table>
  <tr>
    <th>Layer</th>
    <th>Technology</th>
  </tr>
  <tr>
    <td>Framework</td>
    <td>Flutter / Dart</td>
  </tr>
  <tr>
    <td>State Management</td>
    <td>Provider</td>
  </tr>
  <tr>
    <td>Local Database</td>
    <td>SQLite with <code>sqflite</code></td>
  </tr>
  <tr>
    <td>Maps</td>
    <td>Google Maps and WebView map integration</td>
  </tr>
  <tr>
    <td>Weather</td>
    <td>OpenWeatherMap API</td>
  </tr>
  <tr>
    <td>AI</td>
    <td>HTTP backend service integration</td>
  </tr>
  <tr>
    <td>Media</td>
    <td><code>image_picker</code>, <code>video_player</code></td>
  </tr>
</table>

## Project Structure

```text
lib/
  db/              SQLite database manager
  models/          Data models for hikes, observations, media, weather, and AI suggestions
  services/        API, map, location, media, permission, and weather services
  viewmodels/      Provider-based state management
  views/           UI screens and reusable widgets
  assets/images/   App images and static assets
test/              Flutter tests
android/ ios/      Mobile platform projects
web/               Web platform project
windows/ macos/    Desktop platform projects
linux/             Linux platform project
```

## Requirements

<ul>
  <li>Flutter SDK compatible with Dart <code>^3.9.2</code></li>
  <li>Android Studio, Xcode, or another Flutter-supported target environment</li>
  <li>OpenWeatherMap API key</li>
  <li>Optional AI backend service exposing <code>GET /health</code> and <code>POST /api/hike-ai/evaluate</code></li>
</ul>

## Environment Setup

Create a `.env` file from the template:

```bash
cp .env.example .env
```

Update the values:

```env
WEATHER_API_KEY=your_openweathermap_api_key_here
WEATHER_API_BASE_URL=https://api.openweathermap.org/data/2.5
AI_SERVICE_BASE_URL=http://10.0.2.2:8000
WEB_MAP_URL=https://hoangvhgch220975.github.io/map_only/
```

<table>
  <tr>
    <th>Target</th>
    <th>AI Backend URL</th>
  </tr>
  <tr>
    <td>Android Emulator</td>
    <td><code>http://10.0.2.2:8000</code></td>
  </tr>
  <tr>
    <td>iOS Simulator / Desktop</td>
    <td><code>http://localhost:8000</code></td>
  </tr>
  <tr>
    <td>Real Device</td>
    <td><code>http://YOUR_COMPUTER_IP:8000</code></td>
  </tr>
</table>

## Installation

```bash
flutter pub get
```

## Run

```bash
flutter run
```

## Test and Analyze

```bash
flutter test
flutter analyze
```

## Build

```bash
flutter build apk
flutter build ios
flutter build web
```

## Notes

> The app loads `.env` at startup. Missing or invalid API keys can disable weather and AI-related features.

- Local data is stored in SQLite under `m_hike_hybrid_app.db`.
- AI suggestions are cached locally after generation and can be regenerated when needed.
- Maps, camera, gallery, location, and video playback may require additional platform permissions.

## License

<p>
  This project is licensed under the <strong>MIT License</strong>.
  See <a href="LICENSE">LICENSE</a> for details.
</p>

<div align="center">
  <sub>Built with Flutter for hiking planning and trip journaling.</sub>
</div>
