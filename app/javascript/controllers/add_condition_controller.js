import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "newForms"]

  addCondition(event) {
    event.preventDefault()
    const clone = this.formTarget.cloneNode(true)
    const length = document.querySelectorAll(".condition-form").length
    this.changeIds(clone, length)
    clone.id = `add-condition-form-${length}`
    clone.classList.remove("display-none")
    clone.data = {} // to remove the stimulus target
    this.newFormsTarget.appendChild(clone)
  }

  removeCondition(event) {
    event.preventDefault()
    event.srcElement.parentNode.remove()
  }

  changeIds(form, length) {
    const inputs = form.getElementsByTagName("input")

    for (const input of inputs) {
      const formCount = 3 + length
      input.name = input.name.replace(/\d/g, `${formCount}`)
      input.id = input.id.replace(/\d/g, `${formCount}`)
    }

    const divs = form.getElementsByTagName("div")

    for (const div of divs) {
      const count = 3 + length
      const children = div.childNodes

      for (const child of children) {
        if (child.hasAttribute("for")) {
          child.setAttribute(
            "for",
            child.getAttribute("for").replace(/\d/g, `${count}`),
          )
        }
        if (child.hasAttribute("name")) {
          child.name = child.name.replace(/\d/g, `${count}`)
          child.id = child.id.replace(/\d/g, `${count}`)
        }
      }
    }
  }
}
