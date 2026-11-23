# FoodLoop

A food-waste redistribution app for a college campus. The canteen (donor) posts
surplus food, registered recipients request it, volunteers collect and deliver
it, and an admin approves accounts and assigns volunteers.

The UI follows the "Canteen Token" design: listings are token slips, statuses
are rubber stamps, histories are printed receipts, and the donor's board is a
chalkboard. See [DESIGN.md](DESIGN.md).

| Folder | What it is |
|---|---|
| `backend/` | Node.js + Express 5 + MongoDB (Mongoose 9) REST API, JWT auth, Postman tests |
| `frontend/` | Flutter app (web and Android), `provider` + `go_router` |
| `docs/` | Screenshot pass and findings (`docs/FINDINGS.md`, `docs/screenshots/`) |

---

## 1. Requirements

- **Node.js** 20 or newer (developed on 24)
- **MongoDB** 6 or newer, running locally
- **Flutter** 3.50 or newer (Dart 3.14), with Chrome for the web build

## 2. MongoDB

The backend expects MongoDB at `mongodb://127.0.0.1:27017/foodloop`. Use either:

- **A local install:** install MongoDB Community Server and start the service.
  On Windows it runs as the "MongoDB" service after installation.
- **Docker:**
  ```bash
  docker run -d --name foodloop-mongo -p 27017:27017 mongo:7
  ```

The `foodloop` database is created by the seed script; you don't need to create
it by hand.

## 3. Backend

```bash
cd backend
cp .env.example .env        # then set JWT_SECRET to a long random string
npm install
npm run seed                # WIPES the foodloop database and loads demo data
npm run dev                 # API on http://localhost:5000 (restarts on change)
```

`.env` settings (from `.env.example`):

| Key | Default | Meaning |
|---|---|---|
| `PORT` | `5000` | API port |
| `MONGO_URI` | `mongodb://127.0.0.1:27017/foodloop` | Database |
| `JWT_SECRET` | (change it) | Signs login tokens |
| `JWT_EXPIRES_IN` | `7d` | How long a login lasts |

Other scripts:

| Command | What it does |
|---|---|
| `npm start` | Run the API without auto-restart |
| `npm run create-admin -- "Name" email@x.y "password" [phone]` | Create an extra approved admin (admins can't register through the app) |
| `npm run test:api` | Run the Postman collection with newman (see section 6) |

All responses use the shape `{ success, message, data }`.

## 4. Flutter app

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

The API address is in `frontend/lib/core/config.dart`:

- **Web:** `http://localhost:5000/api`
- **Android emulator:** `http://10.0.2.2:5000/api` (10.0.2.2 is the emulator's
  name for your computer)
- **A phone or another machine:** override it at run time:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://192.168.1.5:5000/api
  ```

The theme toggle (paper / chalkboard) is in Profile. A component gallery of
every signature widget is at `/#/gallery`.

## 5. Test logins

After `npm run seed`, every account uses the password **`password123`**.

| Role | Email | Who |
|---|---|---|
| Admin | `admin@foodloop.test` | Campus Admin |
| Donor | `canteen@foodloop.test` | Main Block Canteen |
| Recipient | `ananya@foodloop.test` | Ananya Rao, Asha Night Shelter |
| Recipient | `farhan@foodloop.test` | Farhan Sheikh, Boys Hostel C Mess |
| Volunteer | `kiran@foodloop.test` | Kiran Kumar, NSS Unit 2 |
| Volunteer | `meera@foodloop.test` | Meera Nair, NSS Unit 2 |
| Pending recipient | `rohit@foodloop.test` | Rohit Verma; sees the "waiting for approval" screen |

The seed also creates about ten listings in every state (available, fully
reserved, expired, completed), plus claims, pickups and notifications, so every
screen has something on it.

## 6. API tests

With the backend running (`npm run dev`) on a freshly seeded database:

```bash
cd backend
npm run test:api
```

This runs `backend/postman/FoodLoop.postman_collection.json` with newman: 80
requests, including negative tests for over-allocation, wrong role and invalid
status transitions. The tests add data, so run `npm run seed` again afterwards
for a clean demo.

You can also import the same collection into Postman or Thunder Client.

## 7. Demo script: donor → recipient → volunteer → delivered

Run this on a freshly seeded database. It's easiest with two browser windows (or
one normal and one private window), so two people can be signed in at once.

1. **Donor posts food.** Sign in as `canteen@foodloop.test`.
   - Press **Post food** (raised button on a phone, red button in the sidebar
     on desktop).
   - Fill in *What is it?* (e.g. "Veg Pulao"), food type, quantity 10 and unit
     *plates*.
   - Use **+2 h** for the pickup time, then **Print token**.
   - The new token appears on the **Today's Surplus** chalkboard with its own
     number (#FL-00xx).
2. **Recipient requests it.** In the other window, sign in as
   `ananya@foodloop.test`.
   - On **Today's Counter**, open the new token. On a phone it opens as its own
     page; on wider screens it opens in the side panel.
   - Read the food-safety note, set the quantity to 4 and press
     **Request 4 plates**.
   - **Requests** now shows a receipt with a PENDING stamp.
3. **Donor approves.** Back in the donor window, the request appears under
   **Requests** on the board (and the bell shows a new alert).
   - Press **Approve**. The APPROVED stamp drops onto the request (the app's
     signature animation), and the board shows 6 plates left.
4. **Admin assigns a volunteer.** Sign the donor window out and sign in as
   `admin@foodloop.test`.
   - On **Overview**, the request is under **Needs a volunteer**.
   - Press **Assign volunteer**, pick **Kiran Kumar** and press
     **Assign Kiran**.
5. **Volunteer collects and delivers.** Sign in as `kiran@foodloop.test`.
   - **Pickups → Assigned** shows the pickup slip.
   - Press **I've collected it**. It moves to *On the way*.
   - Then press **Mark delivered**. It moves to *Delivered*.
6. **Check the result.**
   - As Ananya, the **Requests** receipt is complete, with a DELIVERED stamp.
   - As the admin, **Overview** counts the new portions. Food counts only when
     it is delivered.
   - Every role's **Alerts** shows the steps that concerned them.

Things to show along the way:

- **Over-allocation:** on the seeded data, the canteen has two requests (6 + 8
  packets) for Veg Grilled Sandwiches, which has only 12. Approve one, and the
  other can no longer be approved. Its pickup deadline is 45 minutes after
  seeding, so show this soon after `npm run seed`.
- **Pending account:** `rohit@foodloop.test` sees only the waiting screen until
  the admin approves him under **Approvals**.
- **Themes:** Profile → *Chalkboard mode* switches between paper and chalkboard.

## 8. Notes

- **Android:** VS Code currently shows a Gradle/Java build error for the Android
  target. It has not been investigated; web is the tested target.
- **Progress and known issues:** see [PROGRESS.md](PROGRESS.md) and
  [docs/FINDINGS.md](docs/FINDINGS.md).
