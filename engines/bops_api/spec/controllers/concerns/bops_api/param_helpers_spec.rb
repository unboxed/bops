# frozen_string_literal: true

require "rails_helper"

class DummyController
  include BopsApi::ParamHelpers
end

RSpec.describe BopsApi::ParamHelpers do
  let(:controller) { DummyController.new }

  describe "#handle_comma_separated_param" do
    it "splits comma-separated values into an array" do
      params = {example: "a,b"}
      result = controller.handle_comma_separated_param(params, :example)
      expect(result).to eq(["a", "b"])
    end

    it "handles array values" do
      params = {example: ["a", "b"]}
      result = controller.handle_comma_separated_param(params, :example)
      expect(result).to eq(["a", "b"])
    end

    it "removes blank values" do
      params = {example: "a,,"}
      result = controller.handle_comma_separated_param(params, :example)
      expect(result).to eq(["a"])
    end

    it "removes duplicate values" do
      params = {example: "a,a,b"}
      result = controller.handle_comma_separated_param(params, :example)
      expect(result).to eq(["a", "b"])
    end
  end
end
