# frozen_string_literal: true

RSpec.shared_examples "site visit task", :capybara do |application_type, slug_path|
  let(:local_authority) { create(:local_authority, :default) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!(slug_path) }
  let(:user) { create(:user, local_authority:) }
  let(:tomorrow) { Date.tomorrow }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "allows adding a site visit" do
    within :sidebar do
      click_link "Site visit"
    end

    expect(page).to have_content("No site visits have been recorded yet.")

    within "#new-site-visit-form" do
      click_button "Add site visit"
    end

    expect(page).to have_content("Enter the date of the site visit")
    expect(page).to have_content("Enter some comments about the site visit")

    within "#new-site-visit-form" do
      fill_in "Day", with: 32
      fill_in "Month", with: 12
      fill_in "Year", with: 2025

      click_button "Add site visit"
    end

    expect(page).to have_content("Enter a valid date for the site visit")

    within "#new-site-visit-form" do
      fill_in "Day", with: tomorrow.day
      fill_in "Month", with: tomorrow.month
      fill_in "Year", with: tomorrow.year

      click_button "Add site visit"
    end

    expect(page).to have_content("Enter a date on or before today’s date")

    within "#new-site-visit-form" do
      fill_in "Day", with: 2
      fill_in "Month", with: 10
      fill_in "Year", with: 2025

      fill_in "Comment", with: "Visited the site to assess proximity to neighbour boundary."
      click_button "Add site visit"
    end

    expect(page).to have_selector("[role=alert] p", text: "Site visit successfully recorded")

    click_button "Save changes"
    expect(page).to have_selector("[role=alert] p", text: "Site visits successfully checked")
    expect(page).not_to have_content("No site visits have been recorded yet.")

    expect(task.reload).to be_in_progress

    site_visit = planning_application.site_visits.last
    expect(site_visit).to have_attributes(comment: "Visited the site to assess proximity to neighbour boundary.")

    within("#site-visit-history") do
      expect(page).to have_content(site_visit.address)
    end

    click_button "Save and mark as complete"
    expect(page).to have_selector("[role=alert] p", text: "Site visits successfully checked")

    expect(task.reload).to be_completed
  end

  it "allows editing a site visit" do
    site_visit = create(:site_visit, :with_two_different_documents, planning_application: planning_application)
    last_document = site_visit.documents.last

    within :sidebar do
      click_link "Site visit"
    end

    within "#site-visit-history" do
      expect(page).to have_content(site_visit.comment)
      click_link "Edit"
    end

    expect(page).to have_selector("h1", text: "Edit site visit")

    fill_in "Comments", with: "This is an updated comment."
    check last_document.name

    click_button "Update site visit"

    expect(page).to have_content("Site visit successfully updated")

    expect(site_visit.reload.comment).to eq("This is an updated comment.")
    expect(site_visit.documents.count).to eq(1)
  end

  it "allows deleting a site visit" do
    site_visit = create(:site_visit, planning_application: planning_application)

    within :sidebar do
      click_link "Site visit"
    end

    expect(page).to have_selector("h1", text: "Site visit")
    expect(page).not_to have_content("No site visits have been recorded yet.")

    within "#site-visit-history" do
      expect(page).to have_content(site_visit.comment)
      click_button "Remove"
    end

    expect(page).to have_content("Site visit successfully removed")
    expect(page).to have_content("No site visits have been recorded yet.")
  end

  it "displays uploaded photos in the site visit history" do
    create(
      :site_visit,
      :with_documents,
      planning_application:,
      created_by: user,
      visited_at: 1.day.ago,
      address: planning_application.address,
      comment: "Site inspection completed"
    )

    within :sidebar do
      click_link "Site visit"
    end

    expect(page).to have_selector("h1", text: "Site visit")

    within("#site-visit-history") do
      expect(page).to have_content("Site inspection completed")
      expect(page).to have_link("View in new window")
      expect(page).to have_css("img")
    end
  end
end
