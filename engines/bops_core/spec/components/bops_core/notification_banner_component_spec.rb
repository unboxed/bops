# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::NotificationBannerComponent, type: :component) do
  context "with default attributes" do
    subject! do
      render_inline(described_class.new(
        title: "Outcome",
        colour: "green",
        subheading: "Likely to be supported",
        message: "Your proposal is likely to be supported based on the information you have provided."
      ))
    end

    it "renders the notification banner component" do
      expect(page).to have_css(".govuk-notification-banner.bops-notification-banner--green")
      within ".govuk-notification-banner__header" do
        expect(page).to have_css(".govuk-notification-banner__title", text: "Outcome")
      end
      within ".govuk-notification-banner__content" do
        expect(page).to have_css("h2", text: "Likely to be supported")
        expect(page).to have_css("p", text: "Your proposal is likely to be supported based on the information you have provided.")
      end
    end
  end

  context "with different colours" do
    %w[green orange red grey].each do |colour|
      context "with the colour: #{colour}" do
        subject! do
          render_inline(described_class.new(
            title: "Outcome",
            colour: colour,
            subheading: "Test Subheading",
            message: "Test Message"
          ))
        end

        it "renders the notification banner with the correct colour class" do
          expect(page).to have_css(".govuk-notification-banner.bops-notification-banner--#{colour}")
        end
      end
    end
  end

  context "with HTML content in the message" do
    subject! do
      render_inline(described_class.new(
        title: "Outcome",
        colour: "blue",
        subheading: "Additional Information",
        message: <<~HTML.html_safe
          <p>This is a detailed explanation of the outcome.</p>
          <p>More details can be found <a href='https://example.com'>here</a>.</p>
        HTML
      ))
    end

    it "renders the message with HTML content" do
      within ".govuk-notification-banner__content" do
        expect(page).to have_css("p", text: "This is a detailed explanation of the outcome.")
        expect(page).to have_link("here", href: "https://example.com")
      end
    end
  end
end
