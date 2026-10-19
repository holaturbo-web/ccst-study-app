# CCST Study (offline app)

Offline-first study app for the ISA CCST Level I exam. Cards, practice questions and your progress live in a **private** repo (`ccst-study-data`). This public repo holds only the app code, with no ISA content.

App link (after Pages is turned on): **https://holaturbo-web.github.io/ccst-study-app/**

## One-time setup

### 1. Turn on GitHub Pages for this repo
1. Open this repo on GitHub → **Settings** → **Pages**.
2. Under **Build and deployment**, set **Source** to *Deploy from a branch*.
3. Choose branch **main**, folder **/ (root)**, then click **Save**.
4. Wait about a minute. The app link above starts working.

### 2. Create your access key (fine-grained token)
1. Go to **github.com/settings/personal-access-tokens/new**.
2. **Token name:** `ccst-study`. **Expiration:** pick a date after your exam (for example 1 year).
3. **Repository access:** choose *Only select repositories* and pick **ccst-study-data** only.
4. **Permissions** → **Repository permissions** → **Contents** → set to **Read and write**. Leave everything else at *No access*.
5. Click **Generate token** and copy it (it starts with `github_pat_`). GitHub shows it only once.

Paste the key only into the app on your devices. Don't send it in chat or email. If it ever leaks, delete it on that same settings page and make a new one.

### 3. Install it on your phone
1. Open the app link in **Safari** (iPhone) or **Chrome** (Android).
2. Paste your access key and tap **Connect**.
3. iPhone: tap **Share** → **Add to Home Screen**. Android: tap **⋮** → **Add to Home screen** (or **Install app**).
4. Open it from the home screen icon once while you're online so everything is cached for offline use.

Repeat step 3 on any other device (laptop, work computer). They all sync to the same progress file.

## How sync works
- Every answer and card rating saves on the device first, so the app works with no signal.
- Whenever you're online (on open, every few minutes, and when you leave the app) it merges your progress with `progress/progress.json` in the data repo.
- If two devices changed different items, both changes are kept. For the same item, the most recent change wins.
- The header shows the status: *Synced*, *Offline · X changes waiting*, or *Syncing…*. You can also sync manually from **Plan → Sync settings**.
- New content (more cards and questions) is picked up automatically the next time the app is online.

## Profiles (separate progress)
Each profile has its own cards schedule, scores, error log and notes; they never mix. Content is shared.
- Your normal profile is **main** (saved as `progress/progress.json`).
- To add another: **Plan → Sync settings → Switch to profile**, type a name (e.g. `practice`), tap **Switch**. It's saved as `progress/practice.json`.
- Switch back the same way by typing `main`. You can also set the profile on the connect screen.

## Notes
- iPhone may clear website storage for apps you haven't opened in several weeks. Your progress is safe in GitHub; just reconnect with your key.
- Each sync creates a small commit in the data repo. That's normal. It's also your full progress history.
