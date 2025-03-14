# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::StatusDetailComponent, type: :component) do
  include ActionView::Helpers::TagHelper

  context "when all required attributes are provided" do
    subject! do
      render_inline(described_class.new(id: "status-detail", open: true)) do |component|
        component.with_title { "Consultee Name" }
        component.with_body { "This is a consultee comment." }
        component.with_status { tag.span("Approved", class: "govuk-tag govuk-tag--green") }
      end
    end

    it "renders correctly with all attributes" do
      within "#status-detail" do
        expect(element["id"]).to eq("status-detail")
        expect(element["class"]).to include("govuk-details-wrapper")

        within ".govuk-details" do
          within ".govuk-details__summary" do
            expect(element.text).to eq("Consultee Name")
          end

          within ".govuk-details__text" do
            expect(element.text).to eq("This is a consultee comment.")
          end
        end

        within ".status-container" do
          expect(element.text).to eq("Approved")
          expect(element["class"]).to include("status-container")
        end
      end
    end
  end

  context "when a required attribute is missing" do
    it "raises an error if title is missing" do
      expect {
        render_inline(described_class.new(id: "status-detail")) do |component|
          component.with_body { "This is a consultee comment." }
          component.with_status { tag.span("Approved", class: "govuk-tag govuk-tag--green") }
        end
      }.to raise_error(ArgumentError, /Missing required attributes.*:title/)
    end

    it "raises an error if body is missing" do
      expect {
        render_inline(described_class.new(id: "status-detail")) do |component|
          component.with_title { "Consultee Name" }
          component.with_status { tag.span("Approved", class: "govuk-tag govuk-tag--green") }
        end
      }.to raise_error(ArgumentError, /Missing required attributes.*:body/)
    end

    it "raises an error if status is missing" do
      expect {
        render_inline(described_class.new(id: "status-detail")) do |component|
          component.with_title { "Consultee Name" }
          component.with_body { "This is a consultee comment." }
        end
      }.to raise_error(ArgumentError, /Missing required attributes.*:status/)
    end
  end

  context "when extra HTML attributes are provided" do
    subject! do
      render_inline(described_class.new(id: "status-detail", classes: ["custom-class"], html_attributes: {data: {foo: "bar"}})) do |component|
        component.with_title { "Consultee Name" }
        component.with_body { "This is a consultee comment." }
        component.with_status { tag.span("Approved", class: "govuk-tag govuk-tag--green") }
      end
    end

    it "applies custom attributes correctly" do
      expect(page).to have_css("#status-detail.custom-class[data-foo='bar']")
    end
  end
end
