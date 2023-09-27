import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"

export default class extends Controller {
  handleClick(_event) {
    let doc = new jsPDF('p', 'px', 'a4')
    let pdfjs = document.getElementById('site-notice-content')
    doc.html(pdfjs, {
        callback: function(doc) {
            doc.save("site-notice.pdf");
        }
    })
  }
}
