import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    if (!this.hasMenuTarget) return
    const isNowHidden = this.menuTarget.classList.toggle("hidden")
    const button = event.currentTarget
    if (button) button.setAttribute("aria-expanded", !isNowHidden)
  }
}
