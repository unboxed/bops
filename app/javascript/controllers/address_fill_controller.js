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

  getHiddenAddressesField() {
    return document.getElementById("manual-addresses-hidden")
  }

  appendAddress(address) {
    const container = this.getAddressContainer()

    const count = this.countExistingAddressElements()

    const addressDiv = this.createAddressElement(address, count)
    const addressHiddenInput = this.createHiddenInputElement(
      "address",
      address,
      count,
    )
    const sourceHiddenInput = this.createHiddenInputElement(
      "source",
      "manual",
      count,
    )

    this.getHiddenAddressesField().appendChild(addressHiddenInput)
    this.getHiddenAddressesField().appendChild(sourceHiddenInput)

    container.appendChild(addressDiv)

    const submitButton = document.getElementById("submit-button")

    if (submitButton === null) {
      const btn = this.createAddNeighboursButton()
      const submitButtonDiv = document.querySelector(".submit-buttons")
      const backButton = document.querySelector(".back-button")

      submitButtonDiv.insertBefore(btn, backButton)
    }
  }

  countExistingAddressElements() {
    const addressCount = document.querySelector(".address-entry")
    const manualAddressCount = document.querySelector(".manual-address-entry")

    const polygonCount =
      addressCount === null
        ? 0
        : document.getElementById("address-container").children.length
    const manualCount =
      manualAddressCount === null
        ? 0
        : document.getElementById("manual-address-container").children.length

    return polygonCount + manualCount
  }

  createHiddenInputElement(name, value, index) {
    const hiddenInput = document.createElement("input")
    hiddenInput.type = "hidden"
    hiddenInput.name = `consultation[neighbours_attributes][][${name}]`
    hiddenInput.value = value

    const hiddenInputId = `hidden-neighbour-${name}-${index}`
    hiddenInput.id = hiddenInputId

    return hiddenInput
  }

  createAddressElement(address, index) {
    const addressEntryDiv = document.createElement("div")
    addressEntryDiv.className = "manual-address-entry"

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
      const hiddenSourceId = hiddenInputId.replace("address", "source")
      const hiddenSourceInput = document.getElementById(hiddenSourceId)
      addressDiv.remove()
      hiddenInput.remove()
      hiddenSourceInput.remove()
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
