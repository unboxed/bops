import { Controller } from "@hotwired/stimulus"
import { ajax } from "@rails/ujs"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  static targets = [
    "form",
    "accordian",
    "externalConsultees",
    "externalCount",
    "internalConsultees",
    "internalCount",
    "noConsultees",
    "container",
    "addConsultee",
    "template",
    "submit",
  ]

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

    // Prevent the enter key from submitting the form
    this.formTarget.addEventListener("keypress", (event) => {
      if (
        event.keyCode === 13 &&
        event.srcElement.id !== "send-emails-button"
      ) {
        event.preventDefault()
      }
    })

    // Confirm that the user wants to send the emails
    this.submitTarget.addEventListener("click", (event) => {
      if (!confirm(this.confirmationMessage)) {
        event.preventDefault()
        this.submitTarget.blur()
      }
    })
  }

  handleKeyDown(event) {
    if (event.keyCode === 13) {
      event.stopPropagation()

      this.autocompleteInput.blur()

      setTimeout(() => {
        this.addConsulteeTarget.focus()
      }, 50)
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

    for (const checkbox of this.externalConsulteeCheckboxes) {
      checkbox.checked = checked
    }
  }

  toggleInternalConsultees(event) {
    const checked = event.srcElement.checked

    for (const checkbox of this.internalConsulteeCheckboxes) {
      checkbox.checked = checked
    }
  }

  addConsulteeClick(event) {
    this.addConsultee()
  }

  addConsulteeKeyDown(event) {
    if (event.keyCode === 13) {
      event.stopPropagation()
      this.addConsultee()
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
          this.appendConsultee(data)
          this.resetAutocomplete()
        },
        error: () => {
          alert(this.errorMessage)
        },
      })
    } else {
      alert(this.promptMessage)
    }
  }

  appendConsultee(data) {
    const consultee = this.buildConsultee(data)

    const consulteesTarget =
      data.origin === "external"
        ? this.externalConsulteesTarget
        : this.internalConsulteesTarget

    const countTarget =
      data.origin === "external"
        ? this.externalCountTarget
        : this.internalCountTarget

    const tableBody = consulteesTarget.querySelector("tbody")
    tableBody.appendChild(consultee)

    const newCount = tableBody.querySelectorAll("tr").length
    countTarget.textContent = newCount

    this.noConsulteesTarget.style.display = "none"
    this.accordianTarget.style.display = ""
    consulteesTarget.style.display = ""
  }

  buildConsultee(data) {
    const consultee = this.templateTarget.content.cloneNode(true)

    const idInput = consultee.querySelector(
      "td:first-child input[type=hidden]:first-child",
    )

    const hiddenInput = consultee.querySelector(
      ".govuk-checkboxes__item input[type=hidden]",
    )

    const checkboxInput = consultee.querySelector(
      ".govuk-checkboxes__item input[type=checkbox]",
    )

    const inputLabel = consultee.querySelector(".govuk-checkboxes__item label")
    const nameCell = consultee.querySelector("td:nth-child(2)")
    const fieldName = `consultation[consultees_attributes][${data.id}][selected]`
    const domId = `consultation_consultees_attributes_${data.id}_selected`

    consultee.id = `consultee_${data.id}`
    idInput.id = `consultation_consultees_attributes_${data.id}_id`
    idInput.name = `consultation[consultees_attributes][${data.id}][id]`
    idInput.value = data.id
    hiddenInput.name = fieldName
    checkboxInput.name = fieldName
    checkboxInput.id = domId
    inputLabel.htmlFor = domId
    nameCell.textContent = data.name

    return consultee
  }

  resetAutocomplete() {
    this.selected = null
    this.autocompleteInput.value = ""
    this.autocompleteInput.scrollIntoView(true)

    setTimeout(() => {
      this.autocompleteInput.focus()
    }, 50)
  }

  onConfirm(selected) {
    this.selected = selected

    setTimeout(() => {
      this.addConsulteeTarget.focus()
    }, 50)
  }

  get planningApplicationId() {
    return this.data.get("planning-application-id")
  }

  get confirmationMessage() {
    return this.data.get("confirmation-message")
  }

  get errorMessage() {
    return this.data.get("error-message")
  }

  get promptMessage() {
    return this.data.get("prompt-message")
  }

  get externalConsulteeCheckboxes() {
    return this.externalConsulteesTarget.querySelectorAll(
      "input[type=checkbox]",
    )
  }

  get internalConsulteeCheckboxes() {
    return this.internalConsulteesTarget.querySelectorAll(
      "input[type=checkbox]",
    )
  }

  get autocompleteInput() {
    return this.element.querySelector("#add-consultee")
  }

  get autocompleteList() {
    return this.element.querySelector("#add-consultee__listbox")
  }
}
