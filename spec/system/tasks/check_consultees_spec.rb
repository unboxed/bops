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

      context "checking page content" do
        let(:user) { create(:user, local_authority:) }

        before do
          sign_in(user)
          visit "/planning_applications/#{planning_application.reference}/check-and-assess/check-application/check-consultees"
        end

        it "shows the Add consultees link with the correct return path", :capybara do
          expect(page).to have_link(
            "Add consultees",
            href: task_path(
              planning_application,
              "consultees-neighbours-and-publicity/consultees/add-and-assign-consultees",
              return_to: task_path(planning_application, "check-and-assess/check-application/check-consultees")
            )
          )
        end
      end
    end
  end
end
