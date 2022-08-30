import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hideable"]

  handleChange(event) {
    event.target.checked ? this.hide() : this.show()
  }

  hide() {
    this.hideableTargets.forEach(element => {
      element.classList.add("display-none")
    })
  }

  show() {
    this.hideableTargets.forEach(element => {
      element.classList.remove("display-none")
    })
  }
}
