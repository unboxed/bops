# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::PolicyClassComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:policy_class) do
    create(
      :policy_class,
      section: "A",
      part: 1,
      planning_application: planning_application,
      status: status
    )
  end

  before { render_inline(described_class.new(policy_class: policy_class)) }

  context "when status is 'complete'" do
    let(:status) { :complete }

    it "renders link to policy_class" do
      expect(page).to have_link(
        "Part 1, Class A",
        href: "/planning_applications/#{planning_application.id}/policy_classes/#{policy_class.id}"
      )
    end
  end

  context "when status is not 'complete'" do
    let(:status) { :in_assessment }

    it "renders link edit to policy_class" do
      expect(page).to have_link(
        "Part 1, Class A",
        href: "/planning_applications/#{planning_application.id}/policy_classes/#{policy_class.id}/edit"
      )
    end
  end
end
