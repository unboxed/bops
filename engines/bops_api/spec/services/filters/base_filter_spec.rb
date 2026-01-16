# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::BaseFilter do
  describe "abstract methods" do
    let(:filter) { described_class.new }
    let(:scope) { PlanningApplication.all }
    let(:params) { {} }

    it "raises NotImplementedError for applicable?" do
      expect { filter.applicable?(params) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for apply" do
      expect { filter.apply(scope, params) }.to raise_error(NotImplementedError)
    end
  end
end
