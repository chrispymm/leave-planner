#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${1:?Usage: test_database_restore.sh BACKUP_DIRECTORY}"

if [[ ! -d "${BACKUP_DIR}" ]]; then
  echo "Backup directory does not exist: ${BACKUP_DIR}" >&2
  exit 1
fi

RESTORE_DIR="$(mktemp -d)"
trap 'find "${RESTORE_DIR}" -mindepth 1 -maxdepth 1 -type f -delete; rmdir "${RESTORE_DIR}"' EXIT

database_count=0
for backup in "${BACKUP_DIR}"/production*.sqlite3; do
  [[ -f "${backup}" ]] || continue

  database_count=$((database_count + 1))
  restored="${RESTORE_DIR}/$(basename "${backup}")"
  sqlite3 "${restored}" ".restore '${backup}'"

  if [[ "$(sqlite3 "${restored}" "PRAGMA integrity_check;")" != "ok" ]]; then
    echo "Restore integrity check failed for $(basename "${backup}")" >&2
    exit 1
  fi
done

if [[ "${database_count}" -eq 0 ]]; then
  echo "No SQLite backups found in ${BACKUP_DIR}" >&2
  exit 1
fi

echo "Successfully restored and verified ${database_count} databases from ${BACKUP_DIR}"
