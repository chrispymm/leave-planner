import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    reset: Boolean,
    storageKey: String
  }

  connect() {
    if (this.resetValue) {
      this.save()
      return
    }

    const storedState = this.readState()

    if (storedState !== null) {
      this.element.open = storedState === "true"
    }
  }

  save() {
    try {
      window.localStorage.setItem(this.storageKeyValue, String(this.element.open))
    } catch (error) {
      console.warn("Unable to save leave year display state", error)
    }
  }

  readState() {
    try {
      return window.localStorage.getItem(this.storageKeyValue)
    } catch (error) {
      console.warn("Unable to restore leave year display state", error)
      return null
    }
  }
}
