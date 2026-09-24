# Annual Leave Planner — working instructions

A small Rails app for planning annual leave across the members of a household
or team. It shows a rolling 12-month calendar of leave, UK bank holidays and
user-defined extra calendars (school holidays, term dates, and so on).

## Critical safety rules

Read these before running anything destructive.

1. **`storage/development.sqlite3` holds real data and is the only local copy.**
   Treat it as production data. Take a backup before migrations, schema
   changes, `db:reset`, or anything else that could lose rows:
   `sqlite3 storage/development.sqlite3 ".backup db/backups/development_$(date +%Y%m%d_%H%M%S).sqlite3"`.
   Use SQLite's `.backup` command rather than `cp`, because the database runs
   in WAL mode and a plain copy can miss committed data.
2. **The GitHub repository (`chrispymm/leave-planner`) is public.** Never
   commit `config/master.key`, any `.sqlite3` file, database backups, or real
   credentials. `.gitignore` already covers `storage/*`, `db/backups/` and
   `config/master.key` — do not weaken those rules.
3. **The production server also runs an unrelated Kirby PHP site.** Never
   change shared nginx config, PHP-FPM, or firewall rules for the whole host.
   Only the `leave.chrispymm.co.uk` vhost belongs to this app, and
   `chrispymm.co.uk` must keep working after any server change.

## Stack and conventions

- Rails 8.1 on Ruby 4.0.7 (`.ruby-version`), SQLite in every environment.
- Hotwire (Turbo + Stimulus) for interactivity. Stimulus controllers live in
  `app/javascript/controllers/`, loaded through importmap. **Do not add a
  Node build step or a JS framework.**
- Pico.css plus plain, hand-written CSS. **Do not introduce Tailwind or any
  utility-class framework** — this was an explicit product decision.
- Solid Queue, Solid Cache and Solid Cable, each in its own SQLite database.
- Stay close to Rails defaults and idioms; prefer built-in Rails features over
  new dependencies.
- Comment only genuinely non-obvious code.

## Domain model

`Account` is the top-level tenant. `User` records sign in; `Membership` links
users to accounts, and `Invitation` adds new members. Authentication is the
stock Rails generator setup (`Session`, `Current`,
`app/controllers/concerns/authentication.rb`) — not Devise.

`Person` is someone whose leave is tracked. It is deliberately separate from
`User`, so you can plan for a partner who never signs in. Key fields:

- `allowance_unit` is `days` or `hours`; `hours_per_day` converts between them.
- `include_bank_holidays` decides whether bank holidays consume allowance.
- `leave_year_start_month` / `leave_year_start_day` support non-calendar leave
  years, so **never assume a leave year starts in January**.
- `initial_remaining_allowance` / `initial_allowance_date` let someone start
  mid-year with a known balance instead of backfilling history.

`LeaveEntry` is one row per person per day (unique on `person_id` + `date`),
supporting half days and `custom_hours`. `LeaveRange` is **not** a database
table — it is an `ActiveModel` object in `app/models/leave_range.rb` that
groups contiguous `LeaveEntry` rows into a single bookable range for the UI.

`BankHoliday` rows sync from the GOV.UK API via
`app/services/uk_bank_holidays_service.rb`, scheduled weekly in
`config/recurring.yml` and also available through `lib/tasks/bank_holidays.rake`.
`AdditionalCalendar` and `AdditionalCalendarEntry` are account-scoped custom
calendars with a name, description and colour.

## Calendar behaviour

- The default view shows 12 months starting from **the month before the
  current month**; next/previous move by 12 months. Shared logic lives in
  `app/controllers/concerns/calendar_window.rb`.
- Layout is either `grid` or `list`, persisted per user in
  `users.calendar_layout` and toggled via `CalendarLayoutsController`. It is
  **not** driven by a query parameter; that approach was removed deliberately.

## Everyday commands

```bash
bin/setup                 # install dependencies and prepare the database
bin/dev                   # run the app locally
bin/rails test            # full test suite (Minitest, fixtures)
bin/rails test test/models/person_test.rb    # single file
bin/rubocop               # lint (rails-omakase); CI runs this
bin/brakeman --no-pager   # security scan, also in CI
```

Run `bin/rails test` and `bin/rubocop` before committing. CI additionally runs
Brakeman, `bundler-audit`, `importmap audit` and system tests.

## Deployment

Live at **https://leave.chrispymm.co.uk**, deployed with **Capistrano** to a
VPS that also hosts an unrelated Kirby PHP site. Kamal is intentionally not
used, to avoid disturbing the existing nginx/PHP setup.

```bash
bundle exec cap production deploy            # deploy main
bundle exec cap production deploy:rollback   # roll back one release
bundle exec cap production database:backup   # manual backup (also runs pre-deploy)
```

How it fits together:

- Config lives in `Capfile`, `config/deploy.rb` and `config/deploy/production.rb`.
- Ruby is installed per-user with rbenv; the server has no passwordless sudo,
  so ordinary deploys use **no sudo at all**.
- Puma runs as a **user-level systemd unit** (`systemctl --user`), which is why
  no sudoers rule is needed. Commands need `XDG_RUNTIME_DIR=/run/user/1002`
  when run manually over SSH.
- Puma binds to **127.0.0.1:3000 only** (set in `config/puma.rb`) and nginx
  proxies to it. Keep the loopback bind: `capistrano3-puma` does *not* pass
  `puma_bind` into the generated systemd unit, so `config/puma.rb` is the only
  thing controlling the bind address.
- Solid Queue runs inside Puma via `SOLID_QUEUE_IN_PUMA=true`, to keep memory
  use low on a 1 CPU / 2 GB host.
- `config/master.key` and the `storage/` directory are Capistrano *linked*
  paths kept in `shared/`, so databases survive deploys. `master.key` must be
  placed on the server manually, since it is never committed.
- Root-only, one-time setup is scripted in `bin/deploy/server_bootstrap.sh`
  (build dependencies, systemd lingering, the nginx vhost). TLS uses Certbot
  with automatic renewal.

Backups: `bin/deploy/backup_databases.sh` makes verified, self-contained
copies of all four production databases nightly (systemd timer) and before
every deploy, keeping 14 days. `bin/deploy/test_database_restore.sh` restores
a backup set into temporary files and verifies it — use it rather than
assuming a backup is good.
