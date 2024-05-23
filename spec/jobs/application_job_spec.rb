# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationJob do
  describe "saving and restoring the current user" do
    let(:user) { create(:user, name: "Background User") }
    let(:buffer) { StringIO.new }
    let(:logs) { buffer.string }

    let(:job_class) do
      Class.new(::ApplicationJob) do
        def perform
          logger.info <<~INFO
            Performed #{self.class.name} for #{Current.user.name}
          INFO
        end
      end
    end

    before do
      ActiveJob::Base.logger = Logger.new(buffer)
      stub_const("MyApplicationJob", job_class)
    end

    it "uses the enqueing user when performing the job later" do
      Current.set(user: user) do
        MyApplicationJob.perform_later
      end

      expect {
        Thread.new {
          perform_enqueued_jobs
        }.join
      }.not_to change(Current, :user).from(nil)

      expect(logs).to include <<~LOGS
        INFO -- : Performed MyApplicationJob for Background User
      LOGS
    end

    it "uses the current user when performing the job now" do
      expect {
        Current.set(user: user) do
          MyApplicationJob.perform_now
        end
      }.not_to change(Current, :user).from(nil)

      expect(logs).to include <<~LOGS
        INFO -- : Performed MyApplicationJob for Background User
      LOGS
    end
  end
end
