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
  end

  describe "class methods" do
    describe "#menu" do
      let!(:lawfulness_certificate) { ApplicationType.find_by(name: "lawfulness_certificate") }
      let!(:prior_approval) { ApplicationType.find_by(name: "prior_approval") }

      it "returns an array of application type names (humanized) and ids" do
        expect(described_class.menu).to eq(
          [["Prior approval", prior_approval.id], ["Lawfulness certificate", lawfulness_certificate.id]]
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
      let!(:application_type) { ApplicationType.find_by(name: "lawfulness_certificate") }

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
