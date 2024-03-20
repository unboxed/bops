import { Controller } from "@hotwired/stimulus"
import accessibleAutocomplete from "accessible-autocomplete"

export default class extends Controller {
  connect() {
    accessibleAutocomplete.enhanceSelectElement({
      confirmOnBlur: true,
      defaultValue: "",
      displayMenu: "overlay",
      preserveNullOptions: true,
      selectElement: this.selectElement,
      showAllValues: true,
    })
  }

  get selectElement() {
    return this.element.querySelector("select")
  }
}
