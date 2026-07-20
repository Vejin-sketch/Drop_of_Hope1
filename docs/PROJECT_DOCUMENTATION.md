# Drop of Hope — Project Documentation

A blood donation matching app. Flutter mobile/web frontend + Node.js/Express backend + SQLite database.

Repo: `github.com/Vejin-sketch/Drop_of_Hope1`

---

## 1. Architecture

```
lib/            Flutter frontend (screens + services)
backend/        Node.js/Express API + SQLite database
android/ ios/ web/   Flutter platform shells
docs/           This documentation + legacy notes/backups
```

The frontend talks to the backend over plain HTTP REST calls. There is **no authentication token** sent on any request — see Security section.

`ApiService.baseUrl` (`lib/services/api_service.dart`) picks the backend address:
- Web build → `http://localhost:3000`
- Mobile build → hardcoded LAN IP `http://192.168.124.154:3000`

This means on a physical device the app only reaches the backend if that device is on the same Wi-Fi as whatever machine is running `node server.js` at that IP — a common "why isn't the app connecting" cause. See Troubleshooting.

---

## 2. Frontend (`lib/`)

### Entry point
- **`main.dart`** — checks `SessionManager.isLoggedIn()` on startup and routes to `SplashScreen`, passing the login state through.

### Services (`lib/services/`)
| File | Responsibility |
|---|---|
| `api_service.dart` | All HTTP calls to the backend: login, register, save/fetch profile, fetch requests, matches, donation responses. `fetchBloodStock()` is a stub that throws `UnimplementedError` — the backend route doesn't exist yet. |
| `session_manager.dart` | Wraps `SharedPreferences` to persist `userId`, `username`, `email`, `isLoggedIn` locally on the device (this is the app's "session" — there's no server-side session/token). |
| `location_service.dart` | Wraps `geolocator` to request location permission and get the device's GPS coordinates. |
| `chat_service.dart` | Calls a chatbot endpoint at `http://<ip>:5000/chat`. **No server for this exists anywhere in this repo** (backend only listens on port 3000) — this feature is currently non-functional/orphaned. |

### Screens (`lib/screens/`)
| File | Purpose |
|---|---|
| `splash_screen.dart` | Initial loading screen, routes to login or home based on session state. |
| `login_screen.dart` / `register_screen.dart` | Auth forms, call `ApiService.login` / `.register`. |
| `home_screen.dart` | Main menu after login: Profile, Blood Stock, Donate Blood, Need Blood, Find Donors, Find Requests, Logout. |
| `complete_profile_screen.dart` / `profile_screen.dart` | View/edit medical profile: blood group, gender, age, weight, location, tattoo/HIV status. |
| `donate_blood_screen.dart` | Register a blood donation offer. |
| `need_blood_screen.dart` | Create a blood request (patient details, hospital, urgency, consent checkbox). |
| `find_donors_screen.dart` / `find_requests_screen.dart` | Browse available donors / open requests. |
| `my_requests_screen.dart` | Lists the current user's blood requests. |
| `track_response_screeen.dart` *(sic — typo in filename)* | Tracks the status of a donor's response to a request (pending/fulfilled/cancelled). |
| `blood_stock_screen.dart` | Blood stock level UI — **calls an unimplemented backend route**, will always fail. |
| `notification_screen.dart` | Notifications list (static/local — no push notification backend found). |
| `chat_screen.dart` | Chatbot UI — depends on the non-existent port-5000 service above. |

---

## 3. Backend (`backend/`)

Express app, entry point `server.js`, listens on port `3000`.

### Routes → Controllers
| Route | Controller | Purpose |
|---|---|---|
| `POST /auth/register`, `/auth/login` | `authController.js` | Create account / log in |
| `GET/PUT /profile` | `routes/profile.js` (logic inline, no controller file) | Read/update the medical profile fields, including lat/long |
| `GET /matches/donors/:id`, `GET /matches/requests` | `matchController.js` | Blood-type + distance matching (haversine formula, 35 km radius) between donors and requests |
| `POST/GET /requests`, `PUT /requests/:id/fulfill` | `requestController.js` | Create/list blood requests, mark fulfilled by a donation |
| `POST /responses`, `PUT /responses/:id/fulfill`, `/cancel`, `GET /responses/by-donor` | `responsesController.js` | A donor offering to help a request, with a 2-hour auto-expiry window if the request is critical |
| *(not mounted in server.js)* | `donationController.js` | CRUD for donation records + 3-month donation-cooldown rule. Written but **not wired into any route** — currently unreachable. |
| `GET /dev/users` | inline in `server.js` | Debug endpoint dumping all users' id/name/lat/long. **Should not exist in a shipped app** — see Security. |

