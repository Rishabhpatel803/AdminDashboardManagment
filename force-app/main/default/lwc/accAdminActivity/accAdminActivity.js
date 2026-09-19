import { LightningElement, api } from "lwc";

const WASH = {
  healthy: "#ebf7ee",
  warning: "#fef5e9",
  critical: "#fef1f1",
  info: "#eef4ff"
};
const MARK = {
  healthy: "#2e844a",
  warning: "#fe9339",
  critical: "#ea001e",
  info: "#0176d3"
};

/**
 * Section 12 - Recent Admin Activity. `activity` is the live list built by
 * AccActivityService from SetupAuditTrail, already sorted most-recent-first
 * and capped at 5 per the specification.
 */
export default class AccAdminActivity extends LightningElement {
  @api activity;

  get entries() {
    const items = this.activity || [];
    return items.map((item, index) => ({
      ...item,
      itemClass:
        index === items.length - 1 ? "tl__item tl__item--last" : "tl__item",
      badgeStyle: `background:${WASH[item.status] || WASH.info};`,
      iconStyle: `--sds-c-icon-color-foreground-default:${MARK[item.status] || MARK.info};--sds-c-icon-color-foreground:${MARK[item.status] || MARK.info};`
    }));
  }

  get hasEntries() {
    return this.entries.length > 0;
  }

  handleViewAll(event) {
    event.preventDefault();
  }
}
