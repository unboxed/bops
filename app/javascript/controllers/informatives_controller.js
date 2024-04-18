import { Controller } from "@hotwired/stimulus"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  static targets = ["informatives-container", "select", "output"]

  addInformative(event) {
    event.preventDefault()
    this.setInformativeInput()
    this.submitForm(event)
  }

  setInformativeInput() {
    const chosenInformative = document.getElementById("informatives").value
    const manualTitleInput = document.getElementById("manual-title-input").value
    const hiddenTitleField = document.getElementById("hidden-title-field")

    const manualTextInput = document.getElementById("manual-text-input").value
    const hiddenTextField = document.getElementById("hidden-text-field")

    if (chosenInformative !== "") {
      hiddenTitleField.value = chosenInformative
    } else {
      hiddenTitleField.value = manualTitleInput
      hiddenTextField.value = manualTextInput
    }
  }

  connect() {
    const titlesArray = []

    const informativesArray = this.getInformativesArray()

    for (let i = 0; i < informativesArray.length; i++) {
      titlesArray.push(informativesArray[i][0])
    }

    accessibleAutocomplete({
      element: document.querySelector("#informatives-container"),
      id: "informatives",
      source: titlesArray,
      onConfirm: (query) => {
        this.onConfirm(query)
      },
      autoselect: false,
      confirmOnBlur: false,
      showAllValues: true,
    })
  }

  onConfirm(selected) {
    this.selected = selected
    const hiddenTitleField = document.getElementById("hidden-title-field")
    hiddenTitleField.value = this.selected

    const hiddenTextField = document.getElementById("hidden-text-field")

    let text = ""

    const informativesArray = this.getInformativesArray()

    for (let i = 0; i < informativesArray.length; i++) {
      if (informativesArray[i][0] === this.selected) {
        text = informativesArray[i][1]
      }
    }

    hiddenTextField.value = text
  }

  submitForm(event) {
    if (event.srcElement.textContent.includes("Save and come back later")) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "save"
      input.value = "true"
      document.querySelector("form").appendChild(input)
    }

    document.querySelector("form").submit()
  }

  getInformativesArray() {
    const dataArrayElement = this.element.querySelector(
      "[data-informatives-array-value]",
    )
    const dataArrayJson = dataArrayElement.getAttribute(
      "data-informatives-array-value",
    )

    return JSON.parse(dataArrayJson)
  }
}
