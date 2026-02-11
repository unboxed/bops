# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check consultees task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }

  it_behaves_like "check consultees task", :pre_application
end
