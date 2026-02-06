# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check fee task", type: :system do
  %i[planning_permission lawfulness_certificate prior_approval].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :not_started, local_authority:)
      end

      it_behaves_like "check fee task", application_type
    end
  end
end
