# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning applications", type: :system do
  let!(:local_authority) { create(:local_authority, :default) }
  let(:consultee) { create(:consultee, :external, email_address: "james.consultee@council.gov.uk", consultation: planning_application.consultation) }
  let(:sgid) { consultee.sgid(expires_in: 1.day, for: "magic_link") }
  let(:reference) { planning_application.reference }
  let(:user) { create(:user) }
  let(:documents) { create_list(:document, 3, :consultees) }

  let(:today) do
    Time.zone.today
  end

  before do
    planning_application.consultation.start_deadline
    visit "/consultees/planning_applications/#{reference}?sgid=#{sgid}"
  end

  shared_examples "a consultee response form" do
    context "with valid magic link" do
      it "I can view the planning_application" do
        expect(page).to have_current_path("/consultees/planning_applications/#{reference}?sgid=#{sgid}")
        expect(page).to have_content(planning_application.full_address)
        expect(page).to have_content("Application number #{reference}")
        expect(page).to have_content(planning_application.description)
        expect(page).to have_content(planning_application.user.name)
        expect(page).to have_content(planning_application.consultation.end_date.to_fs(:day_month_year_slashes))
      end

      it "includes a notification banner" do
        expect(page).to have_content("Submit your comments by #{planning_application.consultation.end_date.to_fs(:day_month_year_slashes)}")
        expect(page).to have_content("Jump to comments section.")
      end

      it "includes documents on planning application overview" do
        expect(page).to have_content(documents.first.name)
        expect(page).to have_link "Download", href: %r{/files/#{documents.first.blob.key}\?sgid=}
        expect(page).to have_content(documents.last.name)
        expect(page).to have_link "Download", href: %r{/files/#{documents.last.blob.key}\?sgid=}

        find_all("a", text: "Download").first.click
        expect(page.status_code).to be < 400
      end

      it "successfully submits two comments" do
        choose "No objection"

        click_button "Submit Response"

        expect(page).to have_content("Response can't be blank")

        fill_in "Response", with: "We are happy for this application to proceed"
        fill_in "Your email address", with: "tom@gmail.com"

        click_button "Submit Response"
        expect(page).to have_content("Email must be a council.gov.uk email address.")

        fill_in "Your email address", with: "tom@council.gov.uk"
        click_button "Submit Response"

        expect(page).to have_content("Your response has been updated")

        within "#comments-form" do
          expect(page).to have_selector("h2", text: "Response")

          within ".consultee-response:first-of-type" do
            expect(page).to have_selector("p time", text: "Received on #{today.to_fs}")
            expect(page).to have_selector("p span", text: "No objection")
            expect(page).to have_selector("p span", text: "Private")
            expect(page).to have_selector("p", text: "We are happy for this application to proceed")
          end

          choose "Amendments needed"

          fill_in "Response", with: "On further reflection we believe the applicant should reduce the size and scale of the proposed development"

          click_button "Submit Response"

          within ".consultee-response:first-of-type" do
            expect(page).to have_selector("p time", text: "Received on #{today.to_fs}")
            expect(page).to have_selector("p span", text: "Amendments needed")
            expect(page).to have_selector("p span", text: "Private")
            expect(page).to have_selector("p", text: "On further reflection we believe the applicant should reduce the size and scale of the proposed development")
          end
        end
      end
    end

    context "with expired magic link" do
      let!(:sgid) { consultee.sgid(expires_in: 1.minute, for: "magic_link") }
      let(:mail) { ActionMailer::Base.deliveries }

      before do
        travel 2.minutes
        visit "/consultees/planning_applications/#{reference}?sgid=#{sgid}"
      end

      it "I can see that the link has expired and can resend link" do
        expect(page).not_to have_content(planning_application.full_address)
        expect(page).not_to have_content(reference)
        expect(page).to have_content("Magic link expired")
        expect(page).to have_content("The email must be a council.gov.uk address.")
        expect(page).to have_content("Contact #{local_authority.feedback_email} if you think there's a problem.")

        fill_in "Request a new email for", with: "tom@gmail.com"

        delivered_emails = mail.count
        click_button("Request a new magic link")
        expect(page).to have_content("Email must be a council.gov.uk address.")

        fill_in "Request a new email for", with: "tom@council.gov.uk"
        click_button("Request a new magic link")

        expect(page).to have_content("A magic link has been sent to: tom@council.gov.uk")

        perform_enqueued_jobs
        expect(mail.count).to eql(delivered_emails + 1)

        sent_email_address = mail.last.to[0]
        expect(sent_email_address).to eql("tom@council.gov.uk")

        url = mail.last.body.raw_source.match(/http[^\s]+/)

        visit url
        expect(page).to have_content(reference)
      end

      it "does not resend the link if attempted within 1 minute" do
        delivered_emails = mail.count
        click_button("Request a new magic link")
        expect(page).to have_content("A magic link has been sent to: #{consultee.email_address}")
        perform_enqueued_jobs
        expect(mail.count).to eql(delivered_emails + 1)

        # Attempt to resend immediately
        delivered_emails = mail.count
        visit "/consultees/planning_applications/#{reference}?sgid=#{sgid}"
        click_button("Request a new magic link")
        expect(page).to have_content("A magic link was sent recently. Please wait at least 1 minute before requesting another.")
        expect(mail.count).to eql(delivered_emails)

        # Wait for 1 minute and try again
        travel 1.minute
        click_button("Request a new magic link")
        expect(page).to have_content("A magic link has been sent to: #{consultee.email_address}")
        perform_enqueued_jobs
        expect(mail.count).to eql(delivered_emails + 1)
      end
    end

    context "with expired magic link for other sgid purpose" do
      let!(:sgid) { consultee.sgid(expires_in: 1.minute, for: "other_link") }

      it "I can't view the planning_application" do
        travel 2.minutes
        visit "/consultees/planning_applications/#{reference}?sgid=#{sgid}"
        expect(page).not_to have_content(reference)
        expect(page).not_to have_content("Your magic link has expired. Click resend to generate another link.")
        expect(page).to have_content("Not found")
      end
    end

    context "with invalid sgid" do
      let!(:sgid) { consultee.sgid(expires_in: 1.day, for: "other_link") }

      it "I can't view the planning application" do
        expect(page).not_to have_content(reference)
        expect(page).to have_content("Not found")
      end
    end

    context "without sgid" do
      let!(:sgid) { nil }

      it "I can't view the planning application" do
        expect(page).not_to have_content(reference)
        expect(page).to have_content("Not found")
      end
    end
  end

  context "when the planning application is a pre-app" do
    let!(:planning_application) { create(:planning_application, :pre_application, local_authority:, user:, documents:) }

    it_behaves_like "a consultee response form"
  end

  context "when the planning application is a full application" do
    let!(:planning_application) { create(:planning_application, :planning_permission, local_authority:, user:, documents:) }

    it_behaves_like "a consultee response form"
  end
end
