/**
 * AccAdminCommandCenterController - the single entry point the Admin Command
 * Center LWC calls.
 *
 * Assembles the payload from the section services and returns one object, so
 * the client makes exactly one Apex round trip and every section is
 * guaranteed to be computed against the same snapshot of org data.
 *
 * Not cacheable: the page shows live counts (logins today, locked users,
 * OrgLimits usage) that must reflect the moment the admin opened the page.
 */
public with sharing class AccAdminCommandCenterController {
  @AuraEnabled
  public static AccModel.Payload getDashboard() {
    AccModel.Payload payload = new AccModel.Payload();

    payload.meta.demoMode = false;
    Datetime now = Datetime.now();
    payload.meta.lastUpdated = String.valueOf(now);
    payload.meta.lastUpdatedLabel =
      'Last Updated: ' + now.format('MMM d, yyyy hh:mm a');
    payload.meta.stale = false;

    payload.org = AccOrgService.build();
    payload.users = AccUsersService.build();
    payload.licenses = AccLicenseService.build();
    payload.security = AccSecurityService.build(payload.users.mfaAdoption);
    payload.automation = AccAutomationService.build();
    payload.integrations = AccIntegrationService.build();
    payload.limits = AccLimitsService.build();
    payload.deployments = AccDeploymentService.build();
    payload.code = AccCodeService.build();
    payload.dataOverview = AccDataService.build();

    payload.health = AccHealthService.build(payload);
    payload.alerts = AccAlertsService.build(payload);
    payload.activity = AccActivityService.build();

    return payload;
  }
}
