# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationType do
  describe "#validations" do
    subject(:application_type) { described_class.new }

    describe "#name" do
      it "validates presence" do
        expect { application_type.valid? }.to change { application_type.errors[:name] }.to ["can't be blank"]
      end
    end

    describe "#code" do
      it "validates presence" do
        expect { application_type.valid? }.to change { application_type.errors[:code] }.to ["Select an application type name"]
      end

      context "when the code isn't in the allowed list" do
        subject(:application_type) { described_class.new(code: "pp.invalid") }

        it "validates inclusion" do
          expect { application_type.valid? }.to change { application_type.errors[:code] }.to ["Select a valid application type name"]
        end
      end

      context "when the code already exists" do
        subject(:application_type) { described_class.new(code: "pp.full.householder") }

        before do
          create(:application_type, :planning_permission)
        end

        it "validates uniqueness" do
          expect { application_type.valid? }.to change { application_type.errors[:code] }.to ["There is already an application type for that name"]
        end
      end

      context "when an application type is inactive" do
        subject(:application_type) { create(:application_type, :ldc_proposed, status: "inactive") }

        before do
          application_type.code = "ldc"
        end

        it "allows the updating of the code" do
          expect { application_type.valid? }.not_to change { application_type.errors[:code] }.from []
        end
      end

      context "when an application type is active" do
        subject(:application_type) { create(:application_type, :ldc_proposed, status: "active") }

        before do
          application_type.code = "ldc"
        end

        it "prevents the updating of the code" do
          expect { application_type.valid? }.to change { application_type.errors[:code] }.to ["The name can't be changed when the application type is active"]
        end
      end

      context "when an application type is retired" do
        subject(:application_type) { create(:application_type, :ldc_proposed, status: "retired") }

        before do
          application_type.code = "ldc"
        end

        it "prevents the updating of the code" do
          expect { application_type.valid? }.to change { application_type.errors[:code] }.to ["The name can't be changed when the application type is retired"]
        end
      end
    end

    describe "#suffix" do
      it "validates presence" do
        expect { application_type.valid? }.to change { application_type.errors[:suffix] }.to ["Enter a suffix for the application number"]
      end

      context "when the suffix is too short" do
        subject(:application_type) { described_class.new(suffix: "P") }

        it "validates length" do
          expect { application_type.valid? }.to change { application_type.errors[:suffix] }.to ["The suffix must be at least 2 characters long"]
        end
      end

      context "when the suffix is too long" do
        subject(:application_type) { described_class.new(suffix: "PPPPPPP") }

        it "validates length" do
          expect { application_type.valid? }.to change { application_type.errors[:suffix] }.to ["The suffix must be at most 6 characters long"]
        end
      end

      context "when the suffix uses invalid characters" do
        subject(:application_type) { described_class.new(suffix: "pppp") }

        it "validates format" do
          expect { application_type.valid? }.to change { application_type.errors[:suffix] }.to ["The suffix must only use uppercase letters and numbers"]
        end
      end

      context "when the suffix already exists" do
        subject(:application_type) { described_class.new(suffix: "LDCP") }

        before do
          create(:application_type, :ldc_proposed)
        end

        it "validates uniqueness" do
          expect { application_type.valid? }.to change { application_type.errors[:suffix] }.to ["There is already an application type with that suffix"]
        end
      end

      context "when an application type is inactive" do
        subject(:application_type) { create(:application_type, :ldc_proposed, status: "inactive") }

        before do
          application_type.suffix = "LDC"
        end

        it "allows the updating of the suffix" do
          expect { application_type.valid? }.not_to change { application_type.errors[:suffix] }.from []
        end
      end

      context "when an application type is active" do
        subject(:application_type) { create(:application_type, :ldc_proposed, status: "active") }

        before do
          application_type.suffix = "LDC"
        end

        it "prevents the updating of the suffix" do
          expect { application_type.valid? }.to change { application_type.errors[:suffix] }.to ["The suffix can't be changed when the application type is active"]
        end
      end

      context "when an application type is retired" do
        subject(:application_type) { create(:application_type, :ldc_proposed, status: "retired") }

        before do
          application_type.suffix = "LDC"
        end

        it "prevents the updating of the suffix" do
          expect { application_type.valid? }.to change { application_type.errors[:suffix] }.to ["The suffix can't be changed when the application type is retired"]
        end
      end
    end

    describe "#features" do
      describe "#consultation_steps" do
        let(:application_type) { described_class.new(features: {consultation_steps: ["Invalid"]}) }

        it "validates the steps" do
          expect { application_type.valid? }.to change { application_type.features.errors[:consultation_steps] }.to ["contains invalid steps: Invalid"]
        end
      end
    end
  end

  describe "class methods" do
    describe "#menu" do
      let!(:lawfulness_certificate) { create(:application_type) }
      let!(:prior_approval) { create(:application_type, :prior_approval) }

      it "returns an array of application type names (humanized) and ids" do
        expect(described_class.menu).to eq(
          [
            ["Prior Approval - Larger extension to a house", prior_approval.id],
            ["Lawful Development Certificate - Existing use", lawfulness_certificate.id]
          ]
        )
      end
    end
  end

  describe "legislation details" do
    context "when planning application type has legislation details defined in en.yml translation" do
      let!(:application_type) { create(:application_type, :prior_approval, part: 1, section: "A") }

      describe "legislation_link" do
        it "returns the legislation link" do
          expect(application_type.legislation_link).to eq("https://www.legislation.gov.uk/uksi/2015/596/schedule/2/made")
        end
      end

      describe "legislation_link_text" do
        it "returns the legislation link text" do
          expect(application_type.legislation_link_text).to eq("The Town and Country Planning (General Permitted Development) (England) Order 2015")
        end
      end

      describe "legislation_description" do
        it "returns the legislation description" do
          expect(application_type.legislation_description).to eq("Review Condition A.4 of GPDO 2015 (as amended) Schedule 2, Part 1, Class A.")
        end
      end
    end

    context "when planning application type has no legislation details defined in en.yml translation" do
      let!(:application_type) { create(:application_type) }

      %w[legislation_link legislation_link_text legislation_description].each do |translation|
        describe translation.to_s do
          it "returns false" do
            expect(application_type.send(translation)).to be(false)
          end
        end
      end
    end
  end
end
