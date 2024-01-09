import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.map = this.getMapElement()
    this.resetBtn = this.getResetButton()
    // Debounce the onGeojsonChange function so it's triggered at most once per second
    this.debouncedGeojsonChange = this.debounce(this.onGeojsonChange, 1000)

    this.setupEventListeners()
  }

  getMapElement() {
    return document.querySelector("my-map:first-of-type")
  }

  getResetButton() {
    return this.map.shadowRoot.querySelector('button[title="Reset map view"]')
  }

  getCSRFToken() {
    return document.querySelector("[name='csrf-token']").getAttribute("content")
  }

  getUrlPath() {
    return this.data.get("url")
  }

  getAddressContainer() {
    return document.getElementById("address-container")
  }

  getHiddenAddressesField() {
    return document.getElementById("addresses-hidden")
  }

  setupEventListeners() {
    this.map.addEventListener("geojsonChange", this.debouncedGeojsonChange)
    this.resetBtn.addEventListener("click", this.clearAddresses)
  }

  async handleGeojsonChange(geoJSON) {
    this.clearAddresses()
    this.showLoadingSpinner()

    try {
      const response = await this.fetchGeojsonData(geoJSON, this.getCSRFToken())
      const data = await response.json()

      this.appendAddressesToPage(data)
    } catch (error) {
      console.error("There was an error calling the OS Places API:", error)
    } finally {
      this.hideLoadingSpinner()
    }
  }

  async fetchGeojsonData(geoJSON, csrfToken) {
    const response = await fetch(this.getUrlPath(), {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({ geojson: geoJSON }),
    })

    if (!response.ok) {
      throw new Error(`HTTP error with status: ${response.status}`)
    }

    return response
  }

  onGeojsonChange({ detail: geoJSON }) {
    const geoJsonFeatures = geoJSON["EPSG:27700"]

    if (geoJsonFeatures === undefined) {
      return
    }

    this.handleGeojsonChange(geoJsonFeatures.features[0])
  }

  clearAddresses = () => {
    this.getAddressContainer().innerHTML = ""
    this.removeHiddenAddressInputs()
    this.removeHiddenSourceInputs()
  }

  appendAddressesToPage(addresses) {
    const container = this.getAddressContainer()

    addresses.forEach((address, index) => {
      const count = this.countExistingAddressElements()

      const addressDiv = this.createAddressElement(address, count + index)
      const addressHiddenInput = this.createHiddenInputElement(
        "address",
        address,
        count + index,
      )
      const sourceHiddenInput = this.createHiddenInputElement(
        "source",
        "map_selection",
        count + index,
      )

      this.getHiddenAddressesField().appendChild(addressHiddenInput)
      this.getHiddenAddressesField().appendChild(sourceHiddenInput)

      container.appendChild(addressDiv)
    })

    const submitButton = document.getElementById("submit-button")

    if (addresses.length > 0 && submitButton === null) {
      const btn = this.createAddNeighboursButton()
      const submitButtonDiv = document.querySelector(".submit-buttons")
      const backButton = document.querySelector(".back-button")

      submitButtonDiv.insertBefore(btn, backButton)
    }
  }

  countExistingAddressElements() {
    const manualAddressCount = document.querySelector(".manual-address-entry")

    const manualCount =
      manualAddressCount === null
        ? 0
        : document.getElementById("manual-address-container").children.length

    return manualCount
  }

  createHiddenInputElement(name, value, index) {
    const hiddenInput = document.createElement("input")
    hiddenInput.type = "hidden"
    hiddenInput.name = `consultation[neighbours_attributes][][${name}]`
    hiddenInput.value = value

    const hiddenInputId = this.getInputId(name, index)
    hiddenInput.id = hiddenInputId

    return hiddenInput
  }

  getInputId(name, index) {
    return name === "address"
      ? `hidden-neighbour-addresses-${index}`
      : `hidden-neighbour-sources-${index}`
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
      const hiddenSourceId = hiddenInputId.replace("addresses", "sources")
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

  showLoadingSpinner() {
    const spinner = document.createElement("div")
    spinner.className = "loading-spinner"
    this.getAddressContainer().prepend(spinner)
  }

  hideLoadingSpinner() {
    const spinner = document.querySelector(".loading-spinner")

    if (spinner) {
      spinner.remove()
    }
  }

  removeHiddenAddressInputs() {
    const hiddenInputs = this.getHiddenAddressesField().querySelectorAll(
      `input[type="hidden"][name="${this.data.get("name")}"]`,
    )

    hiddenInputs.forEach((input) => input.parentNode.removeChild(input))
  }

  removeHiddenSourceInputs() {
    const hiddenInputs = this.getHiddenAddressesField().querySelectorAll(
      `input[type="hidden"][name="consultation[neighbours_attributes][][source]"`,
    )

    hiddenInputs.forEach((input) => input.parentNode.removeChild(input))
  }

  debounce(func, wait) {
    let timeout
    return (...args) => {
      clearTimeout(timeout)
      timeout = setTimeout(() => func.apply(this, args), wait)
    }
  }
}
