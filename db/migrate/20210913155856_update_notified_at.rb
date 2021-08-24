class UpdateNotifiedAt < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
        PlanningApplication.find_each do |planning_application|
          planning_application.validation_requests.each do |request|
            request.update(notified_at: request.created_at)
          end
        end
      end
    end
  end
end
