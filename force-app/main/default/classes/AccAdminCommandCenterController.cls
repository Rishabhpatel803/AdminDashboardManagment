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
    for (AccDashboardSettings__mdt setting : [
      SELECT DeveloperName, Visible__c
      FROM AccDashboardSettings__mdt
    ]) {
      Boolean visible = setting.Visible__c == null || setting.Visible__c;
      if (setting.DeveloperName == 'PageHeader') {
        payload.visibility.pageHeader = visible;
      } else if (setting.DeveloperName == 'InstanceHealth') {
        payload.visibility.instanceHealth = visible;
      } else if (setting.DeveloperName == 'UsersAccess') {
        payload.visibility.usersAccess = visible;
      } else if (setting.DeveloperName == 'LicenseOverview') {
        payload.visibility.licenseOverview = visible;
      } else if (setting.DeveloperName == 'SecurityHealth') {
        payload.visibility.securityHealth = visible;
      } else if (setting.DeveloperName == 'AutomationOverview') {
        payload.visibility.automationOverview = visible;
      } else if (setting.DeveloperName == 'IntegrationMonitoring') {
        payload.visibility.integrationMonitoring = visible;
      } else if (setting.DeveloperName == 'ApiLimits') {
        payload.visibility.apiLimits = visible;
      } else if (setting.DeveloperName == 'Deployments') {
        payload.visibility.deployments = visible;
      } else if (setting.DeveloperName == 'CodeHealth') {
        payload.visibility.codeHealth = visible;
      } else if (setting.DeveloperName == 'DataOverview') {
        payload.visibility.dataOverview = visible;
      } else if (setting.DeveloperName == 'CriticalAlerts') {
        payload.visibility.criticalAlerts = visible;
      } else if (setting.DeveloperName == 'AdminActivity') {
        payload.visibility.adminActivity = visible;
      } else if (setting.DeveloperName == 'QuickActions') {
        payload.visibility.quickActions = visible;
      } else if (setting.DeveloperName == 'Footer') {
        payload.visibility.footer = visible;
      }
    }

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
