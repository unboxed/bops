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

  describe "#applicants_url" do
    let(:local_authority) { build(:local_authority, :lambeth) }
    before do
      allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return(bops_env)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(rails_env))
    end

    context "when in production" do
      let(:bops_env) { "production" }
      let(:rails_env) { bops_env }

      it "returns the database value" do
        expect(local_authority.applicants_url).to eq(local_authority[:applicants_url])
      end
    end

    context "when in staging" do
      let(:bops_env) { "staging" }
      let(:rails_env) { "production" }

      it "does not return the database value" do
        expect(local_authority.applicants_url).not_to eq(local_authority[:applicants_url])
      end

      it "returns the configured value" do
        # nb. because this is set at startup time, it won't get the staging version from the production
        # config; instead it gets the test version.
        expect(local_authority.applicants_url).to eq("https://#{local_authority.subdomain}.bops-applicants.services")
      end
    end

    context "when in development" do
      let(:bops_env) { "development" }
      let(:rails_env) { bops_env }

      it "does not return the database value" do
        expect(local_authority.applicants_url).not_to eq(local_authority[:applicants_url])
      end

      it "returns the configured value" do
        expect(local_authority.applicants_url).to eq("https://#{local_authority.subdomain}.bops-applicants.services")
      end
    end
  end

  describe "#public_register_base_url" do
    let(:local_authority) { build(:local_authority, :lambeth) }
    before do
      allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return(bops_env)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(rails_env))
    end

    context "when in production" do
      let(:bops_env) { "production" }
      let(:rails_env) { bops_env }

      context "when is nil" do
        it "does not return the database value" do
          expect(local_authority.public_register_base_url).not_to eq(local_authority[:public_register_base_url])
        end
      end

      context "when is configured at database level" do
        before do
          local_authority.update!(public_register_base_url: "https://planning_register.services/#{local_authority.subdomain}")
        end

        it "returns the database value" do
          expect(local_authority.public_register_base_url).to eq(local_authority[:public_register_base_url])
        end
      end
    end

    context "when in staging" do
      let(:bops_env) { "staging" }
      let(:rails_env) { "production" }

      it "does not return the database value" do
        expect(local_authority.public_register_base_url).not_to eq(local_authority[:public_register_base_url])
      end

      it "returns the configured value" do
        # nb. because this is set at startup time, it won't get the staging version from the production
        # config; instead it gets the test version.
        expect(local_authority.public_register_base_url).to eq("https://#{local_authority.subdomain}.bops-applicants.services")
      end
    end

    context "when in development" do
      let(:bops_env) { "development" }
      let(:rails_env) { bops_env }

      it "does not return the database value" do
        expect(local_authority.public_register_base_url).not_to eq(local_authority[:public_register_base_url])
      end

      it "returns the configured value" do
        expect(local_authority.public_register_base_url).to eq("https://#{local_authority.subdomain}.bops-applicants.services")
      end
    end
  end
end
