# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocalAuthority, type: :model do
  describe "validations" do
    subject(:local_authority) { described_class.new }

    describe "#subdomain" do
      it "validates presence" do
        expect { local_authority.valid? }.to change { local_authority.errors[:subdomain] }.to ["can't be blank"]
      end

      it "raises an error with wrong type" do
        expect { build(:local_authority, subdomain: "new_name") }
          .to raise_error(ArgumentError)
          .with_message(/is not a valid subdomain/)
      end
    end

    describe "#signatory" do
      let(:local_authority) do
        build(
          :local_authority,
          :lambeth,
          signatory_name: "Jane Smith",
          signatory_job_title: "Director"
        )
      end

      it "#council_code" do
        expect(local_authority.council_code).to eq("LBH")
      end

      it "returns signatory name and job title" do
        expect(local_authority.signatory).to eq("Jane Smith, Director")
      end
    end
  end
end
