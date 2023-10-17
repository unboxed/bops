import { Controller } from "@hotwired/stimulus"
import { ajax } from "@rails/ujs"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  static targets = ["consultees", "container", "form", "submit", "addConsultee"]

  connect() {
    this.selected = null

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
      autoselect: true,
      confirmOnBlur: true,
      templates: {
        inputValue: (value) => {
          return this.inputValue(value)
        },
        suggestion: (value) => {
          return this.suggestion(value)
        },
      },
    })

    // Prevent the enter key from submitting the form
    this.formTarget.addEventListener("keypress", (event) => {
      if (event.keyCode === 13) {
        event.preventDefault()
      }
    })

    // Confirm that the user wants to send the emails
    this.submitTarget.addEventListener("click", (event) => {
      if (!confirm("Send emails to consultees?")) {
        event.preventDefault()
        this.submitTarget.blur()
      }
    })

    // Add the consultee if the user hits return on the button
    this.addConsulteeTarget.addEventListener("keypress", (event) => {
      if (event.keyCode === 13) {
        this.addConsultee()
      }
    })

    this.autocompleteInput.addEventListener("keydown", (event) => {
      this.handleKeyDown(event)
    })

    this.autocompleteList.addEventListener("keydown", (event) => {
      this.handleKeyDown(event)
    })
  }

  handleKeyDown(event) {
    if (event.keyCode === 13) {
      event.stopPropagation()

      this.autocompleteInput.blur()

      setTimeout(() => {
        this.addConsulteeTarget.focus()
      }, 250)
    }
  }

  source(query, populateResults) {
    const results = []

    ajax({
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

  toggleExternalConsultees(event) {
    const checked = event.srcElement.checked

    for (const checkbox of this.externalConsultees) {
      checkbox.checked = checked
    }
  }

  toggleInternalConsultees(event) {
    const checked = event.srcElement.checked

    for (const checkbox of this.internalConsultees) {
      checkbox.checked = checked
    }
  }

  addConsultee() {
    if (this.selected) {
      const params = new URLSearchParams()

      params.append("consultee[origin]", this.selected.origin)
      params.append("consultee[name]", this.selected.name)
      params.append("consultee[email_address]", this.selected.email_address)
      params.append("consultee[role]", this.selected.role)
      params.append("consultee[organisation]", this.selected.organisation)

      ajax({
        type: "POST",
        url: `/planning_applications/${this.planningApplicationId}/consultees.json`,
        data: params,
        success: (data) => {
          this.consulteesTarget.innerHTML = data.consultees
          this.selected = null
          this.autocompleteInput.value = ""

          setTimeout(() => {
            this.autocompleteInput.focus()
          }, 250)
        },
        failure: () => {
          alert("Error: Unable to add the consultee to the list")
        },
      })
    } else {
      alert("Please search for a consultee first")
    }
  }

  onConfirm(selected) {
    this.selected = selected
  }

  get planningApplicationId() {
    return this.data.get("planning-application-id")
  }

  get internalConsultees() {
    return this.element.querySelectorAll(
      "#internal-consultees td input[type=checkbox]",
    )
  }

  get externalConsultees() {
    return this.element.querySelectorAll(
      "#external-consultees td input[type=checkbox]",
    )
  }

  get autocompleteInput() {
    return this.element.querySelector("#add-consultee")
  }

  get autocompleteList() {
    return this.element.querySelector("#add-consultee__listbox")
  }
}
