import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["conditions", "template"]

  addCondition(event) {
    event.preventDefault()

    const condition = this.templateTarget.content.cloneNode(true)
    const index = this.numberOfConditions
    const idPrefix = `condition_set_conditions_attributes_${index}`
    const namePrefix = `condition_set[conditions_attributes][${index}]`

    const wrapper = condition.querySelector(".condition")
    wrapper.dataset.index = index

    const inputs = ["_destroy", "standard", "title", "text", "reason"]

    for (const input of inputs) {
      const element = condition.querySelector(`#${input}Input`)
      element.id = `${idPrefix}_${input}`
      element.name = `${namePrefix}[${input}]`
    }

    let labels = []

    if (window.location.href.includes("pre_commencement=true")) {
      labels = ["title", "text", "reason"]
    } else {
      labels = ["text", "reason"]
    }

    for (const label of labels) {
      const element = condition.querySelector(`#${label}Label`)
      element.htmlFor = `${idPrefix}_${label}`
      element.id = undefined
    }

    const removeLink = condition.querySelector("a")
    removeLink.addEventListener("click", (event) => {
      this.removeCondition(event)
    })

    this.conditionsTarget.appendChild(condition)
  }

  removeCondition(event) {
    event.preventDefault()

    const condition = event.srcElement.parentElement
    const index = condition.dataset.index
    const destroyInputId = `#condition_set_conditions_attributes_${index}__destroy`
    const destroyInput = condition.querySelector(destroyInputId)

    if (destroyInput) {
      destroyInput.value = "true"
    }

    condition.classList.remove("govuk-!-margin-bottom-5")

    const formGroups = condition.querySelectorAll(".govuk-form-group")
    for (const formGroup of formGroups) {
      formGroup.remove()
    }

    const removeLink = condition.querySelector("a")
    removeLink.remove()
  }

  get numberOfConditions() {
    return this.element.querySelectorAll(".condition").length
  }
}
