import { Controller } from "@hotwired/stimulus"
import { ajax } from "@rails/ujs"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  static targets = [
    "policyAreaSelect",
    "policyReferences",
    "policyReferencesInput",
    "policyReferencesContainer",
    "policyReferenceTemplate",
    "policyGuidance",
    "policyGuidanceInput",
    "policyGuidanceContainer",
    "policyGuidanceTemplate",
  ]

  connect() {
    if (this.hasPolicyAreaSelectTarget) {
      accessibleAutocomplete.enhanceSelectElement({
        confirmOnBlur: true,
        defaultValue: "",
        displayMenu: "overlay",
        preserveNullOptions: true,
        selectElement: this.policyAreaSelectTarget,
        showAllValues: true,
      })
    }

    if (this.hasPolicyReferencesContainerTarget) {
      accessibleAutocomplete({
        element: this.policyReferencesContainerTarget,
        id: "policyReferencesAutoComplete",
        name: "policyReference",
        defaultValue: "",
        displayMenu: "overlay",
        showNoOptionsFound: false,
        minLength: 1,
        confirmOnBlur: false,
        source: (query, populateResults) => {
          this.findPolicyReference(query, populateResults)
        },
        templates: {
          inputValue: (value) => {
            return value?.description
              ? `${value.code} - ${value.description}`
              : ""
          },
          suggestion: (value) => {
            return value?.description
              ? `${value.code} - ${value.description}`
              : ""
          },
        },
        onConfirm: (value) => {
          this.appendPolicyReference(value)

          setTimeout(() => {
            this.policyReferencesAutoComplete.value = ""
          }, 50)
        },
      })

      this.policyReferencesInputTarget.remove()
      this.policyReferencesLabel.htmlFor = "policyReferencesAutoComplete"
    }

    if (this.hasPolicyGuidanceContainerTarget) {
      accessibleAutocomplete({
        element: this.policyGuidanceContainerTarget,
        id: "policyGuidanceAutoComplete",
        name: "policyGuidance",
        defaultValue: "",
        displayMenu: "overlay",
        showNoOptionsFound: false,
        minLength: 1,
        confirmOnBlur: false,
        source: (query, populateResults) => {
          this.findPolicyGuidance(query, populateResults)
        },
        templates: {
          inputValue: (value) => {
            return value?.description ? value.description : ""
          },
          suggestion: (value) => {
            return value?.description ? value.description : ""
          },
        },
        onConfirm: (value) => {
          this.appendPolicyGuidance(value)

          setTimeout(() => {
            this.policyGuidanceAutoComplete.value = ""
          }, 50)
        },
      })

      this.policyGuidanceInputTarget.remove()
      this.policyGuidanceLabel.htmlFor = "policyGuidanceAutoComplete"
    }
  }

  policyReferenceIsAlreadyAdded(data) {
    return !!this.policyReferencesTarget.querySelector(
      `input[value="${data.description}"]`,
    )
  }

  appendPolicyReference(data) {
    if (this.policyReferenceIsAlreadyAdded(data)) {
      alert(
        "This policy reference has already been added to this consideration",
      )
    } else {
      this.policyReferencesTarget.appendChild(this.buildPolicyReference(data))
    }
  }

  buildPolicyReference(data) {
    const policyReference =
      this.policyReferenceTemplateTarget.content.cloneNode(true)

    const count = this.policyReferencesTarget.querySelectorAll("li").length
    const fieldBase = `consideration[policy_references_attributes][${count}]`

    const codeInput = policyReference.querySelector("input[name=code]")
    codeInput.name = `${fieldBase}[code]`
    codeInput.value = data.code

    const descriptionInput = policyReference.querySelector(
      "input[name=description]",
    )

    descriptionInput.name = `${fieldBase}[description]`
    descriptionInput.value = data.description

    const urlInput = policyReference.querySelector("input[name=url]")
    urlInput.name = `${fieldBase}[url]`
    urlInput.value = data.url

    const spanElement = policyReference.querySelector("span")
    spanElement.textContent = `${data.code} - ${data.description}`

    return policyReference
  }

  removePolicyReference(event) {
    event.target.parentElement.remove()
  }

  policyGuidanceIsAlreadyAdded(data) {
    return !!this.policyGuidanceTarget.querySelector(
      `input[value="${data.description}"]`,
    )
  }

  appendPolicyGuidance(data) {
    if (this.policyGuidanceIsAlreadyAdded(data)) {
      alert("This policy guidance has already been added to this consideration")
    } else {
      this.policyGuidanceTarget.appendChild(this.buildPolicyGuidance(data))
    }
  }

  buildPolicyGuidance(data) {
    const policyGuidance =
      this.policyGuidanceTemplateTarget.content.cloneNode(true)

    const count = this.policyGuidanceTarget.querySelectorAll("li").length
    const fieldBase = `consideration[policy_guidance_attributes][${count}]`

    const descriptionInput = policyGuidance.querySelector(
      "input[name=description]",
    )

    descriptionInput.name = `${fieldBase}[description]`
    descriptionInput.value = data.description

    const urlInput = policyGuidance.querySelector("input[name=url]")
    urlInput.name = `${fieldBase}[url]`
    urlInput.value = data.url

    const spanElement = policyGuidance.querySelector("span")
    spanElement.textContent = data.description

    return policyGuidance
  }

  removePolicyGuidance(event) {
    event.target.parentElement.remove()
  }

  findPolicyReference(query, populateResults) {
    return this.search("/policy/references", query, populateResults)
  }

  findPolicyGuidance(query, populateResults) {
    return this.search("/policy/guidance", query, populateResults)
  }

  search(url, query, populateResults) {
    ajax({
      type: "GET",
      url: url,
      data: new URLSearchParams({ q: query }).toString(),
      success: (data) => {
        populateResults(data)
      },
      failure: (event) => {
        populateResults([])
      },
    })
  }

  get policyReferencesAutoComplete() {
    return document.getElementById("policyReferencesAutoComplete")
  }

  get policyReferencesLabel() {
    return this.policyReferencesContainerTarget.firstChild
  }

  get policyGuidanceAutoComplete() {
    return document.getElementById("policyGuidanceAutoComplete")
  }

  get policyGuidanceLabel() {
    return this.policyGuidanceContainerTarget.firstChild
  }
}
