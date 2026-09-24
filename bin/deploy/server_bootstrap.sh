#!/usr/bin/env bash
# One-time server setup for deploying leave_planner via Capistrano.
#
# Run this ONCE, on the VPS (65.108.60.153), as the chrispymm user, with:
#
#   sudo bash server_bootstrap.sh
#
# It only touches things this app needs: a handful of apt packages, one
# systemd/login setting, and a new nginx vhost. It does NOT modify the
# existing chrispymm.co.uk / catch-all nginx vhosts, PHP-FPM, or anything
# already running on this box.
#
# Everything else (rbenv, Ruby, the app itself, its systemd --user unit) is
# installed by Capistrano as the unprivileged chrispymm user and needs no
# sudo at all - that is deliberate, since chrispymm has no passwordless sudo
# and this script is the one place root access is used.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run this with sudo: sudo bash $0" >&2
  exit 1
fi

DEPLOY_USER="chrispymm"
DOMAIN="leave.chrispymm.co.uk"

echo "==> Installing Ruby build dependencies (build-essential, libssl-dev,"
echo "    zlib1g-dev and git are already present; adding the rest)"
apt-get update -qq
apt-get install -y \
  libyaml-dev \
  libreadline-dev \
  libsqlite3-dev \
  libffi-dev \
  libncurses5-dev \
  autoconf \
  patch \
  uuid-dev

echo "==> Enabling lingering for ${DEPLOY_USER}"
echo "    (keeps 'systemctl --user' services running without an active SSH"
echo "    session or login - required for Puma to survive after you log out,"
echo "    and to start automatically on reboot)"
loginctl enable-linger "${DEPLOY_USER}"

echo "==> Creating nginx vhost for ${DOMAIN}"
cat > "/etc/nginx/sites-available/${DOMAIN}" <<NGINX
upstream leave_planner_puma {
  # Puma binds to loopback only (config/puma.rb) - not a Unix socket, since
  # capistrano3-puma's systemd template doesn't thread a custom bind through
  # to the generated unit (verified against gem source).
  server 127.0.0.1:3000 fail_timeout=0;
}

server {
  listen 80;
  listen [::]:80;
  server_name ${DOMAIN};

  root /var/www/leave-planner/current/public;

  location ^~ /assets/ {
    expires max;
    add_header Cache-Control public;
  }

  try_files \$uri/index.html \$uri @puma;

  location @puma {
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_pass http://leave_planner_puma;
  }

  client_max_body_size 10M;
  keepalive_timeout 10;
}
NGINX

ln -sf "/etc/nginx/sites-available/${DOMAIN}" "/etc/nginx/sites-enabled/${DOMAIN}"

echo "==> Testing nginx config before reloading"
nginx -t

echo "==> Reloading nginx"
echo "    (this reloads ALL vhosts, including chrispymm.co.uk / catch-all -"
echo "    'nginx -t' above must have passed, so existing sites are safe)"
systemctl reload nginx

echo
echo "Bootstrap complete. Next steps (as ${DEPLOY_USER}, no sudo needed):"
echo "  1. Install rbenv + Ruby ${RUBY_VERSION:-4.0.7} as ${DEPLOY_USER}, then"
echo "     run this from your local machine: bundle exec cap production deploy"
echo "  2. Install and start Puma's user-level systemd unit once:"
echo "       bundle exec cap production puma:install"
echo "       bundle exec cap production puma:start"
echo "  3. Once public DNS points here, get a TLS certificate:"
echo "       sudo certbot --nginx -d ${DOMAIN} --redirect"
echo "     (safe to run any time after nginx is serving the vhost; only"
echo "     touches the ${DOMAIN} server block, not the other vhosts)"
