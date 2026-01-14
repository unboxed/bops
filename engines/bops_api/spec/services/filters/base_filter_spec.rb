# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::BaseFilter do
  describe ".call" do
    let(:test_filter_class) do
      Class.new(described_class) do
        class << self
          private

          def applicable?(params)
            params[:enabled].present?
          end

          def apply(scope, params)
            scope.where(active: true)
          end
        end
      end
    end

    let(:scope) { PlanningApplication.all }

    context "when applicable? returns true" do
      let(:params) { {enabled: "yes"} }

      it "applies the filter" do
        expect(test_filter_class.call(scope, params)).to eq(scope.where(active: true))
      end
    end

    context "when applicable? returns false" do
      let(:params) { {} }

      it "returns the scope unchanged" do
        expect(test_filter_class.call(scope, params)).to eq(scope)
      end
    end
  end

  describe "abstract methods" do
    let(:scope) { PlanningApplication.all }
    let(:params) { {} }

    it "raises NotImplementedError for applicable?" do
      expect { described_class.send(:applicable?, params) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for apply" do
      expect { described_class.send(:apply, scope, params) }.to raise_error(NotImplementedError)
    end
  end
end
