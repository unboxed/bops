# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::AuditableMailer, type: :mailer do
  subject do
    Class.new(Mail::Notify::Mailer) do
      include BopsCore::AuditableMailer

      def self.name
        "AnonymousMailer"
      end

      audit :notification, event: "event.scope", payload: {foo: "bar"}

      def notification
        mail(
          to: "alice@example.com",
          subject: "Test Email",
          body: "Testing, testing, testing ...",
          content_type: "text/plain"
        )
      end
    end
  end

  before do
    stub_const("AnonymousMailer", subject)
  end

  it "sends an audit event when the message is delivered immediately" do
    expect {
      subject.notification.deliver_now
    }.to have_audit("event.scope").with_payload(foo: "bar")
  end

  it "doesn't send an audit event when the message is delivered later" do
    expect {
      subject.notification.deliver_later
    }.not_to have_audit("event.scope")
  end

  it "sends an audit event when the message is delivered later" do
    subject.notification.deliver_later

    expect {
      perform_enqueued_jobs
    }.to have_audit("event.scope").with_payload(foo: "bar")
  end
end
