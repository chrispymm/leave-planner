# config valid for current version and patch releases of Capistrano
lock "~> 3.20.1"

set :application, "leave_planner"
set :repo_url, "https://github.com/chrispymm/leave-planner.git"

set :branch, ENV.fetch("BRANCH", "main")

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/var/www/leave-planner"

# --- rbenv (capistrano-rbenv) -----------------------------------------------
# Installed under the deploy user's own home directory ($HOME/.rbenv, the
# gem's :user default) - no sudo needed for rbenv or the Ruby build itself.
# Only rbenv's OS-level *build dependencies* (openssl, libyaml-dev, etc.)
# need a one-off sudo install; see bin/deploy/server_bootstrap.sh.
set :rbenv_type, :user
set :rbenv_ruby, File.read(File.expand_path("../.ruby-version", __dir__)).strip.sub(/\Aruby-/, "")

# --- Linked files/dirs -------------------------------------------------------
# storage/ holds the four production SQLite databases (primary, cache, queue,
# cable). This is the single most important line in this file - without it,
# every deploy would silently start from an empty database.
# config/master.key must reach the server but must NEVER be committed - the
# GitHub repo for this project is public.
append :linked_files, "config/master.key"
append :linked_dirs,
  "log",
  "storage",
  "tmp/pids",
  "tmp/cache",
  "tmp/sockets",
  "public/assets"

set :keep_releases, 5

# --- Puma (capistrano3-puma) -------------------------------------------------
# Managed as a *user-level* systemd unit (systemctl --user), which needs no
# sudo at all for install/start/stop/restart - a good fit since the deploy
# user has no passwordless sudo on this box. The one sudo call systemd
# integration would otherwise make (`loginctl enable-linger`, so the user
# service keeps running without an active login session) is disabled here
# and must be run once, manually, by bin/deploy/server_bootstrap.sh instead.
set :puma_systemctl_user, :user
set :puma_enable_lingering, false
set :puma_service_unit_name, -> { "#{fetch(:application)}-puma-#{fetch(:stage)}" }
set :puma_enable_socket_service, false

# Note: capistrano3-puma 8.1.0's systemd template does not thread `puma_bind`
# through to the generated unit's ExecStart line (verified in the gem
# source) - the bind actually used is whatever config/puma.rb sets. That
# file binds explicitly to 127.0.0.1:3000 (loopback only), which nginx
# proxies to below - functionally equivalent to a Unix socket for this
# single-app box, and keeps config/puma.rb identical to a stock Rails app.
set :puma_threads, [ 2, 4 ]
set :puma_workers, 0 # single-mode: this is a 1 CPU box, forking workers would only add memory overhead
set :puma_preload_app, true

# Runs the Solid Queue supervisor inside the Puma process
# (config/puma.rb already has `plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]`)
# rather than a second systemd unit and a second Ruby process - the right
# trade-off on a 1 CPU / 2GB box serving one low-traffic app.
set :puma_service_unit_env_vars, [
  "SOLID_QUEUE_IN_PUMA=true",
  "APP_HOST=leave.chrispymm.co.uk"
]

# Unlike Kamal's gapless container swap, a Capistrano deploy stops the old
# Puma process before the new one starts, so there is no overlapping-writer
# window - migrations can run unconditionally before the restart.
before "deploy:publishing", "deploy:migrate"
