# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, name: "Lorrine Krajcik", local_authority: default_local_authority) }
  let(:reviewer) { create(:user, :reviewer, name: "Harley Dicki", local_authority: default_local_authority) }

  it "ensure we can perform a healthcheck" do
    visit "/healthcheck"

    expect(page.body).to have_content("OK")
  end

  it "Home page redirects to login" do
    visit "/"

    expect(page).to have_text("Email")
    expect(page).not_to have_text("Your fast track applications")
  end

  it "User cannot log in with invalid credentials" do
    visit "/"

    fill_in("user[email]", with: reviewer.email)
    fill_in("user[password]", with: "invalid_password")
    click_button("Log in")

    expect(page).to have_text("Invalid Email or password.")
    expect(page).not_to have_text("Signed in successfully.")
  end

  context "as a user with valid credentials" do
    context "as an assessor" do
      before do
        sign_in assessor
        visit "/"
      end

      it "can see their name and role" do
        expect(page).to have_text("Lorrine Krajcik")
        expect(page).to have_text("Case Officer")
      end
    end

    context "as a reviewer" do
      before do
        sign_in reviewer
        visit "/"
      end

      it "can see their name and role" do
        expect(page).to have_text("Harley Dicki")
        expect(page).to have_text("Manager")
      end
    end

    context "when user is an administrator" do
      let(:password) { secure_password }
      let!(:administrator) do
        create(
          :user,
          :administrator,
          local_authority: default_local_authority,
          email: "alice@example.com",
          password:
        )
      end

      it "redirects to the users dashboard" do
        visit "/users/sign_in"
        fill_in("Email", with: "alice@example.com")
        fill_in("Password", with: password)
        click_button("Log in")
        fill_in("Security code", with: administrator.current_otp)
        click_button("Enter code")

        expect(page).to have_current_path("/administrator_dashboard")

        click_link("Log out")

        expect(page).to have_current_path("/users/sign_in")
      end
    end

    context "with a user belonging to a given subdomain" do
      let!(:lambeth) { create(:local_authority, :lambeth) }
      let!(:southwark) { create(:local_authority, :southwark) }
      let(:lambeth_password) { secure_password }
      let(:southwark_password) { secure_password }
      let(:lambeth_assessor) do
        create(:user, :assessor, name: "Lambertina Lamb", password: lambeth_password, local_authority: lambeth)
      end
      let(:southwark_assessor) do
        create(:user, :assessor, name: "Southwarkina Sully", password: southwark_password, local_authority: southwark)
      end

      before do
        @previous_host = Capybara.app_host
        Capybara.app_host = "http://#{lambeth.subdomain}.example.com"
      end

      after do
        Capybara.app_host = "http://#{@previous_host}"
      end

      it "is prevented from logging in to a different subdomain" do
        visit "/"

        fill_in("user[email]", with: southwark_assessor.email)
        fill_in("user[password]", with: southwark_password)
        click_button("Log in")

        expect(page).to have_text("Email")
        expect(page).not_to have_text("Welcome")
      end

      it "is able to login to its allocated subdomain" do
        visit "/"

        fill_in("user[email]", with: lambeth_assessor.email)
        fill_in("user[password]", with: lambeth_password)
        click_button("Log in")
        fill_in("Security code", with: lambeth_assessor.current_otp)
        click_button("Enter code")

        expect(page).to have_text("Signed in successfully.")
      end
    end
  end

  context "when signing in with two factor authentication" do
    before do
      visit "/"

      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
    end

    context "when I do not have a mobile number" do
      let!(:user) do
        create(
          :user,
          local_authority: default_local_authority,
          mobile_number: nil,
          name: "Alice Smith"
        )
      end

      let(:administrator) do
        create(:user, :administrator, local_authority: default_local_authority)
      end

      it "prompts me to enter a mobile number first before receiving my OTP" do
        click_button "Log in"

        expect(page).to have_content("Enter your phone number")
        expect(page).to have_content("To use two-factor authentication we need a UK mobile phone number for your account.")

        fill_in "Mobile number", with: "07722865843"

        expect(TwoFactor::SmsNotification).to receive(:new).with("07722865843", user.current_otp).and_call_original
        click_button "Send code"

        # mobile number saved to session rather than db at this point
        expect(user.reload.mobile_number).to be_nil

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

      it "shows error message if mobile number is invalid" do
        click_button("Log in")
        fill_in("Mobile number", with: "qwerty")
        click_button("Send code")

        expect(page).to have_content("Mobile number is invalid")

        fill_in("Mobile number", with: "07722865843")
        click_button("Send code")
        fill_in("Security code", with: user.current_otp)
        click_button("Enter code")

        expect(page).to have_content("Signed in successfully.")

        click_link("Log out")
        sign_in(administrator)
        visit "/administrator_dashboard"

        expect(page).to have_row_for("Alice Smith", with: "07722 865 843")
      end

      it "shows error message if mobile number is blank" do
        click_button("Log in")
        click_button("Send code")

        expect(page).to have_content("Mobile number can't be blank")

        fill_in("Mobile number", with: "07722865843")
        click_button("Send code")
        fill_in("Security code", with: user.current_otp)
        click_button("Enter code")

        expect(page).to have_content("Signed in successfully.")

        click_link("Log out")
        sign_in(administrator)
        visit "/administrator_dashboard"

        expect(page).to have_row_for("Alice Smith", with: "07722 865 843")
      end

      context "when there is an error from Notify" do
        before do
          error_hash = Struct.new(:body, :code).new(
            "Notifications::Client::BadRequestError: ValidationError: phone_number Must not contain letters or symbols",
            400
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
          expect(user.reload.mobile_number).to be_nil
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
      let!(:user) { create(:user, local_authority: default_local_authority, mobile_number: "07765445412") }

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
          error_hash = Struct.new(:body, :code).new(
            "Notifications::Client::ClientError: Exceeded rate limit",
            429
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

    context "when otp delivery method is set to email" do
      let(:password) { secure_password }
      let(:user) do
        create(
          :user,
          local_authority: default_local_authority,
          otp_delivery_method: :email,
          password:
        )
      end

      it "sends otp via email" do
        visit "/"
        fill_in("Email", with: user.email)
        fill_in("Password", with: password)
        click_button("Log in")

        expect(page).to have_content(
          "Enter the code you have received by email"
        )

        expect(page).to have_content(
          "A 6-digit code has been sent to your email account. This message may take a minute to arrive."
        )

        email = ActionMailer::Base.deliveries.last

        expect(email.subject).to eq(
          "Back Office Planning System verification code"
        )

        current_otp = email.body.encoded[/\d{6}/]
        fill_in("Security code", with: current_otp)
        click_button("Enter code")

        expect(page).to have_content("Signed in successfully.")
      end

      it "resends otp via email" do
        visit "/"
        fill_in("Email", with: user.email)
        fill_in("Password", with: password)
        click_button("Log in")

        travel_to(1.1.minutes.from_now) do
          click_link("Resend code")

          expect(page).to have_content(
            "You have been sent another verification code."
          )

          emails = ActionMailer::Base.deliveries
          expect(emails.count).to eq(2)
          email = emails.last

          expect(email.subject).to eq(
            "Back Office Planning System verification code"
          )

          current_otp = email.body.encoded[/\d{6}/]
          fill_in("Security code", with: current_otp)
          click_button("Enter code")

          expect(page).to have_content("Signed in successfully.")
        end
      end

      context "when mobile number is not set" do
        let(:password) { secure_password }
        let(:user) do
          create(
            :user,
            local_authority: default_local_authority,
            otp_delivery_method: :email,
            password:,
            mobile_number: nil
          )
        end

        it "does not ask for mobile number" do
          visit "/"
          fill_in("Email", with: user.email)
          fill_in("Password", with: password)
          click_button("Log in")

          email = ActionMailer::Base.deliveries.last

          expect(email.subject).to eq(
            "Back Office Planning System verification code"
          )

          current_otp = email.body.encoded[/\d{6}/]
          fill_in("Security code", with: current_otp)
          click_button("Enter code")

          expect(page).to have_content("Signed in successfully.")
        end
      end
    end

    context "when I do not have two factor enabled" do
      let!(:user) { create(:user, local_authority: default_local_authority) }

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

    context "when I use an email with uppercase letters" do
      let!(:user) { create(:user, local_authority: default_local_authority) }

      it "allows me to login with a case insensitive email address" do
        fill_in "Email", with: user.email.upcase

        click_button("Log in")

        expect(page).to have_content("Enter the code you have received by text message")
        expect(page).not_to have_content("Invalid Email or password")
      end
    end
  end

  context "with user session" do
    let!(:user) { create(:user, local_authority: default_local_authority) }

    before do
      sign_in user
      visit "/"
    end

    it "expires after 6 hours" do
      expect(page).to have_content(user.name)

      # User session should still be active
      travel 5.hours
      visit "/"
      expect(page).to have_content(user.name)

      # User session should expire
      travel 7.hours
      visit "/"
      expect(page).not_to have_content(user.name)

      within(".flash") do
        expect(page).to have_content("Your session expired. Please sign in again to continue.")
      end
    end
  end

  context "when recovering a password" do
    it "presents a helpful error message when using an expired link" do
      visit "/"

      click_link("Forgot your password?")
      fill_in("user[email]", with: assessor.email)

      click_button("Send me reset password instructions")
      expect(page).to have_content("You will receive an email with instructions on how to reset your password in a few minutes.")

      email = ActionMailer::Base.deliveries.last
      url = email.body.encoded.match(%r{https?://[^/]+(/\S+)})[1]

      # Now request another link
      click_link("Forgot your password?")
      fill_in("user[email]", with: assessor.email)
      click_button("Send me reset password instructions")

      # Visit old expired link
      visit url
      password = secure_password
      fill_in("user[password]", with: password)
      fill_in("user[password_confirmation]", with: password)
      click_button("Change password")

      within(".govuk-error-summary") do
        expect(page).to have_content("The reset password link you used no longer works. Please request a new link and try again.")
      end
    end
  end

  it "does not allow weak passwords" do
    visit "/"

    click_link("Forgot your password?")
    fill_in("user[email]", with: assessor.email)

    click_button("Send me reset password instructions")
    expect(page).to have_content("You will receive an email with instructions on how to reset your password in a few minutes.")

    email = ActionMailer::Base.deliveries.last
    url = email.body.encoded.match(%r{https?://[^/]+(/\S+)})[1]

    visit url
    password = "password"
    fill_in("user[password]", with: password)
    fill_in("user[password_confirmation]", with: password)
    click_button("Change password")

    within(".govuk-error-summary") do
      expect(page).to have_content("Password is too weak")
    end
  end

  context "when I am a new user who has not confirmed my email" do
    let!(:user) { create(:user, :unconfirmed, local_authority: default_local_authority) }

    it "does not allow me to log in without confirmation" do
      visit("/")
      fill_in("Email", with: user.email)
      fill_in("Password", with: user.password)
      click_button("Log in")
      fill_in("Security code", with: user.current_otp)
      click_button("Enter code")

      expect(page).to have_content("Email is not confirmed")
    end

    it "allows me to log in after confirmation" do
      user.confirm

      visit("/")
      fill_in("Email", with: user.email)
      fill_in("Password", with: user.password)
      fill_in("Security code", with: user.current_otp)
      click_button("Enter code")

      expect(page).to have_text("Signed in successfully.")
    end
  end
end
