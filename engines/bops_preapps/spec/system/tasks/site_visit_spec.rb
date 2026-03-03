# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site visit task", type: :system do
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }

  it_behaves_like "site visit task", :pre_application, "check-and-assess/additional-services/site-visit"
end
