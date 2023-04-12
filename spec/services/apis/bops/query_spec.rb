# frozen_string_literal: true

require "rails_helper"

RSpec.describe Apis::Bops::Query do
  let(:planning_application) { create(:planning_application, :from_planx) }

  describe ".fetch" do
    it "initializes a Client object with planning application audit log and invokes #call" do
      expect_any_instance_of(Apis::Bops::Client).to receive(:call).with(
        planning_application.local_authority.subdomain,
        planning_application
      ).and_call_original

      described_class.new.post(planning_application.local_authority.subdomain, planning_application)
    end
  end
end