### Data layer
- `db/db.js` — SQLite connection (`backend/database.db`) + promisified `run/get/all` helpers.
- `db/setup.js` — creates `users`, `blood_donations`, `blood_requests` tables.
- `utils/bloodCompatibility.js` — static donor→recipient blood-type compatibility map, used by matching and fulfillment logic.

### Tables (from `setup.js`)
- **users**: name, email, password, last_donation_date, blood_group, gender, age, weight, location, has_tattoo, is_hiv_positive, latitude, longitude
- **blood_donations**: donor info, blood_group, availability, linked to a user
- **blood_requests**: patient info, blood_group, urgency, fulfillment status, linked to the fulfilling donation

---

## 4. Known incomplete / broken pieces (where to look when something doesn't work)

| Symptom | Likely cause | Where to look |
|---|---|---|
| App can't reach the backend at all on a phone | `ApiService.baseUrl` hardcoded to `192.168.124.154` — stale/wrong LAN IP for your current network | `lib/services/api_service.dart:11` — update to your machine's current IP, or point at a deployed URL |
| Blood Stock screen always errors | Feature was never finished server-side | `lib/services/api_service.dart:98` (stub) — needs a real `/stock` route + controller added to backend |
| Chat screen does nothing / errors | Points to a chatbot server on port 5000 that doesn't exist in this repo | `lib/services/chat_service.dart` — either build that service or remove the screen |
| Donations don't show up via a dedicated donations API | `donationController.js` exists but has no route file / isn't mounted in `server.js` | `backend/server.js` — add `app.use("/donations", require("./routes/donations"))` and create that route file |
| Login "succeeds" with wrong password after DB edits, or any weird auth behavior | Passwords are compared as plain strings, no hashing — see Security §1 | `backend/controllers/authController.js:33` |
| Any screen showing another user's data unexpectedly | There is no auth/session check on the backend — every endpoint trusts whatever `userId` the client sends | `backend/routes/*.js` — no auth middleware exists yet |
| Backend won't start / DB errors | Check `backend/database.db` exists and isn't locked by another process (e.g. "DB Browser for SQLite" left open) | `backend/db/db.js`, `backend/db/database.db` |
| General "network error"/timeout | CORS is fully open and shouldn't block anything — more likely the IP/port mismatch above, or the backend simply isn't running (`node server.js` in `backend/`) | Confirm backend is running: `http://localhost:3000/` should return "Blood Donation App API is running..." |

---

## 5. Security — fixed 2026-07-20

The following were found and fixed:

| Issue | Fix |
|---|---|
| `backend/.env` (JWT_SECRET) was git-tracked since the initial commit | Untracked via `git rm --cached`, added to `.gitignore`. **Not yet rotated** — the user judged the app has never been used/deployed, so the old secret was left as-is rather than regenerated. If that changes, rotate `JWT_SECRET` in `backend/.env`. |
| `backend/database.sqlite`, `backend/db/database.db`, and an uploaded profile picture were git-tracked | Untracked and gitignored. Local files are untouched, just no longer versioned. |
| Passwords stored/compared in plaintext | `authController.js` now hashes with `bcryptjs` on register and uses `bcrypt.compare` on login. |
| No authentication on any API route (full IDOR — any client could read/edit any user's data by guessing an id) | Added `backend/middleware/auth.js` (JWT verify). Applied to `/profile`, `/requests`, `/responses`, `/matches`. Login/register now return a `token`; controllers derive the acting user from `req.userId` (the verified token) instead of trusting client-supplied `userId`/`donorId`. |
| `GET /dev/users` leaked all users' names + GPS coordinates, no auth | Deleted. |
| `server.js` never loaded `.env`, so `JWT_SECRET` wasn't even being read | Added `require("dotenv").config()` at the top; server now refuses to start if `JWT_SECRET` is missing. |

Frontend (`lib/services/session_manager.dart`, `lib/services/api_service.dart`) now stores the JWT after login/register and sends `Authorization: Bearer <token>` on every call to a protected route. Verified end-to-end with a live smoke test (register → 401 without token → 200 with token → `/dev/users` now 404).

**Still not done, worth knowing:**
- Traffic is plain HTTP, not HTTPS — fine for local dev, not for any real deployment.
- No password-reset flow.
- No rate limiting on `/auth/login` (brute-force is possible).
- `donationController.js` still isn't wired to a route (pre-existing, unrelated to security).

---

## 6. Housekeeping notes
- `backend/{` — an empty, accidentally-created file (likely from a shell brace-expansion command that didn't run as intended on Windows). Safe to delete.
- `docs/legacy-notes/` — old planning notes, a diagram, and a stale `backend.zip` backup, kept for reference after the July 2026 folder consolidation.
