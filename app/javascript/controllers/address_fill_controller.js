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
        this.appendAddress(val)
      },
    })
  }

  getAddressContainer() {
    return document.getElementById("manual-address-container")
  }

  getConsultationNeighbourAddressesForm() {
    return document.getElementById("consultation-neighbour-addresses-form")
  }

  appendAddress(address) {
    const container = this.getAddressContainer()

    const addressCount = document.getElementById("address-container")

    const count = addressCount === null ? 0 : addressCount.children.length
    const addressDiv = this.createAddressElement(address, count)
    const hiddenInput = this.createHiddenInputElement(address, count)

    this.getConsultationNeighbourAddressesForm().appendChild(hiddenInput)

    container.appendChild(addressDiv)

    const submitButton = document.getElementById("submit-button")

    if (submitButton === null) {
      const btn = this.createAddNeighboursButton()
      const submitButtonDiv = document.querySelector(".submit-buttons")
      const backButton = document.querySelector(".back-button")

      submitButtonDiv.insertBefore(btn, backButton)
    }
  }

  createHiddenInputElement(address, index) {
    const hiddenInput = document.createElement("input")
    hiddenInput.type = "hidden"
    hiddenInput.name = this.data.get("name")
    hiddenInput.value = address

    const hiddenInputAddressId = `hidden-${this.data.get("id")}-${index}`
    hiddenInput.id = hiddenInputAddressId

    return hiddenInput
  }

  createAddressElement(address, index) {
    const addressEntryDiv = document.createElement("div")
    addressEntryDiv.className = "address-entry"

    const addressId = `${this.data.get("id")}-${index}`
    addressEntryDiv.id = addressId

    // Create <hr>
    const hr = document.createElement("hr")
    addressEntryDiv.appendChild(hr)

    // Create a div for display flex
    const flexDiv = document.createElement("div")
    flexDiv.style.display = "flex"
    flexDiv.style.justifyContent = "space-between"
    addressEntryDiv.appendChild(flexDiv)

    // Create the address <p> element
    const p = document.createElement("p")
    p.classList.add("govuk-body")
    p.textContent = address
    flexDiv.appendChild(p)

    // Create the remove link
    const removeLink = this.createRemoveLink(addressId)
    flexDiv.appendChild(removeLink)

    return addressEntryDiv
  }

  createRemoveLink(addressId) {
    const link = document.createElement("a")
    link.textContent = "Remove"
    link.href = "#"
    link.className = "govuk-link"

    link.dataset.addressEntryDivId = addressId
    link.addEventListener("click", (event) => {
      event.preventDefault()

      const targetId = event.target.dataset.addressEntryDivId
      const addressDiv = document.getElementById(targetId)
      const hiddenInputId = `hidden-${targetId}`
      const hiddenInput = document.getElementById(hiddenInputId)

      addressDiv.remove()
      hiddenInput.remove()
    })
    return link
  }

  createAddNeighboursButton() {
    const input = document.createElement("input")

    input.type = "submit"
    input.name = "commit"
    input.value = "Continue to sending letters"
    input.id = "submit-button"
    input.setAttribute("data-disable-with", "Continue to sending letters")
    input.setAttribute("form", "consultation-neighbour-addresses-form")
    input.classList.add("govuk-button", "govuk-!-margin-right-2")
    return input
  }
}
