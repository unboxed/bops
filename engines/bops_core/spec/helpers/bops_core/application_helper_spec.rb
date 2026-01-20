# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::ApplicationHelper, type: :helper) do
  describe "#active_page_key" do
    it "returns 'pre_applications' for bops_preapps/pre_applications controller" do
      allow(helper).to receive(:controller_path).and_return("bops_preapps/pre_applications")
      expect(helper.active_page_key).to eq("pre_applications")
    end

    it "returns 'pre_applications' for bops_preapps/tabs controller" do
      allow(helper).to receive(:controller_path).and_return("bops_preapps/tabs")
      expect(helper.active_page_key).to eq("pre_applications")
    end

    it "returns 'planning_applications' for planning_applications controller" do
      allow(helper).to receive(:controller_path).and_return("planning_applications")
      expect(helper.active_page_key).to eq("planning_applications")
    end

    it "returns 'planning_applications' for planning_applications/tabs controller" do
      allow(helper).to receive(:controller_path).and_return("planning_applications/tabs")
      expect(helper.active_page_key).to eq("planning_applications")
    end

    it "returns 'enforcements' for bops_enforcements/enforcements controller" do
      allow(helper).to receive(:controller_path).and_return("bops_enforcements/enforcements")
      expect(helper.active_page_key).to eq("enforcements")
    end

    it "returns 'dashboard' for unknown controllers" do
      allow(helper).to receive(:controller_path).and_return("some_other/controller")
      expect(helper.active_page_key).to eq("dashboard")
    end
  end

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
