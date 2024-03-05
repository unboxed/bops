import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["terms", "template"]

  addTerm(event) {
    event.preventDefault()

    const term = this.templateTarget.content.cloneNode(true)
    const index = this.numberOfTerms
    const idPrefix = `heads_of_term_terms_attributes_${index}`
    const namePrefix = `heads_of_term[terms_attributes][${index}]`

    const wrapper = term.querySelector(".term")
    wrapper.dataset.index = index

    const inputs = ["_destroy", "title", "text"]

    for (const input of inputs) {
      const element = term.querySelector(`#${input}Input`)
      element.id = `${idPrefix}_${input}`
      element.name = `${namePrefix}[${input}]`
    }

    const labels = ["title", "text"]

    for (const label of labels) {
      const element = term.querySelector(`#${label}Label`)
      element.htmlFor = `${idPrefix}_${label}`
      element.id = undefined
    }

    const removeLink = term.querySelector("a")
    removeLink.addEventListener("click", (event) => {
      this.removeTerm(event)
    })

    this.termsTarget.appendChild(term)
  }

  removeTerm(event) {
    event.preventDefault()

    const term = event.srcElement.parentElement
    const index = term.dataset.index
    const destroyInputId = `#heads_of_term_terms_attributes_${index}__destroy`
    const destroyInput = term.querySelector(destroyInputId)

    if (destroyInput) {
      destroyInput.value = "true"
    }

    term.classList.remove("govuk-!-margin-bottom-5")

    const formGroups = term.querySelectorAll(".govuk-form-group")
    for (const formGroup of formGroups) {
      formGroup.remove()
    }

    const removeLink = term.querySelector("a")
    removeLink.remove()
  }

  get numberOfTerms() {
    return this.element.querySelectorAll(".term").length
  }
}
