import { Controller } from "@hotwired/stimulus"
import { ajax } from "@rails/ujs"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  connect() {
    accessibleAutocomplete({
      element: document.querySelector(`#${this.data.get("id")}-container`),
      id: this.data.get("id"),
      name: this.data.get("name"),
      source: (query, populateResults) => {
        const results = []
        ajax({
          type: "get",
          url: `${this.data.get("url")}?query=${query}`,
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
