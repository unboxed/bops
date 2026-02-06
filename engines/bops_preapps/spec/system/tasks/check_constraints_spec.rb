# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check constraints task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:api_user) { create(:api_user, :planx, local_authority:) }
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, :with_constraints, local_authority:, api_user:) }

  it_behaves_like "check constraints task", :pre_application
end
