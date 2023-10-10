import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "destination"]

  reset() {
    this.destinationTarget.value = this.sourceTarget.value
  }
}
