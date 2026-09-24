#!/usr/bin/env bash
set -euo pipefail

STORAGE_DIR="${1:-/var/www/leave-planner/shared/storage}"
BACKUP_ROOT="${2:-/var/www/leave-planner/shared/backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-14}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"

if [[ ! -d "${STORAGE_DIR}" ]]; then
  echo "Storage directory does not exist: ${STORAGE_DIR}" >&2
  exit 1
fi

mkdir -p "${BACKUP_DIR}"

database_count=0
for database in "${STORAGE_DIR}"/production*.sqlite3; do
  [[ -f "${database}" ]] || continue

  database_count=$((database_count + 1))
  filename="$(basename "${database}")"
  temporary="${BACKUP_DIR}/.${filename}.tmp"
  destination="${BACKUP_DIR}/${filename}"

  sqlite3 "${database}" ".backup '${temporary}'"

  # A backup inherits the source database's WAL journal mode. Convert the
  # offline copy to DELETE mode so each backup is one self-contained file
  # rather than a database plus transient -wal/-shm sidecars.
  integrity_result="$(
    sqlite3 "${temporary}" "PRAGMA journal_mode=DELETE; PRAGMA integrity_check;" |
      tail -n 1
  )"
  if [[ "${integrity_result}" != "ok" ]]; then
    echo "Integrity check failed for backup of ${filename}" >&2
    exit 1
  fi

  if [[ -n "$(sqlite3 "${temporary}" "PRAGMA foreign_key_check;")" ]]; then
    echo "Foreign key check failed for backup of ${filename}" >&2
    exit 1
  fi

  rm -f "${temporary}-wal" "${temporary}-shm"
  mv "${temporary}" "${destination}"
done

if [[ "${database_count}" -eq 0 ]]; then
  echo "No production SQLite databases found in ${STORAGE_DIR}" >&2
  rmdir "${BACKUP_DIR}"
  exit 1
fi

printf 'created_at=%s\ndatabase_count=%d\n' \
  "${TIMESTAMP}" "${database_count}" > "${BACKUP_DIR}/manifest"

# Backup directories contain files only. Delete expired files first, then
# remove their now-empty directories without recursive deletion.
while IFS= read -r -d '' expired_dir; do
  find "${expired_dir}" -mindepth 1 -maxdepth 1 -type f -delete
  rmdir "${expired_dir}"
done < <(
  find "${BACKUP_ROOT}" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -name '20??????T??????Z' \
    -mtime "+${RETENTION_DAYS}" \
    -print0
)

echo "${BACKUP_DIR}"
