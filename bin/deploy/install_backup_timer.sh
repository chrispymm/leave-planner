#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="/var/www/leave-planner/current/config/deploy/systemd"
UNIT_DIR="${HOME}/.config/systemd/user"
SERVICE="leave-planner-backup.service"
TIMER="leave-planner-backup.timer"

mkdir -p "${UNIT_DIR}"
install -m 0644 "${SOURCE_DIR}/${SERVICE}" "${UNIT_DIR}/${SERVICE}"
install -m 0644 "${SOURCE_DIR}/${TIMER}" "${UNIT_DIR}/${TIMER}"

systemctl --user daemon-reload
systemctl --user enable --now "${TIMER}"
systemctl --user list-timers "${TIMER}" --no-pager
