import { Controller } from "stimulus"

export default class extends Controller {
  toggle(event) {
    const button = event.currentTarget;

    if(button.innerText === "ON") {
      button.innerText = "OFF"
    } else {
      button.innerText = "ON"
    }
  }
}
