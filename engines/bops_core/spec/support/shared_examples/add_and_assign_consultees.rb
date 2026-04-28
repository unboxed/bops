# frozen_string_literal: true

RSpec.shared_examples "add and assign consultees task", :capybara do |application_type|
  let(:local_authority) { create(:local_authority, :default) }
  let(:api_user) { create(:api_user, :planx, local_authority:) }
  let(:task) { case_record.find_task_by_slug_path!(slug_path) }
  let(:user) { create(:user, local_authority:) }

  let(:reference) { planning_application.reference }
  let(:case_record) { planning_application.case_record }
  let(:consultation) { planning_application.consultation }

  before do
    create(:contact, :external, name: "Joe Sparks", role: "Planning Officer", organisation: "London Fire Brigade")
    create(:contact, :internal, local_authority:, name: "Chris Wood", role: "Tree Officer", organisation: local_authority.council_name)

    sign_in(user)

    visit "/#{path_prefix}/#{reference}/#{slug_path}"
    expect(page).to have_selector("h1", text: "Add and assign consultees")
  end

  it "allows other consultees to be added" do
    click_button "Add other consultees"
    expect(page).to have_selector("h1", text: "Add other consultee")

    fill_in "Search for a consultee", with: "Chris Wood"
    expect(page).to have_selector("#add-consultee__listbox li:first-child", text: "Chris Wood (Tree Officer, PlanX Council)")

    pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
    expect(page).to have_field("Search for a consultee", with: "Chris Wood")

    click_button "Assign"
    expect(page).to have_content("Other consultee was successfully added")
  end

  context "when there is an existing other consultee" do
    context "and they have not been consulted" do
      before do
        create(:consultee, :external, consultation:, name: "Joe Sparks", role: "Planning Officer", organisation: "London Fire Brigade")

        visit "/#{path_prefix}/#{reference}/#{slug_path}"
      end

      it "allows the other consultee to be removed" do
        within ".govuk-summary-card" do
          expect(page).to have_selector("h2", text: "Other")
          expect(page).to have_selector("dt", text: "London Fire Brigade")
          expect(page).to have_selector("dd", text: "Joe Sparks, Planning Officer")

          click_button "Change"
        end

        expect(page).to have_selector("h1", text: "Edit other consultees")
        expect(page).to have_link("Remove")

        accept_confirm do
          click_link "Remove"
        end

        expect(page).to have_content("Other consultee was successfully removed")
      end
    end

    context "and they have been consulted" do
      before do
        create(:consultee, :external, :consulted, consultation:, name: "Joe Sparks", role: "Planning Officer", organisation: "London Fire Brigade")

        visit "/#{path_prefix}/#{reference}/#{slug_path}"
      end

      it "doesn't allow the other consultees to be removed" do
        within ".govuk-summary-card" do
          expect(page).to have_selector("h2", text: "Other")
          expect(page).to have_selector("dt", text: "London Fire Brigade")
          expect(page).to have_selector("dd", text: "Joe Sparks, Planning Officer")

          click_button "Change"
        end

        expect(page).to have_selector("h1", text: "Edit other consultees")
        expect(page).not_to have_link("Remove")
      end
    end
  end

  context "when there are no constraints" do
    it "shows a message about no constraints" do
      expect(page).to have_content("No planning constraints have been identified")
      expect(page).to have_content("You can still add consultees manually")
    end
  end

  context "when constraints have been identified" do
    let!(:constraint) { create(:constraint, :tpo) }
    let!(:pa_constraint) { create(:planning_application_constraint, planning_application:, constraint:) }

    context "and consultees haven't been identified" do
      before do
        visit "/#{path_prefix}/#{reference}/#{slug_path}"
      end

      it "can be assigned to a consultee" do
        expect(page).to have_content("Consultees have been automatically matched to the identified planning constraints")
        expect(page).to have_content("Check the assignments are correct, make any changes, then confirm")

        within ".govuk-summary-card" do
          expect(page).to have_selector("h2", text: "Tree preservation zone")
          expect(page).to have_selector("strong", text: "Unassigned")

          click_link "Change"
        end

        expect(page).to have_selector("h1", text: "Tree preservation zone")

        within_fieldset "Is consultation needed for this constraint?" do
          expect(page).to have_checked_field("Yes")

          fill_in "Search for a consultee", with: "Chris Wood"
          expect(page).to have_selector("#add-consultee__listbox li:first-child", text: "Chris Wood (Tree Officer, PlanX Council)")

          pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
          expect(page).to have_field("Search for a consultee", with: "Chris Wood")

          click_button "Assign"
        end

        expect(page).to have_content("Consultee was successfully added to constraint")

        click_button "Save and return"
        expect(page).to have_content("Constraint was successfully saved")

        within ".govuk-summary-card" do
          expect(page).to have_selector("h2", text: "Tree preservation zone")
          expect(page).to have_selector("dt", text: "PlanX Council")
          expect(page).to have_selector("dd", text: "Chris Wood, Tree Officer")
        end
      end
    end

    context "and the consultee has been identified" do
      let(:consultee) do
        create(:consultee, :internal, consultation:, name: "Chris Woods", role: "Tree Officer", organisation: "PlanX Council", email_address: "chris.woods@example.com")
      end

      before do
        pa_constraint.consultees << consultee

        visit "/#{path_prefix}/#{reference}/#{slug_path}"
      end

      it "can be marked as not needed" do
        expect(page).to have_content("Consultees have been automatically matched to the identified planning constraints")
        expect(page).to have_content("Check the assignments are correct, make any changes, then confirm")

        within ".govuk-summary-card" do
          expect(page).to have_selector("h2", text: "Tree preservation zone")
          expect(page).to have_selector("dt", text: "PlanX Council")
          expect(page).to have_selector("dd", text: "Chris Woods, Tree Officer")

          click_link "Change"
        end

        expect(page).to have_selector("h1", text: "Tree preservation zone")

        within ".govuk-summary-list" do
          within ".govuk-summary-list__row:nth-of-type(1)" do
            expect(page).to have_selector("dt", text: "Name / Role")
            expect(page).to have_selector("dd", text: "Chris Woods, Tree Officer")
          end

          within ".govuk-summary-list__row:nth-of-type(2)" do
            expect(page).to have_selector("dt", text: "Organisation")
            expect(page).to have_selector("dd", text: "PlanX Council")
          end

          within ".govuk-summary-list__row:nth-of-type(3)" do
            expect(page).to have_selector("dt", text: "Email")
            expect(page).to have_selector("dd", text: "chris.woods@example.com")
          end

          within ".govuk-summary-list__row:nth-of-type(4)" do
            expect(page).to have_selector("dt", text: "Type / Status")
            expect(page).to have_selector("dd", text: "Internal Not consulted")
          end
        end

        within_fieldset "Is consultation needed for this constraint?" do
          expect(page).to have_checked_field("Yes")

          choose "No"
          expect(page).to have_checked_field("No")
        end

        click_button "Save and return"
        expect(page).to have_content("Constraint was successfully saved")

        within ".govuk-summary-card" do
          expect(page).to have_selector("h2", text: "Tree preservation zone")
          expect(page).to have_selector("strong", text: "Not needed")
        end
      end
    end
  end
end
