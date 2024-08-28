import { Controller } from "@hotwired/stimulus"
import "leaflet"
import "leaflet-css"

export default class extends Controller {
  connect() {
    L.Icon.Default.imagePath = "/assets"

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

    this.map = L.map(this.element.id, {
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
    let fillColor = "#ff7800"
    if (summary_tag === "supportive") {
      fillColor = "#78ff00"
    } else if (summary_tag === "objection") {
      fillColor = "#ff0078"
    } else if (summary_tag === "no_response") {
      fillColor = "#dddddd"
    }

    const neighbourMarkerOptions = {
      radius: 8,
      fillColor,
      color: "#000",
      weight: 1,
      opacity: 1,
      fillOpacity: 0.8,
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
}
