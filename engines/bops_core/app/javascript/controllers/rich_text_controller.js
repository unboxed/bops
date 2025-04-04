import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"
import Trix from "trix"

export class AttachmentUpload {
  constructor(attachment, element) {
    this.attachment = attachment
    this.element = element
    this.directUpload = new DirectUpload(
      attachment.file,
      this.directUploadUrl,
      this,
    )
  }

  start() {
    this.directUpload.create(this.directUploadDidComplete.bind(this))
  }

  directUploadWillStoreFileWithXHR(xhr) {
    xhr.upload.addEventListener("progress", (event) => {
      const progress = (event.loaded / event.total) * 100
      this.attachment.setUploadProgress(progress)
    })
  }

  directUploadDidComplete(error, attributes) {
    if (error) {
      throw new Error(`Direct upload failed: ${error}`)
    }

    this.attachment.setAttributes({
      sgid: attributes.attachable_sgid,
      url: this.createBlobUrl(attributes.key),
    })
  }

  createBlobUrl(key) {
    return this.blobUrlTemplate.replace(":key", key)
  }

  get directUploadUrl() {
    return this.element.dataset.directUploadUrl
  }

  get blobUrlTemplate() {
    return this.element.dataset.blobUrlTemplate
  }
}

document.addEventListener("trix-attachment-add", (event) => {
  const { attachment, target } = event

  if (attachment.file) {
    const upload = new AttachmentUpload(attachment, target)
    upload.start()
  }
})

document.addEventListener("trix-before-initialize", () => {
  // Line breaks
  Trix.Block.prototype.breaksOnReturn = function () {
    const attr = this.getLastAttribute()
    const config = Trix.config.blockAttributes[attr ? attr : "default"]

    return config ? config.breakOnReturn : false
  }

  Trix.LineBreakInsertion.prototype.shouldInsertBlockBreak = function () {
    if (
      this.block.hasAttributes() &&
      this.block.isListItem() &&
      !this.block.isEmpty()
    ) {
      return this.startLocation.offset > 0
    } else {
      return !this.shouldBreakFormattedBlock() ? this.breaksOnReturn : false
    }
  }

  // Attachments
  Trix.config.attachments.preview.caption = {
    name: false,
    size: false,
  }

  Trix.config.attachments.file.caption = {
    size: false,
  }

  Trix.config.lang.captionPlaceholder = "Add alt text…"

  // Block attributes
  Trix.config.blockAttributes.default = {
    tagName: "div",
    parse: false,
    breakOnReturn: true,
  }

  // Text attributes
  Trix.config.textAttributes.underline = {
    style: { textDecoration: "underline" },
  }

  // Language
  Trix.config.lang.underline = "Underline"

  // Toolbar
  Trix.config.toolbar.getDefaultHTML = () => {
    const { lang } = Trix.config

    return `<div class="trix-button-row">
      <span class="trix-button-group trix-button-group--text-tools" data-trix-button-group="text-tools">
        <button type="button" class="trix-button trix-button--icon trix-button--icon-bold" data-trix-attribute="bold" data-trix-key="b" title="${lang.bold}" tabindex="-1">${lang.bold}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-italic" data-trix-attribute="italic" data-trix-key="i" title="${lang.italic}" tabindex="-1">${lang.italic}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-underline" data-trix-attribute="underline" data-trix-key="u" title="${lang.underline}" tabindex="-1">${lang.underline}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-link" data-trix-attribute="href" data-trix-action="link" data-trix-key="k" title="${lang.link}" tabindex="-1">${lang.link}</button>
      </span>

      <span class="trix-button-group trix-button-group--block-tools" data-trix-button-group="block-tools">
        <button type="button" class="trix-button trix-button--icon trix-button--icon-bullet-list" data-trix-attribute="bullet" title="${lang.bullets}" tabindex="-1">${lang.bullets}</button>
        <button type="button" class="trix-button trix-button--icon trix-button--icon-number-list" data-trix-attribute="number" title="${lang.numbers}" tabindex="-1">${lang.numbers}</button>
      </span>

      <span class="trix-button-group trix-button-group--file-tools" data-trix-button-group="file-tools">
        <button type="button" class="trix-button trix-button--icon trix-button--icon-attach" data-trix-action="attachFiles" title="${lang.attachFiles}" tabindex="-1">${lang.attachFiles}</button>
      </span>
    </div>

    <div class="trix-dialogs" data-trix-dialogs>
      <div class="trix-dialog trix-dialog--link" data-trix-dialog="href" data-trix-dialog-attribute="href">
        <div class="trix-dialog__link-fields">
          <input type="url" name="href" class="trix-input trix-input--dialog" placeholder="${lang.urlPlaceholder}" aria-label="${lang.url}" data-trix-validate-href required data-trix-input>
          <div class="trix-button-group">
            <input type="button" class="trix-button trix-button--dialog" value="${lang.link}" data-trix-method="setAttribute">
            <input type="button" class="trix-button trix-button--dialog" value="${lang.unlink}" data-trix-method="removeAttribute">
          </div>
        </div>
      </div>
    </div>`
  }
})

export default class extends Controller {
  connect() {
    this.editor.addEventListener("trix-file-accept", (event) => {
      this.canAcceptFile(event)
    })
  }

  canAcceptFile(event) {
    const acceptedTypes = ["image/jpeg", "image/png", "image/gif"]

    if (!acceptedTypes.includes(event.file.type)) {
      event.preventDefault()

      alert(
        "File attachment not supported! You may only add jpeg, png or gif images.",
      )
    }

    // Only allow file size up to 4MB
    const maxFileSize = 4096 * 1024

    if (event.file.size > maxFileSize) {
      event.preventDefault()

      alert(
        "File size is too large! You may only add images up to 4MB in size.",
      )
    }
  }

  get editor() {
    return this.element.querySelector("trix-editor")
  }
}
