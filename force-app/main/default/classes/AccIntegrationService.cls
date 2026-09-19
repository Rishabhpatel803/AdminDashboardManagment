/**
 * Section 6 - Integration Monitoring.
 *
 * The org can tell us what integrations are CONFIGURED (NamedCredential,
 * ConnectedApplication, ExternalCredential) but not whether the remote systems
 * are UP - that needs an outbound callout per endpoint, which a cacheable read
 * cannot perform. So the connected-system cards list the real named
 * credentials with an informational status, and the Integration Health donut
 * reports Data Unavailable instead of inventing an uptime percentage.
 */
public with sharing class AccIntegrationService {
  private static final Integer MAX_SYSTEM_CARDS = 6;

  public static AccModel.IntegrationSection build() {
    AccModel.IntegrationSection section = new AccModel.IntegrationSection();

    Integer namedCredentials = AccQuery.countOrNull(
      'SELECT COUNT() FROM NamedCredential'
    );
    Integer connectedApps = AccQuery.countOrNull(
      'SELECT COUNT() FROM ConnectedApplication'
    );
    Integer externalCredentials = AccQuery.isQueryable('ExternalCredential')
      ? AccQuery.countOrNull('SELECT COUNT() FROM ExternalCredential')
      : null;

    /* --- connected system cards, from real named credentials ---------- */

    List<SObject> credentials = AccQuery.queryOrEmpty(
      'SELECT DeveloperName, MasterLabel FROM NamedCredential ORDER BY MasterLabel LIMIT ' +
      MAX_SYSTEM_CARDS
    );

    if (credentials.isEmpty()) {
      section.systemsUnavailable = true;
      section.systemsUnavailableReason = namedCredentials == null
        ? 'NamedCredential is not readable by this user.'
        : 'This org has no named credentials configured.';
    } else {
      for (SObject credential : credentials) {
        String label = (String) credential.get('MasterLabel');
        AccModel.Tile tile = new AccModel.Tile(
          (String) credential.get('DeveloperName'),
          label,
          'Configured',
          AccStatus.INFO
        );
        tile.icon = 'utility:connected_apps';
        tile.statusLabel = 'Configured';
        tile.tooltip =
          'Named credential "' +
          label +
          '" is configured. Live reachability requires an outbound callout, which this page does not perform.';
        section.systems.add(tile);
      }
    }

    /* --- integration details panel ------------------------------------ */

    section.details.add(detail('i1', 'Named Credentials', namedCredentials));
    section.details.add(detail('i2', 'Connected Apps', connectedApps));
    section.details.add(
      detail('i3', 'External Credentials', externalCredentials)
    );

    Decimal apiUsage = AccLimitsService.apiUsagePercent();
    if (apiUsage == null) {
      AccModel.Tile apiTile = new AccModel.Tile(
        'i4',
        'API Usage',
        'N/A',
        AccStatus.INFO
      );
      apiTile.unavailable = true;
      apiTile.tooltip = 'Data Unavailable: the daily API request limit was not reported by OrgLimits.';
      section.details.add(apiTile);
    } else {
      section.details.add(
        new AccModel.Tile(
          'i4',
          'API Usage',
          AccStatus.percentLabel(apiUsage),
          AccStatus.fromUsage(
            apiUsage,
            AccStatus.LIMIT_HEALTHY,
            AccStatus.LIMIT_WARNING
          )
        )
      );
    }

    section.details.add(unavailableDetail('i5', 'Failed Callouts'));
    section.details.add(unavailableDetail('i6', 'Integration Errors'));

    /* --- health donut: genuinely not knowable from Apex --------------- */

    section.unavailable = true;
    section.unavailableReason = 'Live integration health requires an outbound health check per endpoint, which cannot run inside a cacheable Apex read.';
    section.status = AccStatus.INFO;

    AccModel.Donut donut = new AccModel.Donut(
      0,
      'Data Unavailable',
      AccStatus.INFO,
      section.unavailableReason
    );
    donut.label = 'N/A';
    donut.unavailable = true;
    section.donut = donut;

    return section;
  }

  private static AccModel.Tile detail(String id, String label, Integer count) {
    if (count == null) {
      return unavailableDetail(id, label);
    }
    AccModel.Tile tile = new AccModel.Tile(
      id,
      label,
      AccStatus.number(count),
      AccStatus.INFO
    );
    tile.count = count;
    return tile;
  }

  private static AccModel.Tile unavailableDetail(String id, String label) {
    AccModel.Tile tile = new AccModel.Tile(id, label, 'N/A', AccStatus.INFO);
    tile.unavailable = true;
    tile.tooltip = 'Data Unavailable: callout outcomes are not recorded in a queryable Salesforce object.';
    return tile;
  }
}
