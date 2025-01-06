# frozen_string_literal: true

Rails.application.config.after_initialize do
  if defined?(Rails::Server) || defined?(Sidekiq::Processor)
    connection = ActiveRecord::Tasks::DatabaseTasks.migration_connection
    lock_id = ActiveRecord::Migrator::MIGRATOR_SALT * Zlib.crc32(connection.current_database)

    if connection.get_advisory_lock(lock_id)
      connection.release_advisory_lock(lock_id)
      ActiveRecord::Tasks::DatabaseTasks.migrate
    else
      until connection.get_advisory_lock(lock_id)
        warn "waiting 5s for migration lock ..."
        sleep 5
      end
      connection.release_advisory_lock(lock_id)
    end
  end
end
