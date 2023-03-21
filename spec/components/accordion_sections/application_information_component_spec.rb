# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::ApplicationInformationComponent, type: :component do
  let(:planning_application) do
    create(
      :planning_application,
      description: "Test description",
      application_type: :full,
      work_status:,
      address_1: "123 Long Lane",
      town: "Big City",
      postcode: "AB34EF",
      uprn: "123456789",
      payment_reference:,
      payment_amount: 100,
      user:
    )
  end

  let(:user) { create(:user, name: "Alice Smith") }
  let(:payment_reference) { "123" }
  let(:work_status) { :proposed }

  let(:component) do
    described_class.new(planning_application:)
  end

  it "renders the planning application description" do
    render_inline(component)

    expect(page).to have_row_for("Description:", with: "Test description")
  end

  it "renders link to new description change request" do
    render_inline(component)

    expect(page).to have_link(
      "Propose a change to the description",
      href: "/planning_applications/#{planning_application.id}/description_change_validation_requests/new"
    )
  end

  it "renders type and work status" do
    render_inline(component)

    expect(page).to have_row_for(
      "Application type:",
      with: "Full Householder Application (Proposed)"
    )
  end

  it "renders address" do
    render_inline(component)

    expect(page).to have_row_for(
      "Site address:",
      with: "123 Long Lane, Big City, AB34EF"
    )
  end

  it "renders google maps link" do
    render_inline(component)

    expect(page).to have_link(
      "View site on Google Maps",
      href: "https://google.co.uk/maps/place/123+Long+Lane%2C+Big+City%2C+AB34EF"
    )
  end

  it "renders mapit link" do
    render_inline(component)

    expect(page).to have_link(
      "View on mapit",
      href: "https://mapit.mysociety.org/postcode/AB34EF.html"
    )
  end

  it "renders parish name" do
    render_inline(component)

    expect(page).to have_row_for("Parish:", with: "Southwark, unparished area")
  end

  it "renders ward" do
    render_inline(component)

    expect(page).to have_row_for("Ward:", with: "South Bermondsey")
  end

  it "renders ward type" do
    render_inline(component)

    expect(page).to have_row_for("Ward type:", with: "London borough ward")
  end

  it "renders whether work is already started" do
    render_inline(component)

    expect(page).to have_row_for("Work already started:", with: "No")
  end

  it "renders the UPRN" do
    render_inline(component)

    expect(page).to have_row_for("UPRN:", with: "123456789")
  end

  it "renders the payment reference" do
    render_inline(component)

    expect(page).to have_row_for("Payment reference:", with: "123")
  end

  it "renders the payment amount" do
    render_inline(component)

    expect(page).to have_row_for("Payment amount:", with: "£100.00")
  end

  it "renders the case officer" do
    render_inline(component)

    expect(page).to have_row_for("Case officer:", with: "Alice Smith")
  end

  context "when description change request is present" do
    let!(:description_change_validation_request) do
      create(
        :description_change_validation_request,
        planning_application:
      )
    end

    it "renders link to request" do
      render_inline(component)

      expect(page).to have_link(
        "View requested change",
        href: "/planning_applications/#{planning_application.id}/description_change_validation_requests/#{description_change_validation_request.id}"
      )
    end
  end

  context "when there is no case officer" do
    let(:user) { nil }

    it "renders 'Not assigned'" do
      render_inline(component)

      expect(page).to have_row_for("Case officer:", with: "Not assigned")
    end
  end

  context "when there is no payment reference" do
    let(:payment_reference) { nil }

    it "renders 'Exempt'" do
      render_inline(component)

      expect(page).to have_row_for("Payment reference:", with: "Exempt")
    end
  end

  context "when the work has been started" do
    let(:work_status) { :existing }

    it "renders 'Yes'" do
      render_inline(component)

      expect(page).to have_row_for("Work already started:", with: "Yes")
    end
  end
end
