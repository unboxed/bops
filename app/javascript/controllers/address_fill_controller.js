import { Controller } from "@hotwired/stimulus"
import accessibleAutocomplete from "accessible-autocomplete"
import { ajax } from "@rails/ujs"

export default class extends Controller {
  connect() {
    accessibleAutocomplete({
      element: document.querySelector("#address-autocomplete-container"),
      id: "address-autocomplete", // To match it to the existing <label>.
      source: (query, populateResults) => {
        let results = []
        ajax({
          type: "get",
          url: `${document.querySelector("#os_path").value}?query=${query}`,
          success: (data) => {
            for (var i of JSON.parse(data).results) {
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
