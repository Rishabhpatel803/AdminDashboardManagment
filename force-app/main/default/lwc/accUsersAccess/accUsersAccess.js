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
 * Section 2 - Users & Access Overview: six KPIs plus the Admin Alerts panel.
 * `data` is the live AccModel.UsersSection payload from Apex.
 */
export default class AccUsersAccess extends LightningElement {
  @api data;

  get kpis() {
    if (!this.data) {
      return [];
    }
    return (this.data.kpis || []).map((kpi) => ({
      ...kpi,
      cardClass: kpi.wide ? "kpi kpi--wide" : "kpi",
      valueClass: kpi.unavailable ? "kpi__value acc-unavailable" : "kpi__value",
      badgeStyle: `background:${WASH[kpi.status] || WASH.info};`,
      iconStyle: `--sds-c-icon-color-foreground-default:${MARK[kpi.status] || MARK.info};--sds-c-icon-color-foreground:${MARK[kpi.status] || MARK.info};`
    }));
  }

  get alerts() {
    if (!this.data) {
      return [];
    }
    return (this.data.alerts || []).map((alert) => ({
      ...alert,
      countClass: alert.unavailable
        ? "users__alert-count acc-tabular acc-unavailable"
        : "users__alert-count acc-tabular"
    }));
  }

  handleViewAll(event) {
    event.preventDefault();
  }
}
