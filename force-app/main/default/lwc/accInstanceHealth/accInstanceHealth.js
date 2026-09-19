import { LightningElement, api } from "lwc";

/**
 * Section 1 - Instance Health & Organization Information.
 *
 * Receives the live AccModel.OrgInfo payload. Org Status reflects that the
 * platform served this request, which is independent of the weighted
 * instance health score shown in the hero header. Salesforce Trust requires
 * an external callout this page does not make, so it renders as Data
 * Unavailable rather than an assumed "Verified".
 */
export default class AccInstanceHealth extends LightningElement {
  @api org;

  get blocks() {
    if (!this.org) {
      return [];
    }
    const org = this.org;
    const blocks = [
      { id: "instanceId", label: "Instance ID", value: org.instanceId },
      {
        id: "environment",
        label: "Environment",
        value: org.environment,
        status: "healthy"
      },
      { id: "release", label: "Release", value: org.release },
      {
        id: "orgStatus",
        label: "Org Status",
        value: org.statusLabel,
        status: org.status
      }
    ];

    if (org.trustUnavailable) {
      blocks.push({
        id: "trust",
        label: "Salesforce Trust",
        value: org.trust,
        icon: "utility:shield",
        iconStatus: "info"
      });
    } else {
      blocks.push({
        id: "trust",
        label: "Salesforce Trust",
        value: org.trust,
        icon: "utility:shield",
        iconStatus: "healthy"
      });
    }

    blocks.push({
      id: "instanceUrl",
      label: "Instance URL",
      value: org.instanceUrl,
      href: org.instanceUrlHref
    });
    blocks.push({
      id: "myDomain",
      label: "My Domain",
      value: org.myDomain,
      href: org.myDomainHref
    });
    return blocks;
  }
}
