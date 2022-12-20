# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocalAuthority do
  describe "validations" do
    subject(:local_authority) { described_class.new }

    describe "#reviewer_group_email" do
      context "when blank" do
        let(:local_authority) do
          build(:local_authority, reviewer_group_email: nil)
        end

        it "is valid" do
          expect(local_authority.valid?).to be(true)
        end
      end

      context "when a valid email" do
        let(:local_authority) do
          build(:local_authority, reviewer_group_email: "list@example.com")
        end

        it "is valid" do
          expect(local_authority.valid?).to be(true)
        end
      end

      context "when not a valid email" do
        let(:local_authority) do
          build(:local_authority, reviewer_group_email: "qwerty")
        end

        it "is invalid" do
          expect(local_authority.valid?).to be(false)
        end
      end
    end

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

    describe "#signatory_name" do
      it "validates presence" do
        expect { local_authority.valid? }.to change { local_authority.errors[:signatory_name] }.to ["can't be blank"]
      end
    end

    describe "#signatory_job_title" do
      it "validates presence" do
        expect { local_authority.valid? }.to change { local_authority.errors[:signatory_job_title] }.to ["can't be blank"]
      end
    end

    describe "#enquiries_paragraph" do
      it "validates presence" do
        expect { local_authority.valid? }.to change { local_authority.errors[:enquiries_paragraph] }.to ["can't be blank"]
      end
    end

    describe "#email_address" do
      it "validates presence" do
        expect { local_authority.valid? }.to change { local_authority.errors[:email_address] }.to ["can't be blank"]
      end
    end

    describe "#feedback_email" do
      it "validates presence" do
        expect { local_authority.valid? }.to change { local_authority.errors[:feedback_email] }.to ["can't be blank"]
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

  describe "#council_name" do
    let(:southwark) { create(:local_authority, :southwark) }

    it "has Southwark Council council_name" do
      expect(southwark.council_name).to eq("Southwark Council")
    end
  end

  describe "#staging?" do
    it "returns false when staging env is not set" do
      local_authority = create(:local_authority, :southwark)

      expect(local_authority).not_to be_staging
    end

    it "returns false when staging env is not set to false" do
      allow(ENV).to receive(:fetch).with("STAGING_ENABLED", "false").and_return("false")
      local_authority = create(:local_authority, :southwark)

      expect(local_authority).not_to be_staging
    end

    it "returns true when staging env set" do
      allow(ENV).to receive(:fetch).with("STAGING_ENABLED", "false").and_return("true")
      local_authority = create(:local_authority, :southwark)

      expect(local_authority).to be_staging
    end
  end
end
