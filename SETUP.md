# Taste Doner — cloud + Android setup

This project keeps the original restaurant manager workflow and adds separate Owner/Staff sign-in, shared cloud records, and live refresh across phones. **It is source code, not a live configured service yet.** A Supabase project and its public project URL/anon key must be connected before either phone can sign in. Never put a Supabase service-role key in the app.

## 1. Create the free cloud database
1. Create a project at https://supabase.com/ (choose a strong database password and keep it private).
2. In Supabase open **SQL Editor → New query**, paste all of `supabase_setup.sql`, and run it.
3. In **Project Settings → API**, copy the Project URL and anon/public key.
4. In `index.html`, replace `PASTE_SUPABASE_PROJECT_URL_HERE` and `PASTE_SUPABASE_ANON_KEY_HERE` with those two values. The anon key is designed to be public; database access is controlled by the RLS policies in the SQL.
5. In Supabase **Authentication → Providers → Email**, turn off public signups after creating the owner account (step 6). Keep email/password sign-in enabled.

## 2. Create the Owner and Staff accounts
1. Publish the app temporarily (GitHub Pages or another HTTPS static host), then open it and use **First-time setup → Create first account** with the Owner email/password.
2. In Supabase SQL Editor run this, replacing the email:
   `update public.profiles set role='owner' where id=(select id from auth.users where email='OWNER_EMAIL_HERE');`
3. Sign out and sign in again. The Owner role now unlocks menu editing and stock purchases.
4. In Supabase **Authentication → Users → Add user**, invite/create your partner's email and password. The database trigger creates that account's Staff profile automatically. Staff can sign in on their own phone.
5. In **Database → Publications**, enable Realtime for `sales`, `expenses`, `stock_purchases`, and `menu_items` (publication `supabase_realtime`).

## 3. Publish the web app
Upload the contents of this folder to a GitHub repository. In repository **Settings → Pages**, deploy from the `main` branch / root. Open the published HTTPS URL on both phones and sign in with the separate accounts. Use Add to Home Screen in Chrome for an app-like icon.

## 4. Build Android APK
The included GitHub Actions workflow builds a debug APK. Push the project folder contents to a GitHub repository (including the hidden `.github` folder); open **Actions → Build Taste Doner APK → Run workflow** (or push to `main`). When it completes, open the run and download the `Taste-Doner-debug-APK` artifact. Extract it and install `app-debug.apk` on Android. Allow installation from that source if Android asks. The app uses the same Supabase backend, so both phones share records.

## Important notes
- Both phones need internet for live synchronization. The app shell may open offline, but new sales are not queued offline.
- Menu costs prefilled from the earlier draft (Rs 80/90/95/85/75; fries unknown) are estimates. Verify/edit them before using profit reports.
- Staff can create sales and expenses and view shared reports/menu. Only Owner can edit menu, record stock purchases, or update/delete business records.
- Profit uses estimated menu ingredient cost. Stock purchases and personal withdrawals are shown separately in cash movement so purchases are not double-counted as ingredient cost.
- Back up CSV reports regularly. Do not share account passwords.
