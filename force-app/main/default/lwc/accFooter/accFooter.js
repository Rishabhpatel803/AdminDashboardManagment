import { LightningElement, api } from "lwc";

/** Compact Salesforce-style page footer. `org` is the live OrgInfo payload. */
export default class AccFooter extends LightningElement {
  @api org;

  get buildLabel() {
    return this.org ? `Build ${this.org.build}` : "";
  }

  get links() {
    return [
      { id: "help", label: "Need Help?" },
      { id: "docs", label: "View Documentation" },
      { id: "support", label: "Contact Support" }
    ];
  }

  handleInert(event) {
    event.preventDefault();
  }
}
