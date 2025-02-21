# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe(BopsCore::TicketPanelComponent, type: :component) do
  context "without a colour" do
    subject! do
      render_inline(described_class.new(id: "ticket")) do |ticket|
        ticket.with_body { "This is the body" }
        ticket.with_footer { "This is the footer" }
      end
    end

    it "renders the ticket panel component" do
      within "#ticket" do
        expect(element["id"]).to eq("ticket")
        expect(element["class"]).to eq("bops-ticket-panel")

        within "> div:nth-child(1)" do
          expect(element["class"]).to eq("bops-ticket-panel__body")
          expect(element.text).to eq("This is the body")
        end

        within "> div:nth-child(2)" do
          expect(element["class"]).to eq("bops-ticket-panel__footer")
          expect(element.text).to eq("This is the footer")
        end
      end
    end
  end

  context "with HTML content" do
    subject! do
      render_inline(described_class.new(id: "ticket")) do |ticket|
        ticket.with_body do
          <<~HTML.html_safe
            <p class="govuk-body">This is the first paragraph</p>
            <p class="govuk-body">This is the second paragraph</p>
          HTML
        end

        ticket.with_footer { "This is the footer" }
      end
    end

    it "renders the ticket panel component" do
      within "#ticket" do
        expect(element["id"]).to eq("ticket")
        expect(element["class"]).to eq("bops-ticket-panel")

        within "> div:nth-child(1)" do
          expect(element["class"]).to eq("bops-ticket-panel__body")

          within "> p:nth-child(1)" do
            expect(element.text).to eq("This is the first paragraph")
          end

          within "> p:nth-child(2)" do
            expect(element.text).to eq("This is the second paragraph")
          end
        end

        within "> div:nth-child(2)" do
          expect(element["class"]).to eq("bops-ticket-panel__footer")
          expect(element.text).to eq("This is the footer")
        end
      end
    end
  end

  described_class::COLOURS.each do |colour|
    context "with the colour: #{colour.inspect}" do
      subject! do
        render_inline(described_class.new(id: "ticket", colour: colour)) do |ticket|
          ticket.with_body { "This is the body" }
          ticket.with_footer { "This is the footer" }
        end
      end

      it "renders the ticket panel component" do
        within "#ticket" do
          expect(element["id"]).to eq("ticket")
          expect(element["class"]).to eq("bops-ticket-panel bops-ticket-panel--#{colour}")

          within "> div:nth-child(1)" do
            expect(element["class"]).to eq("bops-ticket-panel__body")
            expect(element.text).to eq("This is the body")
          end

          within "> div:nth-child(2)" do
            expect(element["class"]).to eq("bops-ticket-panel__footer")
            expect(element.text).to eq("This is the footer")
          end
        end
      end
    end
  end
end
