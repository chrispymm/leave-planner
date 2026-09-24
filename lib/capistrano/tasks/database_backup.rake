namespace :database do
  desc "Back up the production SQLite databases before deploying"
  task :backup do
    on fetch(:migration_servers) do
      backup_script = "#{current_path}/bin/deploy/backup_databases.sh"

      if test("[ -x #{backup_script} ]")
        execute backup_script, "#{shared_path}/storage", "#{shared_path}/backups"
      else
        warn "Skipping pre-deploy database backup: #{backup_script} is not installed yet"
      end
    end
  end
end

before "deploy:starting", "database:backup"
