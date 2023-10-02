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

      it "returns signatory name and job title" do
        expect(local_authority.signatory).to eq("Jane Smith, Director")
      end
    end
  end

  describe "#council_code" do
    let(:local_authority) { build(:local_authority, :lambeth) }

    it "returns council code" do
      expect(local_authority.council_code).to eq("LBH")
    end

    context "when it changes to PlanX" do
      it "returns council code" do
        local_authority.council_code = "PlanX"
        local_authority.save!

        expect(local_authority.council_code).to eq("PlanX")
      end
    end

    context "when not valid council code" do
      let(:local_authority) do
        build(:local_authority, council_code: "TEST")
      end

      it "is invalid" do
        expect { local_authority.valid? }.to change { local_authority.errors[:council_code] }.to ["Please enter a valid council code"]
      end
    end
  end

  describe "#council_name" do
    let(:local_authority) { build(:local_authority, subdomain: "lambeth") }

    it "returns the council name" do
      expect(local_authority.council_name).to eq("Lambeth Council")
    end

    context "when the subdomain has a hyphen" do
      let(:local_authority) { build(:local_authority, subdomain: "great-yarmouth") }

      it "returns the council name" do
        expect(local_authority.council_name).to eq("Great Yarmouth Council")
      end
    end
  end

  describe "#formatted_subdomain" do
    let(:local_authority) { build(:local_authority, subdomain: "lambeth") }

    it "returns a formatted name" do
      expect(local_authority.formatted_subdomain).to eq("Lambeth")
    end

    context "when the subdomain has a hyphen" do
      let(:local_authority) { build(:local_authority, subdomain: "great-yarmouth") }

      it "returns a formatted name" do
        expect(local_authority.formatted_subdomain).to eq("Great Yarmouth")
      end
    end
  end
end
