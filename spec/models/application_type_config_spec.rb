# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationType::Config do
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
          create(:application_type_config, :planning_permission)
        end

        it "validates uniqueness" do
          expect { application_type.valid? }.to change { application_type.errors[:code] }.to ["There is already an application type for that name"]
        end
      end

      context "when an application type is inactive" do
        subject(:application_type) { create(:application_type_config, :ldc_proposed, status: "inactive") }

        before do
          application_type.code = "ldc"
        end

        it "allows the updating of the code" do
          expect { application_type.valid? }.not_to change { application_type.errors[:code] }.from []
        end
      end

      context "when an application type is active" do
        subject(:application_type) { create(:application_type_config, :ldc_proposed, status: "active") }

        before do
          application_type.code = "ldc"
        end

        it "prevents the updating of the code" do
          expect { application_type.valid? }.to change { application_type.errors[:code] }.to ["The name can't be changed when the application type is active"]
        end
      end

      context "when an application type is retired" do
        subject(:application_type) { create(:application_type_config, :ldc_proposed, status: "retired") }

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
          create(:application_type_config, :ldc_proposed)
        end

        it "validates uniqueness" do
          expect { application_type.valid? }.to change { application_type.errors[:suffix] }.to ["There is already an application type with that suffix"]
        end
      end

      context "when an application type is inactive" do
        subject(:application_type) { create(:application_type_config, :ldc_proposed, status: "inactive") }

        before do
          application_type.suffix = "LDC"
        end

        it "allows the updating of the suffix" do
          expect { application_type.valid? }.not_to change { application_type.errors[:suffix] }.from []
        end
      end

      context "when an application type is active" do
        subject(:application_type) { create(:application_type_config, :ldc_proposed, status: "active") }

        before do
          application_type.suffix = "LDC"
        end

        it "prevents the updating of the suffix" do
          expect { application_type.valid? }.to change { application_type.errors[:suffix] }.to ["The suffix can't be changed when the application type is active"]
        end
      end

      context "when an application type is retired" do
        subject(:application_type) { create(:application_type_config, :ldc_proposed, status: "retired") }

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

    describe "#legislation" do
      context "when status is active" do
        let(:application_type) { build(:application_type_config, :active, :without_legislation) }

        it "validates presence" do
          expect { application_type.valid? }.to change { application_type.errors[:legislation] }.to ["The legislation must be set when an application type is made active"]
        end
      end

      context "when status is not active" do
        let(:application_type) { build(:application_type_config, :inactive, :without_legislation) }

        it "does not validate presence" do
          expect { application_type.valid? }.not_to change { application_type.errors[:legislation] }
        end
      end
    end
  end

  describe "legislation details" do
    context "when planning application type has legislation details" do
      let(:legislation) { create(:legislation, :pa_part1_classA) }
      let(:application_type) { create(:application_type_config, :prior_approval, part: 1, section: "A", legislation:) }

      describe "legislation_title" do
        it "returns the legislation title" do
          expect(application_type.legislation_title).to eq("The Town and Country Planning (General Permitted Development) (England) Order 2015 Part 1, Class A")
        end
      end

      describe "legislation_link" do
        it "returns the legislation link" do
          expect(application_type.legislation_link).to eq("https://www.legislation.gov.uk/uksi/2015/596/schedule/2")
        end
      end

      describe "legislation_description" do
        it "returns the legislation description" do
          expect(application_type.legislation_description).to eq("Review Condition A.4 of GPDO 2015 (as amended) Schedule 2, Part 1, Class A.")
        end
      end
    end

    context "when planning application type has no legislation details" do
      let!(:application_type) { create(:application_type_config, :inactive, :without_legislation) }

      %w[legislation_link legislation_title legislation_description].each do |legislation_detail|
        describe legislation_detail.to_s do
          it "returns nil" do
            expect(application_type.send(legislation_detail)).to be(nil)
          end
        end
      end
    end
  end
end
