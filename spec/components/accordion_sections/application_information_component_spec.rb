# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::ApplicationInformationComponent, type: :component do
  let(:application_type) { create(:application_type, :ldc_proposed) }

  let(:planning_application) do
    create(
      :planning_application,
      :from_planx,
      description: "Test description",
      address_1: "123 Long Lane",
      town: "Big City",
      postcode: "AB34EF",
      uprn: "123456789",
      payment_reference:,
      payment_amount: 100,
      application_type:,
      user:
    )
  end

  let(:user) { create(:user, name: "Alice Smith") }
  let(:payment_reference) { "123" }

  let(:component) do
    described_class.new(planning_application:)
  end

  it "renders the planning application description" do
    render_inline(component)

    expect(page).to have_summary_item("Description", with: "Test description")
  end

  context "when ldc proposed application" do
    it "renders correct type and work status" do
      render_inline(component)

      expect(page).to have_summary_item(
        "Application type",
        with: "Lawful Development Certificate"
      )
    end
  end

  context "when listed building application" do
    let(:application_type) { create(:application_type, :listed) }

    it "renders correct type and work status" do
      render_inline(component)

      expect(page).to have_summary_item(
        "Application type",
        with: "Consent to do works to a Listed Building"
      )
    end
  end

  it "renders address" do
    render_inline(component)

    expect(page).to have_summary_item(
      "Site address",
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

    expect(page).to have_summary_item("Parish", with: "Southwark, unparished area")
  end

  it "renders ward" do
    render_inline(component)

    expect(page).to have_summary_item("Ward", with: "South Bermondsey")
  end

  it "renders ward type" do
    render_inline(component)

    expect(page).to have_summary_item("Ward type", with: "London borough ward")
  end

  it "renders whether work is already started" do
    render_inline(component)

    expect(page).to have_summary_item("Work already started", with: "No")
  end

  it "renders the UPRN" do
    render_inline(component)

    expect(page).to have_summary_item("UPRN", with: "123456789")
  end

  it "renders the payment reference" do
    render_inline(component)

    expect(page).to have_summary_item("Payment reference", with: "123")
  end

  it "renders the payment amount" do
    render_inline(component)

    expect(page).to have_summary_item("Payment amount", with: "£100.00")
  end

  it "renders the case officer" do
    render_inline(component)

    expect(page).to have_summary_item("Case officer", with: "Alice Smith")
  end

  context "when there is no case officer" do
    let(:user) { nil }

    it "renders 'Not assigned'" do
      render_inline(component)

      expect(page).to have_summary_item("Case officer", with: "Not assigned")
    end
  end

  context "when there is no payment reference" do
    let(:payment_reference) { nil }

    it "renders 'Exempt'" do
      render_inline(component)

      expect(page).to have_summary_item("Payment reference", with: "Exempt")
    end
  end

  context "when there is an alternative reference" do
    let(:planning_application) do
      create(
        :planning_application,
        :from_planx,
        description: "Test description",
        address_1: "123 Long Lane",
        town: "Big City",
        postcode: "AB34EF",
        uprn: "123456789",
        payment_reference:,
        payment_amount: 100,
        alternative_reference: "M3-12345",
        application_type:,
        user:
      )
    end

    it "renders the alternative reference" do
      render_inline(component)

      expect(page).to have_summary_item("Alternative reference", with: "M3-12345")
    end
  end

  context "when there is no alternative reference" do
    it "renders 'Not provided'" do
      render_inline(component)

      expect(page).to have_summary_item("Alternative reference", with: "Not provided")
    end
  end

  context "when the work has been started" do
    let(:application_type) { create(:application_type, :ldc_existing) }

    it "renders 'Yes'" do
      render_inline(component)

      expect(page).to have_summary_item("Work already started", with: "Yes")
    end
  end

  context "when there is a session ID" do
    it "renders 'session id'" do
      render_inline(component)

      expect(page).to have_summary_item("Session ID", with: "21161b70-0e29-40e6-9a38-c42f61f25ab9")
    end
  end
end
