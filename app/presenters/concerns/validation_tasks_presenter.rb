# frozen_string_literal: true

module ValidationTasksPresenter
  extend ActiveSupport::Concern

  included do
    def items_counter
      ValidationTasks::ItemsCounterPresenter.new(@template, @planning_application).items_count
    end
  end
end
