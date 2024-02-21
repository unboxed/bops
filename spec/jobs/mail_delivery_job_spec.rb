# frozen_string_literal: true

require "rails_helper"

RSpec.describe MailDeliveryJob do
  describe "saving and restoring the current user" do
    let(:user) { create(:user, name: "Background User") }
    let(:deliveries) { ActionMailer::Base.deliveries }
    let(:last_email) { deliveries.last }

    before do
      Current.user = user

      stub_const("MyMailer", mailer_class)
    end

    context "a mailer with no arguments" do
      let(:mailer_class) do
        Class.new(::ApplicationMailer) do
          def email
            mail(to: "someone@example.com", subject: "Test Message") do |format|
              format.text do
                <<~MESSAGE
                  Hello from #{Current.user.name}
                MESSAGE
              end
            end
          end
        end
      end

      it "delivers the email" do
        perform_enqueued_jobs {
          MyMailer.email.deliver_later
        }

        expect(last_email.body).to eq <<~MESSAGE
          Hello from Background User
        MESSAGE
      end
    end

    context "a mailer with positional arguments" do
      let(:mailer_class) do
        Class.new(::ApplicationMailer) do
          def email(positional)
            mail(to: "someone@example.com", subject: "Test Message") do |format|
              format.text do
                <<~MESSAGE
                  Hello from #{Current.user.name}

                  Arguments: #{positional.inspect}
                MESSAGE
              end
            end
          end
        end
      end

      it "delivers the email" do
        perform_enqueued_jobs {
          MyMailer.email("positional").deliver_later
        }

        expect(last_email.body).to eq <<~MESSAGE
          Hello from Background User

          Arguments: "positional"
        MESSAGE
      end
    end

    context "a mailer with keyword arguments" do
      let(:mailer_class) do
        Class.new(::ApplicationMailer) do
          def email(keyword:)
            mail(to: "someone@example.com", subject: "Test Message") do |format|
              format.text do
                <<~MESSAGE
                  Hello from #{Current.user.name}

                  Arguments: keyword: #{keyword.inspect}
                MESSAGE
              end
            end
          end
        end
      end

      it "delivers the email" do
        perform_enqueued_jobs {
          MyMailer.email(keyword: "keyword").deliver_later
        }

        expect(last_email.body).to eq <<~MESSAGE
          Hello from Background User

          Arguments: keyword: "keyword"
        MESSAGE
      end
    end

    context "a mailer with mixed arguments" do
      let(:mailer_class) do
        Class.new(::ApplicationMailer) do
          def email(positional, keyword:)
            mail(to: "someone@example.com", subject: "Test Message") do |format|
              format.text do
                <<~MESSAGE
                  Hello from #{Current.user.name}

                  Arguments: #{positional.inspect}, keyword: #{keyword.inspect}
                MESSAGE
              end
            end
          end
        end
      end

      it "delivers the email" do
        perform_enqueued_jobs {
          MyMailer.email("positional", keyword: "keyword").deliver_later
        }

        expect(last_email.body).to eq <<~MESSAGE
          Hello from Background User

          Arguments: "positional", keyword: "keyword"
        MESSAGE
      end
    end
  end
end
