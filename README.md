# 🎵 Soundwave — Music Recognition App

A full-stack Shazam clone built with **Flutter** (mobile), **Node.js/Express** (backend), and **PostgreSQL** (database).

---

## Features

- 🎤 **Real-time music recognition** — tap to listen, identify any song in seconds
- 📜 **Recognition history** — browse every song you've ever identified
- ❤️ **Favorites** — save songs you love
- 🔍 **Search** — search the song database by title or artist
- 📈 **Trending** — see what songs are being recognized most this week
- 🔐 **Auth** — full JWT-based register/login/profile system
- 🌙 **Dark UI** — sleek purple/cyan dark theme

---

## Project Structure

```
soundwave/
├── app/          # Flutter mobile app
│   ├── lib/
│   │   ├── core/           # Theme, constants
│   │   ├── data/           # Models, providers, services
│   │   ├── screens/        # All UI screens
│   │   └── widgets/        # Shared widgets
│   └── pubspec.yaml
│
└── backend/      # Node.js/Express REST API
    ├── src/
    │   ├── config/         # Database connection + migration
    │   ├── controllers/    # Auth, recognition, songs
    │   ├── middleware/     # JWT auth, error handler
    │   ├── routes/         # Express routers
    │   └── services/       # ACRCloud / Audd.io integration
    └── package.json
```

---

## Tech Stack

| Layer     | Technology                       |
|-----------|----------------------------------|
| Mobile    | Flutter 3.x, Dart                |
| State     | Provider                         |
| Backend   | Node.js, Express                 |
| Database  | PostgreSQL                       |
| Auth      | JWT + bcryptjs                   |
| Music API | ACRCloud (or Audd.io fallback)   |
| Audio     | `record` package                 |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Node.js 18+
- PostgreSQL 14+
- An [ACRCloud](https://www.acrcloud.com) account (free tier available) **or** [Audd.io](https://audd.io) token

---

### 1. Backend Setup

```bash
cd backend

# Copy environment file and fill in your values
cp .env.example .env

# Install dependencies
npm install

# Create the database in PostgreSQL first:
# psql -U postgres -c "CREATE DATABASE soundwave_db;"

# Run migrations (creates all tables)
npm run db:migrate

# Start dev server
npm run dev
```

The API runs at `http://localhost:3000`.

**`.env` values to fill in:**

| Key | Description |
|-----|-------------|
| `DB_PASSWORD` | Your PostgreSQL password |
| `JWT_SECRET` | Any long random string |
| `ACRCLOUD_HOST` | From your ACRCloud project |
| `ACRCLOUD_ACCESS_KEY` | From your ACRCloud project |
| `ACRCLOUD_ACCESS_SECRET` | From your ACRCloud project |
| `AUDD_API_TOKEN` | Alternative: Audd.io token |

---

### 2. Flutter App Setup

```bash
cd app

# Install dependencies
flutter pub get
```

**Set your backend URL** in `lib/core/constants/app_constants.dart`:

```dart
// Android emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// iOS simulator
static const String baseUrl = 'http://localhost:3000/api';

// Physical device (use your machine's local IP)
static const String baseUrl = 'http://192.168.x.x:3000/api';
```

**Run the app:**

```bash
flutter run
```

---

## API Endpoints

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Create account |
| POST | `/api/auth/login` | Sign in |
| GET | `/api/auth/me` | Get current user |
| PUT | `/api/auth/profile` | Update profile |

### Recognition
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/recognize` | Identify a song (multipart audio) |
| GET | `/api/recognize/history` | Get recognition history |
| DELETE | `/api/recognize/history/:id` | Delete history item |

### Songs
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/songs/search?q=` | Search songs |
| GET | `/api/songs/trending` | Top songs this week |
| GET | `/api/songs/favorites` | User's favorites |
| POST | `/api/songs/:id/favorite` | Add to favorites |
| DELETE | `/api/songs/:id/favorite` | Remove from favorites |

---

## Getting ACRCloud Credentials (Free)

1. Sign up at [acrcloud.com](https://www.acrcloud.com)
2. Create a new project → **Audio & Video Recognition**
3. Copy `Host`, `Access Key`, and `Access Secret` into your `.env`

---

## Screenshots

_Coming soon — run the app to see the dark purple UI in action_

---

## License

MIT
