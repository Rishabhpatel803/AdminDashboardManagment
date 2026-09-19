import { LightningElement, api } from "lwc";

/**
 * accCard - the card shell every one of the 13 sections sits in.
 *
 * Keeps the numbered blue chip, title, optional status glyph and the
 * top-right action slot ("View All") identical across the whole page, so
 * spacing and typography can never drift section to section.
 */
export default class AccCard extends LightningElement {
  /** Section number rendered in the blue chip, e.g. "7". */
  @api number;
  /** Card heading. Named cardTitle because `title` is a reserved attribute. */
  @api cardTitle;
  /** Optional glyph shown between the chip and the heading. */
  @api iconName;
  /** Colour of that glyph: healthy | warning | critical | info */
  @api iconStatus = "info";
  /** default | critical - critical washes the card in light red. */
  @api variant = "default";
  /** Removes the card's inner padding for edge-to-edge tables. */
  @api flush = false;

  get cardClass() {
    const classes = ["acc-card"];
    if (this.variant === "critical") classes.push("acc-card--alert");
    if (this.flush) classes.push("acc-card--flush");
    return classes.join(" ");
  }

  get titleClass() {
    return this.variant === "critical"
      ? "acc-card__title acc-t-critical"
      : "acc-card__title";
  }

  get iconStyle() {
    const color = {
      healthy: "#2e844a",
      warning: "#fe9339",
      critical: "#ea001e",
      info: "#0176d3"
    }[this.iconStatus];
    return `--sds-c-icon-color-foreground:${color};--sds-c-icon-color-foreground-default:${color};--slds-c-icon-color-foreground:${color};--slds-c-icon-color-foreground-default:${color};`;
  }
}
