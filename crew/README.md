# CCST Crew Study

A crew version of the study app. Each tech has their own login and progress, and the crew shares a leaderboard. The coach approves techs, sees how each one is doing, and posts announcements.

App link: **https://holaturbo-web.github.io/ccst-study-app/crew/**

The app works like the personal one: it's offline-first, it saves on the phone, and it syncs when there's signal. The data lives in a free Supabase project that the coach owns.

## One-time setup (coach, about 15 minutes)

### 1. Create the Supabase project
1. Go to **supabase.com** and sign up (you can use your GitHub account).
2. Click **New project**. Name it `ccst-crew`, set a database password and save it somewhere safe, then pick the US region closest to you.
3. Wait about 2 minutes for it to finish setting up.

### 2. Run the setup script
1. In the project, open **SQL Editor** → **New query**.
2. Paste the whole file `2026-10-20-crew-supabase-setup.sql` from this folder.
3. Edit the three values near the top:
   - `crew_code`: the code techs type to join, for example `PRIME-CCST-27`.
   - `coach_username`: the username you'll sign up with, for example `alejandro`.
   - `email_pattern`: an inbox you control, with `{u}` where the username goes, for example `yourname+{u}@gmail.com`. Techs never see or use this address. Password reset links for techs come to this inbox, so you can reset them.
4. Click **Run**. It should finish with "Success".

### 3. Two auth settings
1. **Authentication** → **Sign In / Providers** → **Email**: turn **off** "Confirm email", then save.
2. **Authentication** → **URL Configuration**: set **Site URL** to `https://holaturbo-web.github.io/ccst-study-app/crew/`, and add the same address under **Redirect URLs**.

### 4. Connect the app
In **Project Settings** → **API Keys** (or **Data API**), copy:
- the **Project URL** (looks like `https://abcd1234.supabase.co`)
- the **publishable** key, or the legacy **anon public** key

These two are meant to be public. The database's access rules protect the data. **Never share the `service_role` or secret key.**

They go in `crew/config.js` (already filled in for this crew).

### 5. First sign-in and content
1. Open the app link, tap **Join the crew**, and sign up with your coach username and the crew code. You'll be coach automatically.
2. Go to **Coach** → **Publish content**, paste your GitHub access key (the same one your personal app uses), and tap **Publish content**. This copies the cards, questions, plan and Reader PDF to the crew.
3. Post a welcome announcement.

## Running the crew
- **Adding techs:** send them the app link and the crew code. They join, then appear under **Waiting for approval** in the Coach tab. Tap **Approve**.
- **Installing:** on iPhone, Safari → Share → Add to Home Screen. On Android, Chrome → ⋮ → Install app.
- **Forgotten password:** Coach tab → open the tech → **Send password reset**. The link arrives in your crew inbox. Open it on your phone, set a new password, and give it to the tech.
- **Someone leaves:** **Deactivate** blocks them but keeps their progress. **Remove** deletes their progress.
- **New content:** when the study content changes, tap **Publish content** again. Techs get it on their next sync.
- **Leaderboard points:** 1 per card reviewed, 2 per question answered, +1 when it's right. The weekly board resets on Monday.

## What each person can see
| | Tech | Coach |
|---|---|---|
| Own progress, error log | ✓ | ✓ |
| Other techs' answers and error logs | ✗ | ✗ (the coach sees summaries only) |
| Leaderboard | ✓ | ✓ |
| Coach tab: approvals, crew stats, announcements, crew code, publishing | ✗ | ✓ |

## Good to know
- **Free tier:** Supabase pauses a free project after a week with no activity at all. If the crew stops studying for a while, open the Supabase dashboard and click **Restore**.
- **Score integrity:** scores are calculated on each phone, so a determined tech could fake theirs. That's fine for a friendly crew board, but don't use it for anything that matters.
- **Separate from your own app:** your personal study app at `/ccst-study-app/` and its GitHub data are separate. Your crew account has its own progress.
