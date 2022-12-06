# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusTags::PolicyClassComponent, type: :component do
  let(:policy_class) { create(:policy_class, status: status) }

  before { render_inline(described_class.new(policy_class: policy_class)) }

  context "when status is 'complete'" do
    let(:status) { :complete }

    it "renders 'Complete' status" do
      expect(page).to have_content("Complete")
    end
  end

  context "when status is 'in_assessment'" do
    let(:status) { :in_assessment }

    it "renders 'In progress' status" do
      expect(page).to have_content("In progress")
    end
  end

  context "when status is 'to_be_reviewed'" do
    let(:status) { :to_be_reviewed }

    it "renders 'To be reviewed' status" do
      expect(page).to have_content("To be reviewed")
    end
  end
end
