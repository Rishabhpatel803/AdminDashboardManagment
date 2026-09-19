import { LightningElement, api } from "lwc";

/**
 * Section 10 - Data Overview (with Section 11 storage utilisation). `data`
 * is the live AccModel.DataSection payload: real record counts via
 * Database.countQuery per object, real storage via System.OrgLimits. Growth
 * against a "previous period" has no historical snapshot in Salesforce, so
 * it reports Data Unavailable rather than an invented percentage.
 */
export default class AccDataOverview extends LightningElement {
  @api data;

  get objects() {
    if (!this.data) {
      return [];
    }
    return (this.data.objects || []).map((obj) => ({
      ...obj,
      impactClass: `data__impact acc-t-${obj.impactStatus}`,
      barStyle: `--acc-share:${obj.share}%;`
    }));
  }

  get storageMeters() {
    return this.data ? this.data.storage.meters || [] : [];
  }

  get storageTotals() {
    return this.data ? this.data.storage.totals || [] : [];
  }

  get storageUnavailable() {
    return this.storageMeters.length === 0;
  }

  get activity() {
    if (!this.data) {
      return [];
    }
    return (this.data.activity || []).map((row) => ({
      ...row,
      valueClass: row.unavailable
        ? "data__activity-value acc-unavailable"
        : "data__activity-value"
    }));
  }

  get growthUnavailable() {
    return this.data ? this.data.growthUnavailable : true;
  }

  get growthClass() {
    return `data__growth acc-t-${this.data ? this.data.growthStatus : "info"}`;
  }

  get totalRecords() {
    return this.data ? this.data.totalRecords : "N/A";
  }

  get growthLabel() {
    return this.data ? this.data.growthLabel : "N/A";
  }
}
