# frozen_string_literal: true

module StatusTags
  class PublishDeterminationComponent < StatusTags::BaseComponent
    def initialize(planning_application:, user:)
      @planning_application = planning_application
      @user = user
      super(status:)
    end

    private

    attr_reader :planning_application, :user

    def status
      if planning_application.publish_complete?
        :complete
      elsif planning_application.ready_to_publish? && user.assessor?
        :waiting
      end
    end
  end
end
