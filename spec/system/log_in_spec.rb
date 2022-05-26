# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let(:assessor) { create :user, :assessor, name: "Lorrine Krajcik", local_authority: default_local_authority }
  let(:reviewer) { create :user, :reviewer, name: "Harley Dicki", local_authority: default_local_authority }

  it "ensure we can perform a healthcheck" do
    visit healthcheck_path

    expect(page.body).to have_content("OK")
  end

  it "Home page redirects to login" do
    visit root_path

    expect(page).to have_text("Email")
    expect(page).not_to have_text("Your fast track applications")
  end

  it "User cannot log in with invalid credentials" do
    visit root_path

    fill_in("user[email]", with: reviewer.email)
    fill_in("user[password]", with: "invalid_password")
    click_button("Log in")

    expect(page).to have_text("Invalid Email or password.")
    expect(page).not_to have_text("Signed in successfully.")
  end

  context "users with valid credentials" do
    context "as an assessor" do
      before do
        sign_in assessor
        visit root_path
      end

      it "can see their name and role" do
        expect(page).to have_text("Lorrine Krajcik")
        expect(page).to have_text("Case Officer")
      end
    end

    context "as a reviewer" do
      before do
        sign_in reviewer
        visit root_path
      end

      it "can see their name and role" do
        expect(page).to have_text("Harley Dicki")
        expect(page).to have_text("Manager")
      end
    end

    context "when user is an administrator" do
      let!(:administrator) do
        create(
          :user,
          :administrator,
          local_authority: default_local_authority,
          email: "alice@example.com",
          password: "password"
        )
      end

      it "redirects to the users dashboard" do
        visit(new_user_session_path)
        fill_in("Email", with: "alice@example.com")
        fill_in("Password", with: "password")
        click_button("Log in")
        fill_in("Security code", with: administrator.current_otp)
        click_button("Enter code")

        expect(page).to have_current_path(users_path)

        find(:xpath, "//input[@value='Log out']").click

        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context "a user belonging to a given subdomain" do
      let!(:lambeth) { create :local_authority, :lambeth }
      let!(:southwark) { create :local_authority, :southwark }
      let(:lambeth_assessor) do
        create :user, :assessor, name: "Lambertina Lamb", password: "Lambsrock18!", local_authority: lambeth
      end
      let(:southwark_assessor) do
        create :user, :assessor, name: "Southwarkina Sully", password: "Southwark4ever!", local_authority: southwark
      end

      before do
        @previous_host = Capybara.app_host
        Capybara.app_host = "http://#{lambeth.subdomain}.example.com"
      end

      after do
        Capybara.app_host = "http://#{@previous_host}"
      end

      it "is prevented from logging in to a different subdomain" do
        visit root_path

        fill_in("user[email]", with: southwark_assessor.email)
        fill_in("user[password]", with: "Southwark4ever!")
        click_button("Log in")

        expect(page).to have_text("Email")
        expect(page).not_to have_text("Welcome")
      end

      it "is able to login to its allocated subdomain" do
        visit root_path

        fill_in("user[email]", with: lambeth_assessor.email)
        fill_in("user[password]", with: "Lambsrock18!")
        click_button("Log in")
        fill_in("Security code", with: lambeth_assessor.current_otp)
        click_button("Enter code")

        expect(page).to have_text("Signed in successfully.")
      end

      it "has the feedback email" do
        visit root_path

        expect(page).to have_link("feedback", href: "mailto:feedback_email@lambeth.gov.uk")
      end
    end
  end

  context "signing in with two factor authentication" do
    before do
      visit root_path

      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
    end

    context "when I do not have a mobile number" do
      let!(:user) { create :user, local_authority: default_local_authority, mobile_number: nil }

      it "prompts me to enter a mobile number first before receiving my OTP" do
        click_button "Log in"

        expect(page).to have_content("Enter your phone number")
        expect(page).to have_content("To use two-factor authentication we need a UK mobile phone number for your account.")

        fill_in "Mobile number", with: "07722865843"

        expect(TwoFactor::SmsNotification).to receive(:new).with("07722865843", user.current_otp).and_call_original
        click_button "Send code"

        # mobile number saved to session rather than db at this point
        expect(user.reload.mobile_number).to eq(nil)

        expect(page).to have_content("Enter the code you have received by text message")
        expect(page).to have_content(
          "A 6-digit code has been sent to your mobile phone. This message may take a minute to arrive."
        )
        expect(page).to have_content(
          "If you have an issue logging in, please send an email to #{default_local_authority.email_address}"
        )
        expect(page).to have_link(default_local_authority.email_address.to_s, href: "mailto:#{default_local_authority.email_address}")

        fill_in "Security code", with: user.current_otp
        click_button "Enter code"

        expect(page).to have_content("Signed in successfully.")
        expect(page).to have_content(user.name)

        # mobile now saved to the db after successful login
        expect(user.reload.mobile_number).to eq("07722865843")
      end

      context "when there is an error from Notify" do
        before do
          error_hash = OpenStruct.new(
            body: "Notifications::Client::BadRequestError: ValidationError: phone_number Must not contain letters or symbols", code: 400
          )
          allow_any_instance_of(TwoFactor::SmsNotification).to receive(:deliver!).and_raise(
            Notifications::Client::BadRequestError, error_hash
          )
        end

        it "displays an error if there is an issue calling the notify API" do
          click_button "Log in"

          fill_in "Mobile number", with: "0671272472"
          click_button "Send code"

          expect(page).to have_content("Notify was unable to send sms with error: Notifications::Client::BadRequestError: ValidationError: phone_number Must not contain letters or symbols.")
          expect(page).to have_content("Enter your phone number")
          expect(user.reload.mobile_number).to eq(nil)
        end
      end

      it "I cannot access /two_factor url without setting up a mobile number first" do
        click_button "Log in"

        expect(TwoFactor::SmsNotification).not_to receive(:new)

        visit "/two_factor"

        expect(page).not_to have_content("Enter the code you have received by text message")
        expect(page).to have_content("Enter your phone number")
      end

      it "I cannot access /setup or /two_factor url without logging in first" do
        visit "/setup"
        expect(page).to have_content("You need to sign in or sign up before continuing.")

        visit "/two_factor"
        expect(page).to have_content("You need to sign in or sign up before continuing.")
      end
    end

    context "when I have a mobile number" do
      let!(:user) { create :user, local_authority: default_local_authority, mobile_number: "07765445412" }

      it "immediately send me my OTP" do
        expect(TwoFactor::SmsNotification).to receive(:new).with("07765445412", user.current_otp).and_call_original
        click_button "Log in"

        expect(page).not_to have_content("Enter your phone number")

        expect(page).to have_content("Enter the code you have received by text message")

        fill_in "Security code", with: user.current_otp
        click_button "Enter code"

        expect(page).to have_content("Signed in successfully.")
      end

      it "I can resend my OTP code" do
        click_button "Log in"

        # Before a minute has passed you should get a warning
        click_link "Resend code"
        expect(page).to have_content("Please wait at least a minute before resending your verification code.")

        # After a minute has passed you are able to resend code
        travel 2.minutes
        expect(TwoFactor::SmsNotification).to receive(:new).with("07765445412", user.current_otp).and_call_original
        click_link "Resend code"
        expect(page).to have_content("You have been sent another verification code.")

        # Before another minute has passed you should get the same warning
        expect(TwoFactor::SmsNotification).not_to receive(:new)
        click_link "Resend code"
        expect(page).to have_content("Please wait at least a minute before resending your verification code.")
      end

      context "when there is an error from Notify" do
        before do
          error_hash = OpenStruct.new(
            body: "Notifications::Client::ClientError: Exceeded rate limit", code: 429
          )
          allow_any_instance_of(TwoFactor::SmsNotification).to receive(:deliver!).and_raise(
            Notifications::Client::ClientError, error_hash
          )
        end

        it "displays an error if there is an issue calling the notify API" do
          click_button "Log in"

          expect(page).to have_content("Notify was unable to send sms with error: Notifications::Client::ClientError: Exceeded rate limit.")
        end
      end
    end

    context "when I do not have two factor enabled" do
      let!(:user) { create :user, local_authority: default_local_authority }

      before do
        user.update!(otp_required_for_login: false)
      end

      it "I can sign in without an OTP or mobile number prompt" do
        expect(TwoFactor::SmsNotification).not_to receive(:new)
        click_button "Log in"

        expect(page).to have_content("Signed in successfully")
        expect(page).to have_content(user.name)
      end
    end
  end

  context "user session" do
    let!(:user) { create :user, local_authority: default_local_authority }

    before do
      sign_in user
      visit root_path
    end

    it "expires after 6 hours" do
      expect(page).to have_content(user.name)

      # User session should still be active
      travel 5.hours
      visit root_path
      expect(page).to have_content(user.name)

      # User session should expire
      travel 7.hours
      visit root_path
      expect(page).not_to have_content(user.name)

      within(".flash") do
        expect(page).to have_content("Your session expired. Please sign in again to continue.")
      end
    end
  end
end
