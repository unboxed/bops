# frozen_string_literal: true

require "zlib"

module Bops
  class AutoMigrator
    LOCK_KEY = Zlib.crc32(name)

    class << self
      def migrate
        new.migrate
      end
    end

    def migrate
      return unless auto_migrate?

      with_connection do |connection|
        unless migration_context.needs_migration?
          logger.info("[auto_migrator] No pending migrations.")
          return
        end

        logger.info("[auto_migrator] Attempting to acquire advisory lock #{LOCK_KEY} ...")

        lock_acquired = false
        started_at = current_time
        deadline = started_at + wait_timeout

        loop do
          lock_acquired = try_advisory_lock(connection)
          break if lock_acquired
          break if current_time >= deadline

          sleep poll_interval
        end

        unless lock_acquired
          duration = (monotonic_now - started_at).round(1)

          logger.warn(
            "[auto_migrator] Could not acquire lock after #{duration}s " \
            "(timeout: #{wait_timeout}s). Another process is likely " \
            "migrating. Continuing boot without migrating."
          )

          return
        end

        begin
          # Re-check after acquiring the lock: another process may have
          # already migrated while we were waiting/polling.
          if migration_context.needs_migration?
            logger.info("[auto_migrator] Lock acquired. Pending migrations found, migrating ...")
            migration_context.migrate
            logger.info("[auto_migrator] Migrations complete.")
          else
            logger.info("[auto_migrator] Lock acquired, but no pending migrations (already applied by another process).")
          end
        rescue => e
          logger.error("[auto_migrator] Migration failed: #{e.class}: #{e.message}")
          raise
        ensure
          release_advisory_lock(connection)
          logger.info("[auto_migrator] Advisory lock released.")
        end
      end
    end

    private

    def database_tasks
      ActiveRecord::Tasks::DatabaseTasks
    end

    def connection_pool
      @connection_pool ||= database_tasks.migration_connection_pool
    end

    def with_connection(&)
      connection_pool.with_connection(&)
    end

    def migration_context
      @migration_context ||= connection_pool.migration_context
    end

    def enabled?
      ENV.fetch("BOPS_AUTO_MIGRATOR_ENABLED", "true") == "true"
    end

    def booting_puma?
      # `bin/puma` / `bundle exec puma` sets $PROGRAM_NAME to the puma
      # executable path from process start, before any app code runs.
      return true if defined?(::Puma::CLI) && $PROGRAM_NAME.to_s.match?(/puma/i)

      # `bin/rails server` (or its `s` alias) boots Puma internally via
      # Rails::Server, often without renaming the process — so
      # $PROGRAM_NAME may still read "bin/rails" here. Fall back to
      # checking the command that was invoked.
      return true if defined?(::Rails::Server) && ARGV.first.to_s.match?(/\A(server|s)\z/)

      false
    end

    def booting_sidekiq?
      defined?(::Sidekiq::CLI) && $PROGRAM_NAME.to_s.match?(/sidekiq/i)
    end

    def auto_migrate?
      return false unless enabled?
      return false unless booting_puma? || booting_sidekiq?

      true
    end

    def try_advisory_lock(connection)
      connection.get_advisory_lock(LOCK_KEY)
    end

    def release_advisory_lock(connection)
      connection.release_advisory_lock(LOCK_KEY)
    end

    def current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def wait_timeout
      ENV.fetch("BOPS_AUTO_MIGRATOR_WAIT_TIMEOUT", "60").to_i
    end

    def poll_interval
      ENV.fetch("BOPS_AUTO_MIGRATOR_POLL_INTERVAL", "0.5").to_f
    end

    def logger
      Rails.logger
    end
  end
end
