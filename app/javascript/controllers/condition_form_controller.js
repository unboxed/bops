import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  static targets = ["container", "titleInput", "textInput", "reasonInput"]

  connect() {
    const inputId = this.titleInputTarget.id
    const inputName = this.titleInputTarget.name
    const inputValue = this.titleInputTarget.value

    accessibleAutocomplete({
      element: this.containerTarget,
      id: inputId,
      name: inputName,
      defaultValue: inputValue,
      displayMenu: "overlay",
      showNoOptionsFound: false,
      minLength: 3,
      confirmOnBlur: false,
      source: (query, populateResults) => {
        this.source(query, populateResults)
      },
      templates: {
        inputValue: (value) => {
          return value?.title ? value.title : ""
        },
        suggestion: (value) => {
          return value?.title ? value.title : ""
        },
      },
      onConfirm: (value) => {
        this.textInputTarget.value = value?.text ? value.text : ""
        this.reasonInputTarget.value = value?.reason ? value.reason : ""
      },
    })

    this.titleInputTarget.remove()
  }

  source(query, populateResults) {
    Rails.ajax({
      type: "GET",
      url: "/conditions",
      data: new URLSearchParams({ q: query }).toString(),
      success: (data) => {
        populateResults(data)
      },
      failure: (_event) => {
        populateResults([])
      },
    })
  }
}
