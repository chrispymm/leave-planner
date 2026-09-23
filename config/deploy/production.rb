server "65.108.60.153", user: "chrispymm", roles: %w[app db web]

set :rails_env, "production"

# `systemctl --user` over a non-interactive SSH command needs XDG_RUNTIME_DIR
# to find the user's systemd bus. This is normally exported automatically by
# pam_systemd on login, but Capistrano's SSH commands aren't logins - setting
# it explicitly avoids relying on lingering alone to make it available.
set :default_env, { "XDG_RUNTIME_DIR" => "/run/user/1002" }
