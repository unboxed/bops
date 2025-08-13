# frozen_string_literal: true

require "rails_helper"

class DummyController
  include BopsApi::ParamHelpers
end

RSpec.describe BopsApi::ParamHelpers do
  let(:controller) { DummyController.new }

  describe "#handle_comma_separated_param" do
    it "splits comma-separated values into an array" do
      result = controller.handle_comma_separated_param("a,b")
      expect(result).to eq(["a", "b"])
    end

    it "handles array values" do
      result = controller.handle_comma_separated_param(["a", "b"])
      expect(result).to eq(["a", "b"])
    end

    it "removes blank values" do
      result = controller.handle_comma_separated_param("a,,")
      expect(result).to eq(["a"])
    end

    it "removes duplicate values" do
      result = controller.handle_comma_separated_param("a,a,b")
      expect(result).to eq(["a", "b"])
    end
  end
end
