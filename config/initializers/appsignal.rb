# frozen_string_literal: true

# Set a gauge for the number of pending applications and trigger an alarm if > 0
Appsignal::Probes.register(:pending_applications, -> {
  pending_applications = PlanningApplication.kept.pending.where(created_at: 1.month.ago...5.minutes.ago)
  Appsignal.set_gauge("pending_applications", pending_applications.count)
})
