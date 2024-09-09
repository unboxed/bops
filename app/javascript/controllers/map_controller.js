import { Controller } from "@hotwired/stimulus"
import "leaflet"
import "leaflet-css"

export default class extends Controller {
  connect() {
    L.Icon.Default.imagePath = "/assets"

    this.mapElement = this.element.querySelector("#map")

    const layerData = JSON.parse(this.element.dataset.layers)
    const redline = layerData.redline
    const neighbours = layerData.neighbours

    const layers = []

    let [lat, long, ..._] = this.element.dataset.latlong.split(",")

    if (redline !== null) {
      const geoJsonLayer = L.geoJson(redline, {
        style: {
          color: "#ff0000",
          weight: 2,
          opacity: 0.67,
        },
      })
      layers.push(geoJsonLayer)
      const centre = geoJsonLayer.getBounds().getCenter()
      lat = centre.lat
      long = centre.lng
    }

    this.map = L.map(this.mapElement.id, {
      center: [lat, long],
      zoom: 17,
    })

    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 25,
      attribution:
        '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(this.map)

    if (neighbours !== null) {
      for (const summary_tag in neighbours) {
        layers.push(
          this.buildNeighboursLayer(neighbours[summary_tag], summary_tag),
        )
      }
    }

    for (const layer of layers) {
      layer.addTo(this.map)
    }
  }

  buildNeighboursLayer(neighboursList, summary_tag) {
    const colours = {
      supportive: { fill: "#cce2d8", border: "#005a30" },
      neutral: { fill: "#fff7bf", border: "#594d00" },
      objection: { fill: "#f6d7d2", border: "#942514" },
      no_response: { fill: "#d2e2f1", border: "#003078" },
    }

    const neighbourMarkerOptions = {
      radius: 8,
      fillColor: colours[summary_tag].fill,
      color: colours[summary_tag].border,
      weight: 1,
      opacity: 1,
      fillOpacity: 1,
    }

    const neighboursCollection = {
      type: "FeatureCollection",
      features: neighboursList.map((point) => {
        return {
          type: "Feature",
          geometry: point,
        }
      }),
    }

    return L.geoJson(neighboursCollection, {
      pointToLayer: (feature, latlng) => {
        return L.circleMarker(latlng, neighbourMarkerOptions)
      },
    })
  }

  showMapData(ev) {
    ev.target.classList.add("govuk-!-display-none")
    ev.target.parentNode
      .querySelector(".map-data")
      .classList.remove("govuk-!-display-none")
  }

  hideMapData(ev) {
    ev.target.parentNode.classList.add("govuk-!-display-none")
    ev.target.parentNode.parentNode
      .querySelector(".map-data-toggle")
      .classList.remove("govuk-!-display-none")
  }
}
