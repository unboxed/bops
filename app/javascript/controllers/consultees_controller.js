import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  static targets = [
    "form",
    "accordion",
    "allConsultees",
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

    // Confirm that the user wants to send the emails
    if (this.hasSubmitTarget) {
      this.formTarget.addEventListener("submit", (event) => {
        if (!confirm(this.confirmationMessage)) {
          event.preventDefault()

          setTimeout(() => {
            this.submitTarget.disabled = false
            this.submitTarget.blur()
          }, 50)
        }
      })
    }

    this.autocompleteInput.addEventListener("keydown", (event) => {
      if (event.keyCode === 13) {
        event.preventDefault()

        if (this.selected) {
          this.addConsultee()
        }
      }
    })
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

  toggleConsultees(event) {
    const checked = event.srcElement.checked

    for (const checkbox of this.consulteeCheckboxes) {
      checkbox.checked = checked
    }
  }

  addConsulteeClick(_event) {
    this.addConsultee()
  }

  addConsultee() {
    if (this.selected) {
      const params = new URLSearchParams()

      params.append("consultee[origin]", this.selected.origin)
      params.append("consultee[name]", this.selected.name)
      params.append("consultee[email_address]", this.selected.email_address)

      if (this.selected.role) {
        params.append("consultee[role]", this.selected.role)
      }

      if (this.selected.organisation) {
        params.append("consultee[organisation]", this.selected.organisation)
      }

      Rails.ajax({
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

    const tableBody = this.allConsulteesTarget.querySelector("tbody")
    tableBody.appendChild(consultee)

    if (this.hasNoConsulteesTarget) {
      this.noConsulteesTarget.style.display = "none"
    }

    if (this.hasAccordionTarget) {
      this.accordionTarget.style.display = ""
    }

    this.allConsulteesTarget.style.display = ""
  }

  buildConsultee(data) {
    const consultee = this.templateTarget.content.cloneNode(true)
    const consulteeRow = consultee.querySelector("tr")
    consulteeRow.classList.add(`${data.origin}-consultee`)

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
    const nameCell = consultee.querySelector(".consultee-name")
    const originCell = consultee.querySelector(".consultee-origin")
    const fieldName = `consultation[consultees_attributes][${data.id}][selected]`
    const domId = `consultation_consultees_attributes_${data.id}_selected`

    consultee.id = `consultee_${data.id}`

    if (idInput !== null) {
      idInput.id = `consultation_consultees_attributes_${data.id}_id`
      idInput.name = `consultation[consultees_attributes][${data.id}][id]`
      idInput.value = data.id
    }

    if (hiddenInput !== null) {
      hiddenInput.name = fieldName
    }

    if (checkboxInput !== null) {
      checkboxInput.name = fieldName
      checkboxInput.id = domId
    }

    if (inputLabel !== null) {
      inputLabel.htmlFor = domId
    }

    const consulteeWrapper = document.createElement("div")

    if (data.role || data.organisation) {
      const suffix = [data.role, data.organisation].filter((v) => v).join(", ")
      const suffixWrapper = document.createElement("span")
      suffixWrapper.classList.add("govuk-!-font-size-16")
      suffixWrapper.textContent = suffix

      consulteeWrapper.append(
        data.name,
        document.createElement("br"),
        suffixWrapper,
      )
    } else {
      consulteeWrapper.textContent = data.name
    }

    nameCell.appendChild(consulteeWrapper)

    if (originCell !== null) {
      originCell.textContent = data.origin
    }

    return consultee
  }

  resetAutocomplete() {
    this.selected = null
    this.autocompleteInput.value = ""
  }

  onConfirm(selected) {
    this.selected = selected
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

  get consulteeCheckboxes() {
    return this.allConsulteesTarget.querySelectorAll("input[type=checkbox]")
  }

  get autocompleteInput() {
    return this.element.querySelector("#add-consultee")
  }

  get autocompleteList() {
    return this.element.querySelector("#add-consultee__listbox")
  }
}
