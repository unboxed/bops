# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::PolicyClassComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:policy_class) do
    create(
      :policy_class,
      status: status,
      planning_application: planning_application
    )
  end

  context "when review is needed" do
    let(:status) { :to_be_reviewed }

    before do
      create(
        :review_policy_class,
        status: :complete,
        mark: :return_to_officer_with_comment,
        policy_class: policy_class,
        comment: "comment"
      )

      create(
        :recommendation,
        status: :review_complete,
        challenged: true,
        planning_application: planning_application,
        reviewer_comment: "comment"
      )

      render_inline(
        described_class.new(
          planning_application: planning_application,
          policy_class: policy_class
        )
      )
    end

    it "renders 'To be reviewed' status" do
      expect(page).to have_content("To be reviewed")
    end
  end

  context "when status is 'complete'" do
    let(:status) { :complete }

    before do
      render_inline(
        described_class.new(
          planning_application: planning_application,
          policy_class: policy_class
        )
      )
    end

    it "renders 'Complete' status" do
      expect(page).to have_content("Complete")
    end
  end

  context "when status is 'in_assessment'" do
    let(:status) { :in_assessment }

    before do
      render_inline(
        described_class.new(
          planning_application: planning_application,
          policy_class: policy_class
        )
      )
    end

    it "renders 'In progress' status" do
      expect(page).to have_content("In progress")
    end
  end
end
