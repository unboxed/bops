# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check site history task", type: :system do
  %i[planning_permission lawfulness_certificate prior_approval].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :in_assessment, local_authority:)
      end

      it_behaves_like "check site history", application_type
    end
  end
end
