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
      confirmOnBlur: false,
      onConfirm: (val) => {
        const hiddenField = document.getElementById("address-hidden-field")
        if (hiddenField) {
          hiddenField.value = val
        } else {
          this.addAddress(val)
        }
      },
    })
  }

  addAddress(address) {
    ajax({
      type: "get",
      url: `${this.data.get("url")}?query=${address}`,
      success: (data) => {
        this.populateForm(data.results[0].DPA)
      },
    })
  }

  populateForm(results) {
    const newResults = {}

    newResults.address_1 = results.ADDRESS
    newResults.postcode = results.POSTCODE
    newResults.town = results.POST_TOWN
    newResults.uprn = results.UPRN
    newResults.latitude = results.LAT
    newResults.longitude = results.LNG

    const formattedAddress = newResults.address_1
      .replace(`, ${newResults.postcode}`, "")
      .replace(`, ${newResults.town}`, "")
    newResults.address_1 = formattedAddress

    for (
      let i = 0, keys = Object.keys(newResults), ii = keys.length;
      i < ii;
      i++
    ) {
      document.getElementById(`planning_application_${keys[i]}`).value =
        newResults[keys[i]]
    }
  }
}
