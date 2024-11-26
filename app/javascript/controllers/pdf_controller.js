import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"

export default class extends Controller {
  handleClick(event) {
    const doc = new jsPDF("p", "px", "a4")
    const filename = event.params.filename
    const pdfjs = document.querySelector(event.params.elementSelector)
    doc.html(pdfjs, {
      autopaging: "text",
      margin: [32, 32, 32, 32],
      callback: (doc) => {
        doc.save(filename)
      },
    })
  }
}
