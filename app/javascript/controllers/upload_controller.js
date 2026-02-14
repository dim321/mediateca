import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Toggle upload form visibility
    const link = document.querySelector('[href="#upload-form"]')
    if (link) {
      link.addEventListener("click", (e) => {
        e.preventDefault()
        this.element.classList.toggle("hidden")
      })
    }
  }
}
