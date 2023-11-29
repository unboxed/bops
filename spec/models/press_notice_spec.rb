# frozen_string_literal: true

require "rails_helper"

RSpec.describe PressNotice do
  describe "validations" do
    subject(:press_notice) { described_class.new }

    describe "#planning_application" do
      it "validates presence" do
        expect { press_notice.valid? }.to change { press_notice.errors[:planning_application] }.to ["must exist"]
      end
    end

    describe "#required" do
      it "validates inclusion in [true, false]" do
        expect { press_notice.valid? }.to change { press_notice.errors[:required] }.to ["Choose 'Yes' or 'No'"]
      end
    end

    describe "#reasons" do
      context "when required is 'true'" do
        subject(:press_notice) { described_class.new(required: true) }

        it "validates presence" do
          expect { press_notice.valid? }.to change { press_notice.errors[:reasons] }.to ["Provide a reason for the press notice"]
        end
      end

      context "when required is 'false'" do
        subject(:press_notice) { described_class.new(required: false) }

        it "does not validate presence" do
          expect { press_notice.valid? }.not_to(change { press_notice.errors[:reasons] })
        end
      end
    end

    describe "callbacks" do
      describe "::after_save #audit_press_notice!" do
        let(:default_local_authority) { create(:local_authority, :default) }
        let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
        let!(:planning_application) { create(:planning_application, local_authority: default_local_authority) }

        before do
          Current.user = assessor
        end

        context "when press notice marked as required" do
          let(:press_notice) { create(:press_notice, :required, planning_application:) }

          it "adds an audit entry with the reasons when creating the press notice response" do
            expect do
              press_notice
            end.to change(Audit, :count).by(1)

            expect(Audit.last).to have_attributes(
              planning_application_id: planning_application.id,
              activity_type: "press_notice",
              audit_comment: "Press notice has been marked as required with the following reasons: environment, development_plan",
              user: assessor
            )
          end

          it "adds an audit entry with the reasons when updating the press notice response" do
            press_notice

            expect do
              press_notice.update!(reasons: %w[ancient_monument])
            end.to change(Audit, :count).by(1)

            expect(Audit.last).to have_attributes(
              planning_application_id: press_notice.planning_application.id,
              activity_type: "press_notice",
              audit_comment: "Press notice has been marked as required with the following reasons: ancient_monument",
              user: assessor
            )
          end
        end

        context "when press notice marked as not required" do
          let(:press_notice) { create(:press_notice, planning_application:) }

          it "adds an audit entry when creating the press notice response" do
            expect do
              press_notice
            end.to change(Audit, :count).by(1)

            expect(Audit.last).to have_attributes(
              planning_application_id: planning_application.id,
              activity_type: "press_notice",
              audit_comment: "Press notice has been marked as not required",
              user: assessor
            )
          end
        end
      end

      describe "::after_update #update_consultation_end_date!" do
        let(:default_local_authority) { create(:local_authority, :default) }
        let!(:planning_application) { create(:planning_application, local_authority: default_local_authority) }
        let!(:consultation) { create(:consultation, planning_application:) }
        let(:press_notice) { create(:press_notice, planning_application:) }

        context "when there is an update to the published_at date" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is an update of 21 days added to the consultation end date" do
            expect do
              press_notice.update(published_at: Time.zone.local(2023, 3, 15))
            end.to change(consultation, :end_date)
              .from(Time.zone.local(2023, 3, 28, 23, 59, 59, 999999))
              .to(Time.zone.local(2023, 4, 5, 23, 59, 59, 999999))
          end
        end

        context "when there is an update to another field" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is no update to the consultation end date" do
            expect { press_notice.update(press_sent_at: Time.zone.local(2023, 3, 15)) }.not_to change(consultation, :end_date)
          end
        end

        context "when consultation end date is later than the published at date + 21 days" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 4, 10, 23, 59, 59, 999999)
            )
          end

          it "there is no update to the consultation end date" do
            expect { press_notice.update(published_at: Time.zone.local(2023, 3, 15)) }.not_to change(consultation, :end_date)
          end
        end

        context "when consultation end date is less than the published at date + 21 days" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is an update to the consultation end date" do
            expect do
              press_notice.update(published_at: Time.zone.local(2023, 3, 15))
            end.to change(consultation, :end_date)
              .from(Time.zone.local(2023, 3, 28, 23, 59, 59, 999999))
              .to(Time.zone.local(2023, 4, 5, 23, 59, 59, 999999))
          end
        end
      end
    end
  end
end
