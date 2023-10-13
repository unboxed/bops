import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  addCondition(event) {
    event.preventDefault()
    const form = document.getElementById("add-condition-form")
    const clone = form.cloneNode(true)
    const length = document.querySelectorAll(".condition-form").length
    this.changeIds(clone, length)
    clone.id = `add-condition-form-${length}`
    clone.classList.remove("display-none")
    const place = document.getElementById("new-forms")
    place.appendChild(clone)
  }

  removeCondition(event) {
    event.preventDefault()
    event.srcElement.parentNode.remove()
  }

  changeIds(form, length) {
    const inputs = form.getElementsByTagName("input")

    for (let a = 0; a < inputs.length; a++) {
      const formCount = 3 + length
      inputs[a].name = inputs[a].name.replace(/\d/g, `${formCount}`)
      inputs[a].id = inputs[a].id.replace(/\d/g, `${formCount}`)
    }

    const divs = form.getElementsByTagName("div")

    for (let b = 0; b < divs.length; b++) {
      const count = 3 + length
      const children = divs[b].childNodes

      for (let k = 0; k < children.length; k++) {
        if (children[k].hasAttribute("for")) {
          children[k].setAttribute(
            "for",
            children[k].getAttribute("for").replace(/\d/g, `${count}`),
          )
        }
        if (children[k].hasAttribute("name")) {
          children[k].name = children[k].name.replace(/\d/g, `${count}`)
          children[k].id = children[k].id.replace(/\d/g, `${count}`)
        }
      }
    }
  }
}
