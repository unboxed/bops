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

  toggleTemplates(event) {
    console.log("i am here")
    const template = event.target.value

    const target = document.getElementById("renotification-form")

    if(template === "Renotification") {
      target.classList.remove("govuk-!-display-none")
    } else {
      target.classList.add("govuk-!-display-none")
    }
  }
}
