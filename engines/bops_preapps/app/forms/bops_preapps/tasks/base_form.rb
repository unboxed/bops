# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class BaseForm
      include ActiveModel::Model
      include ActiveModel::Attributes
      include BopsPreapps::Engine.routes.url_helpers
      include BeforeTypeCast #the form is using ActiveRecord not ActiveModel and the 
      #rails methods are not avaiable on active record so I implemented a custom concern on the engine.

      attr_reader :task, :case_record, :planning_application
      delegate :parent, to: :task

      def initialize(task)
        super({})
        @task = task
        @case_record = @task.case_record
        @planning_application = @task.case_record.planning_application

      end

      def update(params)
        task.update(params)
      end

      def permitted_fields(params)
        params.require(:task).permit(:status, :started_at, :completed_at)
      end

      def redirect_url
        task_path(planning_application, task)
      end
    end
  end
end
