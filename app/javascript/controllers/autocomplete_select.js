import { Controller } from "@hotwired/stimulus"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  connect() {
    accessibleAutocomplete.enhanceSelectElement({
      displayMenu: "overlay",
      selectElement: this.selectElement,
    })
  }

  get selectElement() {
    return this.element.querySelector("select")
  }
}
