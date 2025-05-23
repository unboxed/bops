import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  connect() {
    const inputField = this.element.querySelector("input[type=text]")
    const formGroup = inputField.parentNode
    const fieldId = inputField.id
    const fieldName = inputField.name
    const fieldValue = inputField.value
    const containerId = `${fieldId}-container`

    const container = document.createElement("div")
    container.id = containerId
    inputField.replaceWith(container)

    accessibleAutocomplete({
      element: container,
      id: fieldId,
      name: fieldName,
      minLength: 5,
      defaultValue: fieldValue,
      source: (query, populateResults) => {
        Rails.ajax({
          type: "get",
          url: `/addresses?query=${encodeURIComponent(query)}&count=5`,
          success: (data) => {
            populateResults(data)
          },
        })
      },
    })
  }
}
