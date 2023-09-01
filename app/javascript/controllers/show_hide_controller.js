import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleable", "toggleableWhenNo", "toggleableWhenYes"]

  handleEvent(_event) {
    this.toggleableTargets.forEach((element) => {
      element.classList.toggle("display-none")
    })
  }

  handleEventForDecision(_event) {
    const selectedDecisionHtml = document.querySelector(
      'input[name="assess_immunity_detail_permitted_development_right_form[review_immunity_detail][decision]"]:checked',
    )
    const selectedDecisionValue = selectedDecisionHtml.value
    let oppositeValue = "Yes"

    if (selectedDecisionValue === "Yes") {
      oppositeValue = "No"
    }

    this[`toggleableWhen${selectedDecisionValue}Targets`].forEach((element) => {
      element.classList.remove("display-none")
    })
    this[`toggleableWhen${oppositeValue}Targets`].forEach((element) => {
      element.classList.add("display-none")
    })
  }
}
