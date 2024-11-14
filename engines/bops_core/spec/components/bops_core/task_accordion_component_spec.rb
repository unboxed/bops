# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::TaskAccordionComponent, type: :component) do
  let(:kwargs) do
    {heading: {text: "Review assessment"}, expanded: true}
  end

  subject! do
    render_inline(described_class.new(**kwargs)) do |accordion|
      accordion.with_section(expanded: true) do |section|
        section.with_heading(text: "Assessment summaries")

        section.with_status do
          helper.govuk_tag(text: "Not Started")
        end

        section.with_block do
          <<~HTML.html_safe
            <h3 class="govuk-heading-s">Summary of works</h3>
            <p class="govuk-body">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>
          HTML
        end

        section.with_block do
          <<~HTML.html_safe
            <h3 class="govuk-heading-s">Site description</h3>
            <p class="govuk-body">Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.</p>
          HTML
        end

        section.with_footer do
          <<~HTML.html_safe
            <div class="govuk-radios govuk-radios--inline" data-module="govuk-radios">
              <div class="govuk-radios__item">
                <input class="govuk-radios__input" id="action-agree" name="action" type="radio" value="agree">
                <label class="govuk-label govuk-radios__label" for="action-agree">
                  Agree
                </label>
              </div>
              <div class="govuk-radios__item">
                <input class="govuk-radios__input" id="action-return-with-comments" name="action" type="radio" value="return-with-comments">
                <label class="govuk-label govuk-radios__label" for="action-return-with-comments">
                  Return with comments
                </label>
              </div>
            </div>
          HTML
        end
      end
    end
  end

  it "renders a task accordion component" do
    within "div.bops-task-accordion" do
      expect(element["data-controller"]).to eq("task-accordion")
      expect(element["data-action"]).to eq("task-accordion-section:toggled->task-accordion#sectionToggled")

      within "div.bops-task-accordion-header" do
        within "h2.bops-task-accordion-heading" do
          expect(element.text).to eq("Review assessment")
        end

        within "div.bops-task-accordion-controls" do
          expect(element).to have_button("Collapse all")
        end
      end

      within "div.bops-task-accordion__section:nth-of-type(1)" do
        expect(element["data-controller"]).to eq("task-accordion-section")

        within "div.bops-task-accordion__section-controls" do
          expect(element).to have_button("Collapse")
        end

        within "div.bops-task-accordion__section-block:nth-of-type(1)" do
          expect(element).to have_selector("h3", text: "Summary of works")
        end

        within "div.bops-task-accordion__section-block:nth-of-type(2)" do
          expect(element).to have_selector("h3", text: "Site description")
        end

        within "div.bops-task-accordion__section-footer" do
          expect(element).to have_unchecked_field("Agree")
          expect(element).to have_unchecked_field("Return with comments")
        end
      end
    end
  end
end
