# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check constraints task", type: :system do
  %i[planning_permission lawfulness_certificate prior_approval].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :not_started, :with_constraints, local_authority:, api_user:)
      end

      it_behaves_like "check constraints task", application_type
    end
  end
end
