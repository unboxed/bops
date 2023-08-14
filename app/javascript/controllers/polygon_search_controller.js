import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const map = document.querySelector("my-map")

    map.addEventListener("geojsonChange", ({ detail: geoJSON }) => {
      console.log(geoJSON.features[0])

      this.handleGeojsonChange(geoJSON.features[0])
    })
  }

  async handleGeojsonChange(geoJSON) {
    const CSRF = document
      .querySelector("[name='csrf-token']")
      .getAttribute("content")

    try {
      const response = await fetch(
        document.querySelector("#os_polygon_path").value,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": CSRF,
          },
          body: JSON.stringify({ geojson: geoJSON }),
        },
      )

      if (!response.ok) {
        throw new Error(`There is a HTTP error with status: ${response.status}`)
      }

      const data = await response.json()
      console.log("DATA", data)

      this.appendAddressesToPage(data)
    } catch (error) {
      console.error("There was an error calling the service:", error)
    }
  }

  appendAddressesToPage(addresses) {
    const container = document.getElementById("address-container")

    container.innerHTML = "";
    addresses.forEach((address) => {
      const p = document.createElement("p")
      p.classList.add("govuk-body")
      p.textContent = address
      container.appendChild(p)
    })
  }
}
