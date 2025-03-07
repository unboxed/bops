# frozen_string_literal: true

require "rails_helper"

RSpec.describe Legislation do
  describe "#validations" do
    subject(:legislation) { described_class.new }

    describe "#title" do
      it "validates presence" do
        expect { legislation.valid? }.to change { legislation.errors[:title] }.to ["Enter a title for the legislation"]
      end

      it "is readonly" do
        legislation = create(:legislation, title: "Legislation title")

        expect {
          legislation.update!(title: "A new legislation title")
        }.to raise_error(ActiveRecord::ReadonlyAttributeError)

        expect(legislation.reload.title).to eq("Legislation title")
      end
    end

    context "when destroying" do
      let(:legislation) { create(:legislation) }
      let(:application_type) { create(:application_type_config, legislation:) }

      it "restricts with error when there are associated application types" do
        application_type

        expect { legislation.destroy }.to change { legislation.errors[:base] }.to ["Cannot delete record because dependent application types exist"]
      end

      it "allows deletion when there are no associated application types" do
        expect { legislation.destroy }.not_to change { legislation.errors[:base] }
      end
    end
  end
end
