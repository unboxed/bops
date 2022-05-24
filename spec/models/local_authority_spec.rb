# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocalAuthority, type: :model do
  describe "validations" do
    subject(:local_authority) { described_class.new }

    describe "#council_code" do
      it "validates presence" do
        expect { local_authority.valid? }.to change { local_authority.errors[:council_code] }.to ["can't be blank"]
      end
    end

    describe "#signatory" do
      let(:local_authority) do
        build(
          :local_authority,
          signatory_name: "Jane Smith",
          signatory_job_title: "Director"
        )
      end

      it "returns signatory name and job title" do
        expect(local_authority.signatory).to eq("Jane Smith, Director")
      end
    end
  end
end
