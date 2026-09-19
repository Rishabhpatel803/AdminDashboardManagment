import { LightningElement, api } from "lwc";

/**
 * accCloudMark - the Salesforce cloud badge, reused by the organization card
 * and the footer so the logo is defined exactly once.
 */
export default class AccCloudMark extends LightningElement {
  /** Badge edge length in px. */
  @api size = 26;
  /** Hides the small "salesforce" wordmark inside the badge. */
  @api hideWordmark = false;

  get rootStyle() {
    return `width:${this.size}px;height:${this.size}px;border-radius:${Math.round(this.size * 0.23)}px;`;
  }

  get showWordmark() {
    return !this.hideWordmark && this.size >= 22;
  }

  get wordmarkStyle() {
    return `font-size:${Math.max(3.5, this.size * 0.16)}px;`;
  }
}
