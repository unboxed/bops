import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"

export default class extends Controller {
  handleClick(event) {
    event.preventDefault()
    const doc = new jsPDF("p", "px", "a4")
    const applicationReference = document.getElementById(
      "application-reference",
    ).innerText
    const pdfjs = document.getElementById("site-notice-content")
    doc.html(pdfjs, {
      callback: function (doc) {
        doc.setFont("Helvetica")
        doc.save(`site-notice-${applicationReference}.pdf`)
      },
    })
  }
}
