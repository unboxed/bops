# frozen_string_literal: true

module TaskListItems
  class PolicyClassComponent < TaskListItems::BaseComponent
    def initialize(policy_class:)
      @policy_class = PolicyClassPresenter.new(policy_class)
    end

    private

    attr_reader :policy_class

    def link_text
      I18n.t(
        "policy_classes.title",
        part: policy_class.part,
        class: policy_class.section
      )
    end

    def link_path
      policy_class.default_path
    end

    def status_tag_component
      StatusTags::PolicyClassComponent.new(policy_class: policy_class)
    end
  end
end
