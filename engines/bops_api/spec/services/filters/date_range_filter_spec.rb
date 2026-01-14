# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::DateRangeFilter do
  let(:local_authority) { create(:local_authority) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  describe ".call" do
    context "when date params are blank" do
      let(:params) { {} }

      it "returns scope unchanged" do
        expect(described_class.call(scope, params, :receivedAt)).to eq(scope)
      end
    end

    context "when filtering by receivedAt" do
      let!(:old_app) do
        create(:planning_application, local_authority: local_authority, received_at: 30.days.ago)
      end

      let!(:recent_app) do
        create(:planning_application, local_authority: local_authority, received_at: 5.days.ago)
      end

      let!(:very_recent_app) do
        create(:planning_application, local_authority: local_authority, received_at: 1.day.ago)
      end

      context "with only from date" do
        let(:params) { {receivedAtFrom: 10.days.ago.to_date.iso8601} }

        it "filters applications received after the from date" do
          result = described_class.call(scope, params, :receivedAt)

          expect(result).not_to include(old_app)
          expect(result).to include(recent_app)
          expect(result).to include(very_recent_app)
        end
      end

      context "with only to date" do
        let(:params) { {receivedAtTo: 3.days.ago.to_date.iso8601} }

        it "filters applications received before the to date" do
          result = described_class.call(scope, params, :receivedAt)

          expect(result).to include(old_app)
          expect(result).to include(recent_app)
          expect(result).not_to include(very_recent_app)
        end
      end

      context "with both from and to dates" do
        let(:params) do
          {
            receivedAtFrom: 10.days.ago.to_date.iso8601,
            receivedAtTo: 3.days.ago.to_date.iso8601
          }
        end

        it "filters applications within the date range" do
          result = described_class.call(scope, params, :receivedAt)

          expect(result).not_to include(old_app)
          expect(result).to include(recent_app)
          expect(result).not_to include(very_recent_app)
        end
      end
    end

    context "when filtering by validatedAt" do
      let!(:validated_app) do
        create(:planning_application, :in_assessment, local_authority: local_authority, validated_at: 5.days.ago)
      end

      let!(:unvalidated_app) do
        create(:planning_application, :not_started, local_authority: local_authority, validated_at: nil)
      end

      let(:params) { {validatedAtFrom: 10.days.ago.to_date.iso8601} }

      it "filters by validated_at field" do
        result = described_class.call(scope, params, :validatedAt)

        expect(result).to include(validated_app)
        expect(result).not_to include(unvalidated_app)
      end
    end

    context "with invalid date format" do
      let(:params) { {receivedAtFrom: "not-a-date"} }

      it "handles invalid dates gracefully" do
        # Should not raise an error
        expect { described_class.call(scope, params, :receivedAt) }.not_to raise_error
      end
    end
  end
end
