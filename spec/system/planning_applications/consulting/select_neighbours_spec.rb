# frozen_string_literal: true

require "rails_helper"
require "faraday"

RSpec.describe "Send letters to neighbours", js: true do
  let(:api_user) { create(:api_user, name: "PlanX") }
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let(:application_type) { create(:application_type, :prior_approval) }

  let(:planning_application) do
    create(:planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      application_type:,
      local_authority: default_local_authority,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com",
      make_public: true,
      uprn: uprn)
  end
  let(:uprn) { "20000111111" }

  let(:consultation) do
    planning_application.consultation
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")

    ENV["OS_VECTOR_TILES_API_KEY"] = "testtest"
    allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(instance_double(Faraday::Response, status: 200, body: "some data"))
    allow_any_instance_of(Apis::OsPlaces::Query).to receive(:find_addresses).and_return(Faraday.new.get)
    allow_any_instance_of(Apis::Mapit::Query).to receive(:fetch).and_return(Faraday.new.get)

    stub_any_os_places_api_request

    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
  end

  it "displays the planning application address, reference, and addresses submitted by applicant" do
    click_link "Consultees, neighbours and publicity"
    click_link "Select and add neighbours"

    expect(page).to have_content("Select and add neighbours")

    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content(planning_application.reference)

    expect(page).to have_content("Neighbours submitted by applicant")
    expect(page).to have_content("London, 80 Underhill Road, SE22 0QU")
    expect(page).to have_content("London, 78 Underhill Road, SE22 0QU")
  end

  it "allows me to add addresses manually" do
    click_link "Consultees, neighbours and publicity"
    click_link "Select and add neighbours"

    # Rspec doesn't like the govuk design extra details link, so this is clicking "Manually add addresses"
    page.find(:xpath, "//*[@id='main-content']/div[2]/div/details[2]/summary/span").click

    allow_any_instance_of(Apis::OsPlaces::Query).to receive(:find_addresses).with("60-").and_return(instance_double(Faraday::Response, status: 200, body: {header: {}, results: [{DPA: {ADDRESS: "60-62, Commercial Street, E16LT"}}]}))

    fill_in "Search neighbours by address", with: "60-"
    # # Something weird is happening with the javascript, so having to double click for it to register
    # # This doesn't happen in "real life"
    page.find(:xpath, "//li[text()='60-62, Commercial Street, E16LT']").click

    within("#manual-address-container") do
      expect(page).to have_content("60-62, Commercial Street, E16LT")
    end

    allow_any_instance_of(Apis::OsPlaces::Query).to receive(:find_addresses).with("61-").and_return(instance_double(Faraday::Response, status: 200, body: {header: {}, results: [{DPA: {ADDRESS: "61-62, Commercial Street, E16LT"}}]}))

    fill_in "Search neighbours by address", with: "61-"
    page.find(:xpath, "//li[text()='61-62, Commercial Street, E16LT']").click

    within("#manual-address-container") do
      expect(page).to have_content("61-62, Commercial Street, E16LT")
    end

    expect(page).not_to have_content("Contacted neighbours")

    click_button "Continue to sending letters"

    expect(page).to have_content("Addresses have been successfully added.")

    within("#selected-neighbours-list") do
      expect(page).to have_content("60-62, Commercial Street, E16LT")
      expect(page).to have_content("61-62, Commercial Street, E16LT")
    end
  end

  it "allows me to delete addresses" do
    click_link "Consultees, neighbours and publicity"
    click_link "Select and add neighbours"

    # Rspec doesn't like the govuk design extra details link, so this is clicking "Manually add addresses"
    page.find(:xpath, "//*[@id='main-content']/div[2]/div/details[2]/summary/span").click

    allow_any_instance_of(Apis::OsPlaces::Query).to receive(:find_addresses).with("60-").and_return(instance_double(Faraday::Response, status: 200, body: {header: {}, results: [{DPA: {ADDRESS: "60-62, Commercial Street, E16LT"}}]}))
    fill_in "Search neighbours by address", with: "60-"

    page.find(:xpath, "//li[text()='60-62, Commercial Street, E16LT']").click

    expect(page).to have_content("60-62, Commercial Street, E16LT")

    click_link "Remove"

    within("#manual-address-container") do
      expect(page).not_to have_content("60-62, Commercial Street, E16LT")
    end
  end

  context "when drawing a polygon to search for addresses" do
    let(:geojson) do
      {
        "EPSG:3857" => {
          type: "FeatureCollection",
          features: [
            {
              type: "Feature",
              geometry: {
                type: "Polygon",
                coordinates: [
                  [
                    [-0.07837477827741827, 51.49960885888714],
                    [-0.0783663401899492, 51.49932756979237],
                    [-0.07795182562987539, 51.49943999679809],
                    [-0.07803420855642619, 51.49966559098456],
                    [-0.07837477827741827, 51.49960885888714]
                  ]
                ]
              }
            }
          ]
        },
        "EPSG:27700" => {
          type: "FeatureCollection",
          features: [
            {
              type: "Feature",
              geometry: {
                type: "Polygon",
                coordinates: [
                  [
                    [533_660.325620841, 179_698.37392323086],
                    [533_649.9051589356, 179_685.7419492526],
                    [533_657.22377888, 179_679.7348004314],
                    [533_666.9384742181, 179_692.96876213647],
                    [533_660.325620841, 179_698.37392323086]
                  ]
                ]
              },
              properties: nil
            }
          ]
        }
      }
    end

    before do
      stub_os_places_api_request_for_polygon(geojson["EPSG:27700"][:features][0])
      Rails.configuration.os_vector_tiles_api_key = "testtest"
      click_link "Consultees, neighbours and publicity"
      click_link "Select and add neighbours"

      mock_csrf_token
      # Mimic drawing the polygon on the map
      dispatch_geojson_event(geojson)
    end

    it "shows the relevant content for searching by polygon" do
      expect(page).to have_content("Select neighbours using the map")

      page.find(:xpath, "//*[@id='main-content']/div[2]/div/details[1]/summary/span").click
      expect(page).to have_content("Selected addresses will appear in a list in the next step. You can check the list before sending letters.")
      expect(page).to have_content("Click and drag your cursor to draw a line around all the neighbours you want to select. Draw around a whole property to select it.")
      expect(page).to have_content("If you want to change your selection, use the reset button to start again.")

      map = find("my-map")
      expect(JSON.parse(map["geojsondata"])).to match(planning_application.boundary_geojson)

      within("#map-legend") do
        expect(page).to have_content("Red line boundary")
        expect(page).to have_content("Area of selected neighbours")
      end

      within("#address-container") do
        expect(page).to have_content("Your search has returned 2 results.")
      end
    end

    context "when search includes the uprn of the site address" do
      let(:uprn) { "200003357029" }

      it "excludes this address from the returned address list" do
        within("#address-container") do
          expect(page).to have_content(
            "Your search has returned 1 results. The site address is not included in these results."
          )

          within(".address-entry#neighbour-addresses-0") do
            expect(page).to have_content("6, COXSON WAY, LONDON, SE1 2XB")
            expect(page).to have_selector('a.govuk-link[data-address-entry-div-id="neighbour-addresses-0"]', text: "Remove")
          end

          expect(page).not_to have_content("5, COXSON WAY, LONDON, SE1 2XB")
        end
      end
    end

    context "when search returns more than 100 addresses" do
      before do
        allow_any_instance_of(Apis::OsPlaces::PolygonSearchService).to receive(:call).and_return({total_results: 1001, addresses: []})
      end

      it "shows that the max total results returned for a search is 1000" do
        within("#address-container") do
          expect(page).to have_content(
            "Your search has returned 1001 results. The site address is not included in these results. The first 1000 results are shown below. Check your search area or contact support at bops-team@unboxed.co if you need to see more than 1000 results."
          )
          expect(page).to have_link("bops-team@unboxed.co", href: "mailto:bops-team@unboxed.co")
        end
      end
    end

    it "I can add the neighbour addresses that are returned" do
      within("#address-container") do
        within(".address-entry#neighbour-addresses-0") do
          expect(page).to have_content("5, COXSON WAY, LONDON, SE1 2XB")
          expect(page).to have_selector('a.govuk-link[data-address-entry-div-id="neighbour-addresses-0"]', text: "Remove")
        end
        within(".address-entry#neighbour-addresses-1") do
          expect(page).to have_content("6, COXSON WAY, LONDON, SE1 2XB")
          expect(page).to have_selector('a.govuk-link[data-address-entry-div-id="neighbour-addresses-1"]', text: "Remove")
        end
      end

      # Nothing is persisted to the database at this point
      expect(Neighbour.all.length).to eq(0)

      click_button "Continue to sending letters"

      expect(page).to have_content("Addresses have been successfully added.")

      within("#selected-neighbours-list") do
        expect(page).to have_content("5, COXSON WAY, LONDON, SE1 2XB")
        expect(page).to have_content("6, COXSON WAY, LONDON, SE1 2XB")
      end
    end

    it "I can remove an address before adding the relevant neighbour addresses" do
      within("#neighbour-addresses-0") do
        expect(page).to have_content("5, COXSON WAY, LONDON, SE1 2XB")
      end

      within("#neighbour-addresses-1") do
        expect(page).to have_content("6, COXSON WAY, LONDON, SE1 2XB")
        click_link "Remove"
      end

      expect(page).not_to have_css("#address-1")
      expect(page).not_to have_content("6, COXSON WAY, LONDON, SE1 2XB")

      click_button "Continue to sending letters"

      within("#selected-neighbours-list") do
        expect(page).to have_content("5, COXSON WAY, LONDON, SE1 2XB")
      end

      expect(Consultation.last.neighbours.pluck(:address)).to eq(["5, COXSON WAY, LONDON, SE1 2XB"])

      click_button "Confirm and send letters"
    end

    it "I can view the previously drawn area" do
      click_button "Continue to sending letters"
      click_link "Consultation"
      click_link "Select and add neighbours"

      map = find("my-map")
      geojson = JSON.parse(map["geojsondata"])

      expect(geojson["features"][0]).to eq(
        {
          "type" => "Feature",
          "geometry" => {
            "type" => "Polygon",
            "coordinates" =>
              [
                [
                  [-0.07837477827741827, 51.49960885888714],
                  [-0.0783663401899492, 51.49932756979237],
                  [-0.07795182562987539, 51.49943999679809],
                  [-0.07803420855642619, 51.49966559098456],
                  [-0.07837477827741827, 51.49960885888714]
                ]
              ]
          },
          "properties" => {
            "color" => "#d870fc"
          }
        }
      )

      expect(geojson["features"][1]).to eq(
        {
          "type" => "Feature",
          "properties" => {},
          "geometry" => {
            "type" => "Polygon",
            "coordinates" =>
              [
                [
                  [-0.054597, 51.537331],
                  [-0.054588, 51.537287],
                  [-0.054453, 51.537313],
                  [-0.054597, 51.537331]
                ]
              ]
          }
        }
      )
    end

    it "I can reset a drawn area" do
      within("#neighbour-addresses-0") do
        expect(page).to have_content("5, COXSON WAY, LONDON, SE1 2XB")
      end
      within("#neighbour-addresses-1") do
        expect(page).to have_content("6, COXSON WAY, LONDON, SE1 2XB")
      end

      reset_map

      expect(page).not_to have_css("#neighbour-addresses-0")
      expect(page).not_to have_content("5, COXSON WAY, LONDON, SE1 2XB")
      expect(page).not_to have_css("#neighbour-addresses-1")
      expect(page).not_to have_content("6, COXSON WAY, LONDON, SE1 2XB")
    end

    it "I cannot add a neighbour address if it already exists" do
      create(:neighbour, consultation:, address: "5, COXSON WAY, LONDON, SE1 2XB")
      # Draw polygon for same addresses
      mock_csrf_token
      dispatch_geojson_event(geojson)

      within("#neighbour-addresses-0") do
        expect(page).to have_content("5, COXSON WAY, LONDON, SE1 2XB")
      end
      within("#neighbour-addresses-1") do
        expect(page).to have_content("6, COXSON WAY, LONDON, SE1 2XB")
      end

      click_button "Continue to sending letters"

      within(".govuk-error-summary") do
        expect(page).to have_content(
          "5, COXSON WAY, LONDON, SE1 2XB has already been added."
        )
      end
    end

    context "when redrawing the polygon" do
      before do
        stub_os_places_api_request_for_polygon(redrawn_geojson["EPSG:27700"][:features][0], "redrawn_polygon_search")
      end

      let(:redrawn_geojson) do
        {
          "EPSG:3857" => {
            type: "FeatureCollection",
            features: [
              {
                type: "Feature",
                geometry: {
                  type: "Polygon",
                  coordinates: [
                    [
                      [-0.08018430103465587, 51.497070661375886],
                      [-0.08025903628948244, 51.49700191751015],
                      [-0.08022688540367927, 51.49689298114299],
                      [-0.08004421293717312, 51.49685137544674],
                      [-0.07992821506988153, 51.496941695353854],
                      [-0.07996192953503174, 51.49705721720349],
                      [-0.08009447338556726, 51.49706107297908],
                      [-0.08018430103465587, 51.497070661375886]
                    ]
                  ]
                }
              }
            ]
          },
          "EPSG:27700" => {
            type: "FeatureCollection",
            features: [
              {
                type: "Feature",
                geometry: {
                  type: "Polygon",
                  coordinates: [
                    [
                      [533_378.6137480768, 179_308.4693687631],
                      [533_379.2170422648, 179_306.59981187445],
                      [533_373.4315282275, 179_297.8483378425],
                      [533_367.6318595328, 179_299.8685499648],
                      [533_358.2525280855, 179_307.0164626359],
                      [533_363.4518187683, 179_316.33355877135],
                      [533_373.4518187683, 179_310.43355877135],
                      [533_378.6137480768, 179_308.4693687631]
                    ]
                  ]
                },
                properties: nil
              }
            ]
          }
        }
      end

      it "I can redraw the polygon to return different addresses" do
        within("#neighbour-addresses-0") do
          expect(page).to have_content("5, COXSON WAY, LONDON, SE1 2XB")
        end
        within("#neighbour-addresses-1") do
          expect(page).to have_content("6, COXSON WAY, LONDON, SE1 2XB")
        end

        # Update drawn polygon
        dispatch_geojson_event(redrawn_geojson)

        expect(page).not_to have_content("5, COXSON WAY, LONDON, SE1 2XB")
        expect(page).not_to have_content("6, COXSON WAY, LONDON, SE1 2XB")

        within("#neighbour-addresses-0") do
          expect(page).to have_content("82, GRANGE WALK, LONDON, SE1 3DT")
        end
        within("#neighbour-addresses-1") do
          expect(page).to have_content("83, GRANGE WALK, LONDON, SE1 3DT")
        end
        within("#neighbour-addresses-2") do
          expect(page).to have_content("84, GRANGE WALK, LONDON, SE1 3DT")
        end
        within("#neighbour-addresses-3") do
          expect(page).to have_content("85, GRANGE WALK, LONDON, SE1 3DT")
        end

        click_button "Continue to sending letters"

        within("#selected-neighbours-list") do
          expect(page).to have_content("82, GRANGE WALK, LONDON, SE1 3DT")
          expect(page).to have_content("83, GRANGE WALK, LONDON, SE1 3DT")
          expect(page).to have_content("84, GRANGE WALK, LONDON, SE1 3DT")
          expect(page).to have_content("85, GRANGE WALK, LONDON, SE1 3DT")
        end

        expect(Consultation.last.neighbours.pluck(:address)).to eq(
          [
            "82, GRANGE WALK, LONDON, SE1 3DT",
            "83, GRANGE WALK, LONDON, SE1 3DT",
            "84, GRANGE WALK, LONDON, SE1 3DT",
            "85, GRANGE WALK, LONDON, SE1 3DT"
          ]
        )
      end
    end

    it "I can add addresses manually after using the polygon" do
      within("#address-container") do
        within(".address-entry#neighbour-addresses-0") do
          expect(page).to have_content("5, COXSON WAY, LONDON, SE1 2XB")
          expect(page).to have_selector('a.govuk-link[data-address-entry-div-id="neighbour-addresses-0"]', text: "Remove")
        end
        within(".address-entry#neighbour-addresses-1") do
          expect(page).to have_content("6, COXSON WAY, LONDON, SE1 2XB")
          expect(page).to have_selector('a.govuk-link[data-address-entry-div-id="neighbour-addresses-1"]', text: "Remove")
        end
      end

      # Rspec doesn't like the govuk design extra details link, so this is clicking "Manually add addresses"
      page.find(:xpath, "//*[@id='main-content']/div[2]/div/details[2]/summary/span").click

      allow_any_instance_of(Apis::OsPlaces::Query).to receive(:find_addresses).with("60-").and_return(instance_double(Faraday::Response, status: 200, body: {header: {}, results: [{DPA: {ADDRESS: "60-62, Commercial Street, E16LT"}}]}))
      fill_in "Search neighbours by address", with: "60-"
      # # Something weird is happening with the javascript, so having to double click for it to register
      # # This doesn't happen in "real life"
      page.find(:xpath, "//li[text()='60-62, Commercial Street, E16LT']").click

      within("#manual-address-container") do
        expect(page).to have_content("60-62, Commercial Street, E16LT")
      end

      click_button "Continue to sending letters"

      expect(page).to have_content("Addresses have been successfully added.")
      expect(page).to have_content "60-62, Commercial Street, E16LT"
      expect(page).to have_content "5, COXSON WAY, LONDON, SE1 2XB"
      expect(page).to have_content "6, COXSON WAY, LONDON, SE1 2XB"
    end

    it "I can add addresses with the polygon after adding manually" do
      click_link "Consultation"
      click_link "Select and add neighbours"
      # Rspec doesn't like the govuk design extra details link, so this is clicking "Manually add addresses"
      page.find(:xpath, "//*[@id='main-content']/div[2]/div/details[2]/summary/span").click

      allow_any_instance_of(Apis::OsPlaces::Query).to receive(:find_addresses).with("60-").and_return(instance_double(Faraday::Response, status: 200, body: {header: {}, results: [{DPA: {ADDRESS: "60-62, Commercial Street, E16LT"}}]}))

      fill_in "Search neighbours by address", with: "60-"
      # # Something weird is happening with the javascript, so having to double click for it to register
      # # This doesn't happen in "real life"
      page.find(:xpath, "//li[text()='60-62, Commercial Street, E16LT']").click

      mock_csrf_token
      # Mimic drawing the polygon on the map
      dispatch_geojson_event(geojson)

      within("#address-container") do
        within(".address-entry#neighbour-addresses-1") do
          expect(page).to have_content("5, COXSON WAY, LONDON, SE1 2XB")
          expect(page).to have_selector('a.govuk-link[data-address-entry-div-id="neighbour-addresses-1"]', text: "Remove")
        end
        within(".address-entry#neighbour-addresses-2") do
          expect(page).to have_content("6, COXSON WAY, LONDON, SE1 2XB")
          expect(page).to have_selector('a.govuk-link[data-address-entry-div-id="neighbour-addresses-2"]', text: "Remove")
        end
      end

      within("#manual-address-container") do
        expect(page).to have_content("60-62, Commercial Street, E16LT")
      end

      click_button "Continue to sending letters"

      expect(page).to have_content("Addresses have been successfully added.")
      expect(page).to have_content "60-62, Commercial Street, E16LT"
      expect(page).to have_content "5, COXSON WAY, LONDON, SE1 2XB"
      expect(page).to have_content "6, COXSON WAY, LONDON, SE1 2XB"
    end
  end

  describe "showing the status on the dashboard" do
    before do
      sign_in assessor
    end

    context "when there are no neigbhours" do
      it "shows 'not started'" do
        visit "/planning_applications/#{planning_application.id}"
        click_link "Consultees, neighbours and publicity"
        expect(page).to have_content "Select and add neighbours Not started"
      end
    end

    context "when there are some neighbours" do
      before do
        create(:neighbour, consultation:)
      end

      it "shows 'completed'" do
        visit "/planning_applications/#{planning_application.id}"
        click_link "Consultees, neighbours and publicity"
        expect(page).to have_content "Select and add neighbours Completed"
      end
    end
  end
end
