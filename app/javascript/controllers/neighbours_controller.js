import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggleNeighbours(event) {
    const checked = event.srcElement.checked

    for (const checkbox of this.neighbourCheckboxes) {
      checkbox.checked = checked
    }
  }

  get neighbourCheckboxes() {
    return document.getElementById("selected-neighbours-list").querySelectorAll(
      "input[type=checkbox]",
    )
  }
}
