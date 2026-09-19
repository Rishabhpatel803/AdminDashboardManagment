import { LightningElement, api } from "lwc";

/**
 * accMeter - horizontal progress bar for every usage limit on the page.
 *
 * The fill carries severity and the unfilled track is a lighter step of the
 * SAME hue, so the state reads across the whole bar rather than only the
 * filled part. Width always equals the real percentage - never a decorative
 * value.
 */
const FILL = {
  healthy: "#0176d3",
  warning: "#fe9339",
  critical: "#ea001e",
  info: "#0176d3"
};

const TRACK = {
  healthy: "#cfe6fb",
  warning: "#fde3c8",
  critical: "#fbd5d9",
  info: "#cfe6fb"
};

export default class AccMeter extends LightningElement {
  @api label;
  /** Real percentage 0-100, already computed as current / maximum x 100. */
  @api usage = 0;
  /** Pre-formatted percentage, e.g. "68%". */
  @api usageLabel;
  /** healthy | warning | critical | info */
  @api status = "info";
  /** Optional "102,450 / 150,000 (68%)" raw-counts line. */
  @api counts;
  /** Optional secondary line, e.g. "156 GB of 200 GB". */
  @api detail;
  @api tooltip;

  get clamped() {
    const num = Number(this.usage) || 0;
    return Math.min(100, Math.max(0, num));
  }

  get displayPercent() {
    return this.usageLabel || `${Math.round(this.clamped)}%`;
  }

  get trackStyle() {
    return `background:${TRACK[this.status] || TRACK.info};`;
  }

  /* Square at the baseline, 4px rounded at the data end. */
  get fillStyle() {
    return `width:${this.clamped.toFixed(2)}%;background:${FILL[this.status] || FILL.info};`;
  }
}
