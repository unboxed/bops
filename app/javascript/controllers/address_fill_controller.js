import { Controller } from "@hotwired/stimulus"
import { ajax } from "@rails/ujs"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  connect() {
    accessibleAutocomplete({
      element: document.querySelector("#address-autocomplete-container"),
      id: "address-autocomplete", // To match it to the existing <label>.
      source: (query, populateResults) => {
        const results = []
        ajax({
          type: "get",
          url: `${document.querySelector("#os_path").value}?query=${query}`,
          success: (data) => {
            for (const i of data.results) {
              results.push(i.DPA.ADDRESS)
            }
            populateResults(results)
          },
        })
      },
      minLength: 3,
    })
  }
}
