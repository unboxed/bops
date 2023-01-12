import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleable"]

  handleEvent(_event) {
    this.toggleableTargets.forEach((element) => {
      element.classList.toggle("display-none")
    })
  }
}
