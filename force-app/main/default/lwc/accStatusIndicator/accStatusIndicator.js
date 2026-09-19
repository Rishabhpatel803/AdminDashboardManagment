import { LightningElement, api } from "lwc";

/**
 * accStatusIndicator - the one way status is shown on this page.
 *
 * A status colour never carries meaning on its own here: every indicator
 * pairs the colour with a glyph AND a text label, which is what keeps the
 * amber warning step legible on a white surface.
 *
 * Variants:
 *   dot   - small filled circle + label ("* Healthy")
 *   icon  - SLDS status glyph + label
 *   pill  - washed badge, for the alert severity chips
 */

const MARK = {
  healthy: "#2e844a",
  warning: "#fe9339",
  critical: "#ea001e",
  info: "#0176d3"
};

const INK = {
  healthy: "#2e844a",
  warning: "#dd7a01",
  critical: "#ba0517",
  info: "#0176d3"
};

const WASH = {
  healthy: "#ebf7ee",
  warning: "#fef5e9",
  critical: "#fef1f1",
  info: "#eef4ff"
};

const DEFAULT_ICON = {
  healthy: "utility:success",
  warning: "utility:warning",
  critical: "utility:error",
  info: "utility:info"
};

export default class AccStatusIndicator extends LightningElement {
  /** healthy | warning | critical | info */
  @api status = "info";
  @api label;
  /** dot | icon | pill */
  @api variant = "dot";
  /** Overrides the default glyph for this status. */
  @api iconName;
  @api iconSize = "xx-small";
  @api tooltip;
  /** Renders the label in the status colour instead of neutral ink. */
  @api colorLabel = false;

  get isDot() {
    return this.variant === "dot";
  }

  get isIcon() {
    return this.variant === "icon";
  }

  get isPill() {
    return this.variant === "pill";
  }

  get resolvedIcon() {
    return this.iconName || DEFAULT_ICON[this.status] || DEFAULT_ICON.info;
  }

  get markColor() {
    return MARK[this.status] || MARK.info;
  }

  get inkColor() {
    return INK[this.status] || INK.info;
  }

  get dotStyle() {
    return `background:${this.markColor};`;
  }

  /**
   * SLDS styling hooks are CSS custom properties, so they inherit through the
   * shadow boundary into lightning-icon - the supported way to recolour it.
   */
  get iconStyle() {
    const color = this.markColor;
    return `--sds-c-icon-color-foreground:${color};--sds-c-icon-color-foreground-default:${color};--slds-c-icon-color-foreground:${color};--slds-c-icon-color-foreground-default:${color};`;
  }

  get pillStyle() {
    return `background:${WASH[this.status]};color:${this.inkColor};`;
  }

  get labelStyle() {
    return this.colorLabel || this.isPill ? `color:${this.inkColor};` : "";
  }
}
