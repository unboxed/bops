# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GOV.UK Notify settings", type: :system do
  let(:local_authority) { create(:local_authority, :default, :unconfigured) }
  let(:user) { create(:user, :administrator, local_authority:) }

  let(:notify_url) do
    "https://api.notifications.service.gov.uk/v2/notifications"
  end

  let(:error_response) do
    {
      status: 400,
      headers: {
        "Content-Type" => "application/json"
      },
      body: {
        errors: [
          {error: "BadRequestError", message: "Can't send to this recipient using a team-only API key"}
        ]
      }.to_json
    }
  end

  let(:successful_response) do
    {
      status: 200,
      headers: {
        "Content-Type" => "application/json"
      },
      body: {
        id: "48025d96-abc9-4b1d-a519-3cbc1c7f700b"
      }.to_json
    }
  end

  before do
    sign_in(user)

    allow(SecureRandom).to receive(:base36).and_return("xcp86uyv6aylzz1p")
  end

  it "allows the administrator to update and check the GOV.UK Notify settings" do
    expect(local_authority).to have_attributes(
      notify_api_key: nil,
      email_reply_to_id: nil,
      email_template_id: nil,
      sms_template_id: nil,
      letter_template_id: nil
    )

    visit "/admin/profile"
    expect(page).to have_link("Manage GOV.UK Notify", href: "/admin/notify/edit")

    click_link "Manage GOV.UK Notify"
    expect(page).to have_selector("h1", text: "Manage GOV.UK Notify settings")

    click_button "Submit"
    expect(page).to have_content("Enter the ID of the email template you will be using")
    expect(page).to have_content("Enter the ID of the SMS template you will be using")

    fill_in "API key", with: "live-f06ff28b-f1d1-45b2-bc73-8e1e3df534e9-2c51a5fd-d68b-4687-b9b0-39e2cdf46ad5"
    fill_in "Reply-to email address", with: "13d8cb67-4d5c-40d1-8a4b-bda6661523fb"
    fill_in "Email template", with: "9d06d78e-ba05-4789-915d-a053c49be0ce"
    fill_in "SMS template", with: "80147304-ac8d-422f-aee4-1d540ad70be9"
    fill_in "Letter template", with: "5d2c947e-9c32-478d-b2d7-c0c5a5b92109"

    click_button "Submit and check settings"
    expect(page).to have_content("GOV.UK Notify settings successfully updated")

    expect(local_authority.reload).to have_attributes(
      notify_api_key: "live-f06ff28b-f1d1-45b2-bc73-8e1e3df534e9-2c51a5fd-d68b-4687-b9b0-39e2cdf46ad5",
      email_reply_to_id: "13d8cb67-4d5c-40d1-8a4b-bda6661523fb",
      email_template_id: "9d06d78e-ba05-4789-915d-a053c49be0ce",
      sms_template_id: "80147304-ac8d-422f-aee4-1d540ad70be9",
      letter_template_id: "5d2c947e-9c32-478d-b2d7-c0c5a5b92109"
    )

    click_button "Send email"

    expect(page).to have_selector("[role=alert] li", text: "Enter an email address for the test message")
    expect(page).to have_selector("[role=alert] li", text: "Enter a subject for the test message")
    expect(page).to have_selector("[role=alert] li", text: "Enter the body of the test message")

    fill_in "Email address", with: "bob"
    fill_in "Subject", with: "Test Message"
    fill_in "Body", with: "Testing, testing, testing ..."

    click_button "Send email"

    expect(page).to have_selector("[role=alert] li", text: "Enter a valid email address for the test message")

    notify_request =
      stub_request(:post, "#{notify_url}/email")
        .with(body: hash_including(
          {
            template_id: "9d06d78e-ba05-4789-915d-a053c49be0ce",
            email_reply_to_id: "13d8cb67-4d5c-40d1-8a4b-bda6661523fb",
            email_address: "bob@example.com",
            personalisation: hash_including(
              "subject" => "Test Message",
              "body" => "Testing, testing, testing ..."
            )
          }
        ))
        .to_return(error_response)

    fill_in "Email address", with: "bob@example.com"
    click_button "Send email"

    expect(notify_request).to have_been_requested
    expect(page).to have_content("Can't send to this recipient using a team-only API key")

    notify_request =
      stub_request(:post, "#{notify_url}/email")
        .with(body: hash_including(
          {
            template_id: "9d06d78e-ba05-4789-915d-a053c49be0ce",
            email_reply_to_id: "13d8cb67-4d5c-40d1-8a4b-bda6661523fb",
            email_address: "robert@example.com",
            personalisation: hash_including(
              "subject" => "Test Message",
              "body" => "Testing, testing, testing ..."
            )
          }
        ))
        .to_return(successful_response)

    fill_in "Email address", with: "robert@example.com"
    click_button "Send email"

    expect(notify_request).to have_been_requested
    expect(page).to have_content("Email sent successfully (ref: xcp86uyv6aylzz1p)")

    click_button "Continue"
    expect(page).to have_selector("h1", text: "Check SMS settings")

    click_button "Send SMS"

    expect(page).to have_selector("[role=alert] li", text: "Enter a phone number for the test message")
    expect(page).to have_selector("[role=alert] li", text: "Enter the body of the test message")

    fill_in "Phone number", with: "+447123"
    fill_in "Body", with: "Testing, testing, testing ..."

    click_button "Send SMS"

    expect(page).to have_selector("[role=alert] li", text: "Enter a valid phone number for the test message")

    notify_request =
      stub_request(:post, "#{notify_url}/sms")
        .with(body: hash_including(
          {
            template_id: "80147304-ac8d-422f-aee4-1d540ad70be9",
            phone_number: "+447123456789",
            personalisation: hash_including(
              "body" => "Testing, testing, testing ..."
            )
          }
        ))
        .to_return(error_response)

    fill_in "Phone number", with: "+447123456789"
    click_button "Send SMS"

    expect(notify_request).to have_been_requested
    expect(page).to have_content("Can't send to this recipient using a team-only API key")

    notify_request =
      stub_request(:post, "#{notify_url}/sms")
        .with(body: hash_including(
          {
            template_id: "80147304-ac8d-422f-aee4-1d540ad70be9",
            phone_number: "+447123456780",
            personalisation: hash_including(
              "body" => "Testing, testing, testing ..."
            )
          }
        ))
        .to_return(successful_response)

    fill_in "Phone number", with: "+447123456780"
    click_button "Send SMS"

    expect(notify_request).to have_been_requested
    expect(page).to have_content("SMS sent successfully (ref: xcp86uyv6aylzz1p)")

    click_button "Continue"
    expect(page).to have_selector("h1", text: "Check letter settings")

    click_button "Create letter"

    expect(page).to have_selector("[role=alert] li", text: "Enter an address for the test letter")
    expect(page).to have_selector("[role=alert] li", text: "Enter the heading of the test letter")
    expect(page).to have_selector("[role=alert] li", text: "Enter the message of the test letter")

    fill_in "Address", with: "22 Cottage Ln\nShottery\nStratford-upon-Avon\nCV37 9XX"
    fill_in "Heading", with: "Test Message"
    fill_in "Message", with: "Testing, testing, testing ..."

    notify_request =
      stub_request(:post, "#{notify_url}/letter")
        .with(body: hash_including(
          {
            template_id: "5d2c947e-9c32-478d-b2d7-c0c5a5b92109",
            personalisation: hash_including(
              "address_line_1" => "22 Cottage Ln",
              "address_line_2" => "Shottery",
              "address_line_3" => "Stratford-upon-Avon",
              "address_line_4" => "CV37 9XX",
              "heading" => "Test Message",
              "message" => "Testing, testing, testing ..."
            )
          }
        ))
        .to_return(
          status: 400,
          headers: {
            "Content-Type" => "application/json"
          },
          body: {
            errors: [
              {error: "ValidationError", message: "Must be a real UK postcode"}
            ]
          }.to_json
        )

    click_button "Create letter"

    expect(notify_request).to have_been_requested
    expect(page).to have_content("Must be a real UK postcode")

    notify_request =
      stub_request(:post, "#{notify_url}/letter")
        .with(body: hash_including(
          {
            template_id: "5d2c947e-9c32-478d-b2d7-c0c5a5b92109",
            personalisation: hash_including(
              "address_line_1" => "22 Cottage Ln",
              "address_line_2" => "Shottery",
              "address_line_3" => "Stratford-upon-Avon",
              "address_line_4" => "CV37 9HH",
              "heading" => "Test Message",
              "message" => "Testing, testing, testing ..."
            )
          }
        ))
        .to_return(successful_response)

    fill_in "Address", with: "22 Cottage Ln\nShottery\nStratford-upon-Avon\nCV37 9HH"
    click_button "Create letter"

    expect(notify_request).to have_been_requested
    expect(page).to have_content("Letter created successfully (ref: xcp86uyv6aylzz1p)")

    click_button "Continue"

    expect(page).to have_content("GOV.UK Notify checks completed")
    expect(page).to have_selector("h1", text: "Manage GOV.UK Notify settings")
  end
end
