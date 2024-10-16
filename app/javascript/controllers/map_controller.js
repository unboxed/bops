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
      pointToLayer: (_feature, latlng) => {
        const marker = L.circleMarker(latlng, neighbourMarkerOptions)
        marker.on("click", (_ev) => {
          this.filterNeighbourList(latlng)
        })

        return marker
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
    this.filterNeighbourList(null)
  }

  toggleTab(ev) {
    ev.preventDefault()
    this.filterNeighbourList(null)
    for (const el of this.element.querySelectorAll(".map-data-tab")) {
      if (el.classList.contains(`map-data-${ev.params.toggle}`)) {
        el.classList.remove("govuk-!-display-none")
      } else {
        el.classList.add("govuk-!-display-none")
      }
    }
  }

  filterNeighbourList(latlng) {
    if (latlng !== null) {
      this.showMapData({ target: this.element.querySelector("button") })
      this.toggleTab({
        params: { toggle: "neighbours" },
        preventDefault: () => {},
      })
    }
    const lonlatStr =
      latlng === null ||
      `${this.trunc(latlng.lng, 5)},${this.trunc(latlng.lat, 5)}`

    const els = this.element.querySelectorAll("li")
    for (const el of els) {
      if (latlng === null || el.dataset.lonlat === lonlatStr) {
        el.classList.remove("govuk-!-display-none")
      } else {
        el.classList.add("govuk-!-display-none")
      }
    }

    const heading = this.element.querySelector("h3")
    heading.innerHTML = latlng === null ? "All neighbours" : "Neighbours"
  }

  trunc(num, digits) {
    const sign = Math.abs(num) === num ? "" : "-"
    const whole = Math.trunc(num)
    const remainder = num - whole
    const decimals = String(remainder)
      .split(".")[1]
      .slice(0, digits)
      .replace(/0+$/, "")
    return `${sign}${whole}.${decimals}`
  }
}
