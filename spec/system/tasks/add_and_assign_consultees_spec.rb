# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add and assign consultees task", type: :system do
  let(:path_prefix) { "planning_applications" }
  let(:slug_path) { "consultees-neighbours-and-publicity/consultees/add-and-assign-consultees" }

  %i[prior_approval planning_permission].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :in_assessment, :published, local_authority:, api_user:)
      end

      it_behaves_like "add and assign consultees task", application_type
    end
  end
end
