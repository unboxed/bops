# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check consultees task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }

  %i[planning_permission prior_approval].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, local_authority:)
      end

      it_behaves_like "check consultees task", application_type
    end
  end
end
