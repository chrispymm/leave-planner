import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    this.closeOnEscape = this.closeOnEscape.bind(this)

    document.addEventListener("click", this.closeOnOutsideClick)
    document.addEventListener("keydown", this.closeOnEscape)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.open) {
      this.close()
    } else {
      this.show()
    }
  }

  show() {
    this.menuTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.menuTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  closeOnOutsideClick(event) {
    if (this.open && !this.element.contains(event.target)) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && this.open) {
      this.close()
      this.buttonTarget.focus()
    }
  }

  get open() {
    return !this.menuTarget.hidden
  }
}
