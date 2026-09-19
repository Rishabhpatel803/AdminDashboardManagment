/**
 * Section 1 - Instance Health & Organization Information, sourced live from
 * the Organization record and the org's own domain URLs.
 */
public with sharing class AccOrgService {
  /**
   * API version to marketing release name. The platform exposes no "release"
   * field, so the release is derived from the API version this managed code is
   * saved at, which tracks the org's release.
   */
  private static final Map<String, String> RELEASE_BY_API = new Map<String, String>{
    '59.0' => 'Winter \'24',
    '60.0' => 'Spring \'24',
    '61.0' => 'Summer \'24',
    '62.0' => 'Winter \'25',
    '63.0' => 'Spring \'25',
    '64.0' => 'Summer \'25',
    '65.0' => 'Winter \'26',
    '66.0' => 'Spring \'26',
    '67.0' => 'Summer \'26',
    '68.0' => 'Winter \'27'
  };

  public static AccModel.OrgInfo build() {
    AccModel.OrgInfo info = new AccModel.OrgInfo();

    Organization org = [
      SELECT Id, Name, InstanceName, IsSandbox, OrganizationType
      FROM Organization
      LIMIT 1
    ];

    info.orgName = org.Name;
    info.instanceId = String.isBlank(org.InstanceName)
      ? 'Unknown'
      : org.InstanceName;
    info.isSandbox = org.IsSandbox;
    info.environment = org.IsSandbox ? 'Sandbox' : 'Production';

    String apiVersion = currentApiVersion();
    info.build = apiVersion;
    info.release = RELEASE_BY_API.containsKey(apiVersion)
      ? RELEASE_BY_API.get(apiVersion)
      : 'API ' + apiVersion;

    // The org's own hostnames, read from the platform rather than hard-coded.
    info.instanceUrl = info.instanceId.toLowerCase() + '.salesforce.com';
    info.instanceUrlHref = 'https://' + info.instanceUrl;

    String domain = orgDomain();
    info.myDomain = domain.replaceFirst('^https?://', '');
    info.myDomainHref = domain;

    /*
     * Salesforce Trust incident status lives on status.salesforce.com and needs
     * an external callout (Remote Site Setting or Named Credential), so it is
     * reported as unavailable rather than assumed to be "Verified".
     */
    info.trust = 'Data Unavailable';
    info.trustStatus = AccStatus.CRITICAL;
    info.trustUnavailable = true;

    /*
     * Org Status reflects that the platform is serving this request. It is not
     * a Trust incident check - that is the field above.
     */
    info.status = AccStatus.HEALTHY;
    info.statusLabel = AccStatus.label(info.status);

    return info;
  }

  /** The API version this code runs at, read back from the org. */
  private static String currentApiVersion() {
    List<ApexClass> classes = [
      SELECT ApiVersion
      FROM ApexClass
      WHERE Name = 'AccOrgService'
      LIMIT 1
    ];
    if (classes.isEmpty() || classes[0].ApiVersion == null) {
      return '67.0';
    }
    return String.valueOf(classes[0].ApiVersion.setScale(1));
  }

  /**
   * getSalesforceBaseUrl() was removed after API 58.0, so getOrgDomainUrl() is
   * the only supported source here.
   */
  private static String orgDomain() {
    try {
      return Url.getOrgDomainUrl().toExternalForm();
    } catch (Exception e) {
      return '';
    }
  }
}
