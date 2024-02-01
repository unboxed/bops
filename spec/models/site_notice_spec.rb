# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteNotice do
  describe "validations" do
    subject(:site_notice) { described_class.new }

    describe "#planning_application" do
      it "validates presence" do
        expect { site_notice.valid? }.to change { site_notice.errors[:planning_application] }.to ["must exist"]
      end
    end

    describe "#required" do
      it "validates inclusion in [true, false]" do
        expect { site_notice.valid? }.to change { site_notice.errors[:required] }.to ["Choose 'Yes' or 'No'"]
      end
    end

    describe "callbacks" do
      describe "::after_update #extend_consultation!" do
        let(:default_local_authority) { create(:local_authority, :default) }
        let!(:planning_application) { create(:planning_application, local_authority: default_local_authority) }
        let!(:consultation) { create(:consultation, planning_application:) }
        let(:site_notice) { create(:site_notice, planning_application:) }

        context "when there is an update to the displayed_at date" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is an update of 21 days added to the consultation end date" do
            expect do
              site_notice.update(displayed_at: Time.zone.local(2023, 3, 15))
            end.to change(consultation, :end_date)
              .from(Time.zone.local(2023, 3, 28).to_date)
              .to(Time.zone.local(2023, 4, 5).to_date)
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
            expect { site_notice.update(content: "bla") }.not_to change(consultation, :end_date)
          end
        end

        context "when consultation end date is later than the displayed at date + 21 days" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 4, 10, 23, 59, 59, 999999)
            )
          end

          it "there is no update to the consultation end date" do
            expect { site_notice.update(displayed_at: Time.zone.local(2023, 3, 15)) }.not_to change(consultation, :end_date)
          end
        end

        context "when consultation end date is less than the displayed at date + 21 days" do
          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is an update to the consultation end date" do
            expect do
              site_notice.update(displayed_at: Time.zone.local(2023, 3, 15))
            end.to change(consultation, :end_date)
              .from(Time.zone.local(2023, 3, 28).to_date)
              .to(Time.zone.local(2023, 4, 5).to_date)
          end
        end

        context "when application has been marked as requiring an EIA and there is an update to the displayed_at date" do
          let!(:environment_impact_assessment) { create(:environment_impact_assessment, planning_application:) }

          before do
            consultation.update!(
              start_date: Time.zone.local(2023, 3, 28),
              end_date: Time.zone.local(2023, 3, 28, 23, 59, 59, 999999)
            )
          end

          it "there is an update of 30 days added to the consultation end date" do
            expect do
              site_notice.update(displayed_at: Time.zone.local(2023, 3, 15))
            end.to change(consultation, :end_date)
              .from(Time.zone.local(2023, 3, 28).to_date)
              .to(Time.zone.local(2023, 4, 14).to_date)
          end
        end
      end
    end
  end
end
