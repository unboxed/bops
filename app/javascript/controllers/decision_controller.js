import { Controller } from "stimulus"

export default class extends Controller {
  toggleText() {
    document.querySelector('#toggleMe').textContent = "WOO"
  }
}
