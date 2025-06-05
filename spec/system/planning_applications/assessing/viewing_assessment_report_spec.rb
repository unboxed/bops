# frozen_string_literal: true

require "rails_helper"

RSpec.describe "viewing assessment report", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :planx, local_authority: local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }

  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority:
    )
  end

  let!(:planning_application) do
    create(
      :planning_application,
      :prior_approval,
      :in_assessment,
      :with_constraints,
      local_authority:,
      decision: :granted,
      api_user:,
      user: assessor
    )
  end

  let!(:document) do
    create(
      :document,
      planning_application:,
      referenced_in_decision_notice: true,
      numbers: "REF1"
    )
  end

  let!(:policy_schedule) do
    create(
      :policy_schedule,
      number: 2,
      name: "Permitted development rights"
    )
  end

  let!(:policy_part) do
    create(
      :policy_part,
      name: "Development within the curtilage of a dwellinghouse",
      number: 1,
      policy_schedule: policy_schedule
    )
  end

  let!(:policy_class) do
    create(
      :policy_class,
      section: "A",
      name: "enlargement, improvement or other alteration of a dwellinghouse",
      url: "https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-a-enlargement-improvement-or-other-alteration-of-a-dwellinghouse",
      policy_part: policy_part
    )
  end

  let!(:policy_section_A) do
    create(
      :policy_section,
      section: "A",
      policy_class: policy_class,
      title: "Other",
      description: <<~TEXT.squish
        The enlargement, improvement or other alteration of a dwellinghouse
      TEXT
    )
  end

  let!(:policy_section_1a) do
    create(
      :policy_section,
      section: "1a",
      policy_class: policy_class,
      title: "Other",
      description: <<~TEXT.squish
        Development is not permitted by Class A if permission to
        use the dwellinghouse as a dwellinghouse has been granted
        only by virtue of Class M, MA, N, P, PA or Q of Part 3 of
        this Schedule (changes of use)
      TEXT
    )
  end

  let!(:policy_section_1b) do
    create(
      :policy_section,
      section: "1b",
      policy_class: policy_class,
      title: "Other",
      description: <<~TEXT.squish
        Development is not permitted by Class A if as a result
        of the works, the total area of ground covered by
        buildings within the curtilage of the dwellinghouse
        (other than the original dwellinghouse) would exceed
        50% of the total area of the curtilage (excluding the
        ground area of the original dwellinghouse)
      TEXT
    )
  end

  let!(:policy_section_1c) do
    create(
      :policy_section,
      section: "1c",
      policy_class: policy_class,
      title: "Other",
      description: <<~TEXT.squish
        Development is not permitted by Class A if the height
        of the part of the dwellinghouse enlarged, improved or
        altered would exceed the height of the highest part of
        the roof of the existing dwellinghouse
      TEXT
    )
  end

  before do
    Current.user = assessor

    create(
      :recommendation,
      planning_application:
    )

    create(
      :assessment_detail,
      :summary_of_work,
      planning_application:,
      entry: "This is the summary of work."
    )

    create(
      :assessment_detail,
      :site_description,
      planning_application:,
      entry: "This is the location description."
    )

    create(
      :assessment_detail,
      :additional_evidence,
      planning_application:,
      entry: "This is the additional evidence."
    )

    create(
      :consultee,
      consultation: planning_application.consultation,
      name: "Alice Smith",
      origin: :external
    )

    create(
      :assessment_detail,
      :consultation_summary,
      planning_application:,
      entry: "This is the consultation summary."
    )

    create(
      :site_history,
      planning_application:,
      application_number: "22-00999-LDCP",
      description: "This is the past application history summary."
    )

    create(
      :planning_application_policy_class,
      planning_application:,
      policy_class:
    )

    create(
      :planning_application_policy_section,
      planning_application:,
      policy_section: policy_section_A
    )

    create(
      :planning_application_policy_section,
      :with_comments,
      :complies,
      planning_application:,
      policy_section: policy_section_1a
    )

    create(
      :planning_application_policy_section,
      :with_comments,
      :does_not_comply,
      planning_application:,
      policy_section: policy_section_1b
    )

    create(
      :planning_application_policy_section,
      planning_application:,
      policy_section: policy_section_1c
    )
  end

  it "lets the user view and download the report" do
    sign_in(assessor)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
    click_link("Review and submit recommendation")
    click_button("Assessment report details")

    within("#application-details-section") do
      expect(page).to have_content(planning_application.applicant_name)
      expect(page).to have_content(planning_application.reference)
      expect(page).to have_content(planning_application.application_type.description)
      expect(page).to have_content(planning_application.determination_date.to_fs)
      expect(page).to have_content(planning_application.user.name)
    end

    within("#policy-classes-section") do
      expect(page).to have_selector("h3", text: "Assessment against legislation")
      expect(page).to have_link(policy_class.description, href: policy_class.url)

      within ".bops-assessment-list" do
        within ".bops-assessment-list__row:nth-of-type(4)" do
          expect(page).to have_selector(".bops-assessment-list__section", text: "A")

          within ".bops-assessment-list__description" do
            expect(page).to have_selector("p.govuk-body:first-child", text: policy_section_A.description)
            expect(page).not_to have_selector(".bops-ticket-panel")
          end

          within ".bops-assessment-list__status" do
            expect(page).to have_selector(".govuk-tag.govuk-tag--light-blue", text: "To be determined")
          end
        end

        within ".bops-assessment-list__row:nth-of-type(1)" do
          expect(page).to have_selector(".bops-assessment-list__section", text: "1a")

          within ".bops-assessment-list__description" do
            expect(page).to have_selector("p.govuk-body:first-child", text: policy_section_1a.description)

            within ".bops-ticket-panel" do
              expect(page).to have_selector(".bops-ticket-panel__body", text: "A comment")
              expect(page).to have_selector(".bops-ticket-panel__footer", text: "By #{assessor.name} on #{Date.current.to_fs(:day_month_year_slashes)}")
            end
          end

          within ".bops-assessment-list__status" do
            expect(page).to have_selector(".govuk-tag.govuk-tag--green", text: "Complies")
          end
        end

        within ".bops-assessment-list__row:nth-of-type(2)" do
          expect(page).to have_selector(".bops-assessment-list__section", text: "1b")

          within ".bops-assessment-list__description" do
            expect(page).to have_selector("p.govuk-body:first-child", text: policy_section_1b.description)

            within ".bops-ticket-panel" do
              expect(page).to have_selector(".bops-ticket-panel__body", text: "A comment")
              expect(page).to have_selector(".bops-ticket-panel__footer", text: "By #{assessor.name} on #{Date.current.to_fs(:day_month_year_slashes)}")
            end
          end

          within ".bops-assessment-list__status" do
            expect(page).to have_selector(".govuk-tag.govuk-tag--red", text: "Does not comply")
          end
        end

        within ".bops-assessment-list__row:nth-of-type(3)" do
          expect(page).to have_selector(".bops-assessment-list__section", text: "1c")

          within ".bops-assessment-list__description" do
            expect(page).to have_selector("p.govuk-body:first-child", text: policy_section_1c.description)
            expect(page).not_to have_selector(".bops-ticket-panel")
          end

          within ".bops-assessment-list__status" do
            expect(page).to have_selector(".govuk-tag.govuk-tag--light-blue", text: "To be determined")
          end
        end
      end
    end

    expect(page).to have_content("Conservation area")
    expect(page).to have_content("22-00999-LDCP")
    expect(page).to have_content("This is the past application history summary.")
    expect(page).to have_content("This is the summary of work.")
    expect(page).to have_content("This is the location description.")
    expect(page).to have_content("Alice Smith (external)")
    expect(page).to have_content("This is the consultation summary.")
    expect(page).to have_content(document.name)

    expect(page).not_to have_content("This is the additional evidence.")

    expect(page).to have_link(
      "Download assessment report as PDF",
      href: planning_application_assessment_report_download_path(
        planning_application,
        format: "pdf"
      )
    )
  end
end
