# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::ApplicationHelper, type: :helper) do
  describe "#link_to_document" do
    include GovukVisuallyHiddenHelper
    include GovukLinkHelper

    let(:document) { create(:document) }

    it "adds view in new tab text" do
      link = link_to_document("hello world", document)
      expect(link).to match(/hello world \(opens in new tab\)/)
    end

    it "does not repeat view in new tab text" do
      link = link_to_document("View document in new window", document)
      expect(link).to match(/View document in new window/)
      expect(link).not_to match(/\(opens in new tab\)/)
    end
  end
end
