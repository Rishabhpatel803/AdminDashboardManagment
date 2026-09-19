import { LightningElement, api } from "lwc";

/**
 * Section 8 - Deployment & DevOps. `data` is the live
 * AccModel.DeploymentSection payload. Deployment history, change sets and
 * pipeline status are Metadata API concepts with no SOQL-queryable object,
 * so this section always reports Data Unavailable rather than showing any
 * placeholder deployment.
 */
export default class AccDeployments extends LightningElement {
  @api data;

  get isUnavailable() {
    return !this.data || this.data.unavailable;
  }

  get unavailableReason() {
    return this.data ? this.data.unavailableReason : "";
  }

  get footer() {
    return this.data ? this.data.footer || [] : [];
  }
}
