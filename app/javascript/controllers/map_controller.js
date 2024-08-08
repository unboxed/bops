import { Controller } from "@hotwired/stimulus"
import "leaflet"
import "leaflet-css"

export default class extends Controller {
  connect() {
    const [lat, long, ..._] = this.element.dataset.latlong.split(",")
    this.map = L.map(this.element.id, {
      center: [lat, long],
      zoom: 12,
    })
    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 25,
      attribution:
        '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(this.map)

    const redline = JSON.parse(this.element.dataset.redline)
    L.geoJson(redline, {
      style: {
        color: "#ff0000",
        weight: 2,
        opacity: 0.67,
      },
    }).addTo(this.map)
  }
}
