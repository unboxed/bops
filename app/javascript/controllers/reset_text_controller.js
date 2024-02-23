import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "destination"]

  reset(event) {
    if (event.target.value !== "") {
      const destinationTarget = this.destinationTargets.filter((item) =>
        item.id.includes(event.target.value),
      )[0]
      const sourceTarget = this.sourceTargets.filter((item) =>
        item.id.includes(event.target.value),
      )[0]

      destinationTarget.value = sourceTarget.value
    } else {
      this.destinationTarget.value = this.sourceTarget.value
    }
  }
}
