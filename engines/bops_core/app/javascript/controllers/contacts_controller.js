import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  static targets = ["container", "input"]

  connect() {
    this.selected = null

    if (this.hasContainerTarget) {
      accessibleAutocomplete({
        element: this.containerTarget,
        id: "add-consultee",
        name: null,
        source: (query, populateResults) => {
          this.source(query, populateResults)
        },
        displayMenu: "overlay",
        minLength: 3,
        onConfirm: (selected) => {
          this.onConfirm(selected)
        },
        autoselect: false,
        confirmOnBlur: false,
        templates: {
          inputValue: (value) => {
            return this.inputValue(value)
          },
          suggestion: (value) => {
            return this.suggestion(value)
          },
        },
      })

      this.autocompleteInput.addEventListener("keydown", (event) => {
        if (event.keyCode === 13) {
          event.preventDefault()
        }
      })
    }
  }

  source(query, populateResults) {
    Rails.ajax({
      type: "GET",
      url: "/contacts/consultees",
      data: new URLSearchParams({ q: query }).toString(),
      success: (data) => {
        populateResults(data)
      },
      failure: () => {
        populateResults([])
      },
    })
  }

  inputValue(value) {
    return !value ? "" : value.name
  }

  suggestion(value) {
    if (value.role && value.organisation) {
      return `<b>${value.name}</b> (${value.role}, ${value.organisation})`
    } else if (value.role) {
      return `<b>${value.name}</b> (${value.role})`
    } else if (value.organisation) {
      return `<b>${value.name}</b> (${value.organisation})`
    } else {
      return `<b>${value.name}</b>`
    }
  }

  onConfirm(selected) {
    this.selected = selected
    this.inputTarget.value = selected.id
  }

  get autocompleteInput() {
    return this.element.querySelector("#add-consultee")
  }
}
