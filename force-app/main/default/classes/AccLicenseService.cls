/**
 * Section 3 - License Overview, sourced from UserLicense and
 * PermissionSetLicense.
 *
 * Salesforce reports unlimited allocations as TotalLicenses = -1, so any
 * licence whose total is not a positive number is excluded from utilisation
 * maths rather than producing a nonsense percentage.
 */
public with sharing class AccLicenseService {
  public static AccModel.LicenseSection build() {
    AccModel.LicenseSection section = new AccModel.LicenseSection();

    List<UserLicense> licenses;
    try {
      licenses = [
        SELECT Id, Name, MasterLabel, TotalLicenses, UsedLicenses, Status
        FROM UserLicense
        WHERE Status = 'Active'
        ORDER BY TotalLicenses DESC
      ];
    } catch (Exception e) {
      section.unavailable = true;
      section.unavailableReason = 'UserLicense is not readable by this user.';
      return section;
    }

    UserLicense primary = pickPrimary(licenses);
    if (primary == null) {
      section.unavailable = true;
      section.unavailableReason = 'This org has no active user licence with a fixed allocation.';
      return section;
    }

    Integer used = primary.UsedLicenses == null ? 0 : primary.UsedLicenses;
    Integer total = primary.TotalLicenses;
    Decimal utilisation = AccStatus.percent(used, total);
    String status = AccStatus.fromUsage(
      utilisation,
      AccStatus.LICENSE_HEALTHY,
      AccStatus.LICENSE_WARNING
    );

    section.primaryName = primary.MasterLabel + ' Licenses';
    section.primaryCountLabel = used + ' / ' + total;
    section.primaryAvailableLabel = 'Available: ' + (total - used);

    AccModel.Tile primaryTile = new AccModel.Tile(
      'primary',
      section.primaryName,
      section.primaryCountLabel,
      status
    );
    section.primary = primaryTile;

    section.donut = new AccModel.Donut(
      utilisation,
      'Used',
      status,
      used +
        ' of ' +
        total +
        ' ' +
        primary.MasterLabel +
        ' licences assigned (' +
        AccStatus.percentLabel(utilisation) +
        ').'
    );

    section.supporting.add(permissionSetLicenses());
    section.supporting.add(otherUserLicenses(licenses, primary));

    List<String> statuses = new List<String>{ status };
    for (AccModel.Tile tile : section.supporting) {
      if (tile.unavailable != true) {
        statuses.add(tile.status);
      }
    }
    section.status = AccStatus.worst(statuses);
    return section;
  }

  /**
   * The headline licence: the standard "Salesforce" licence when present,
   * otherwise the largest fixed allocation in the org.
   */
  private static UserLicense pickPrimary(List<UserLicense> licenses) {
    UserLicense fallback = null;
    for (UserLicense licence : licenses) {
      if (licence.TotalLicenses == null || licence.TotalLicenses <= 0) {
        continue;
      }
      if (licence.Name == 'Salesforce') {
        return licence;
      }
      if (fallback == null) {
        fallback = licence;
      }
    }
    return fallback;
  }

  private static AccModel.Tile permissionSetLicenses() {
    Integer used = 0;
    Integer total = 0;
    Boolean found = false;

    for (
      SObject row : AccQuery.queryOrEmpty(
        'SELECT TotalLicenses, UsedLicenses FROM PermissionSetLicense WHERE Status = \'Active\''
      )
    ) {
      Integer rowTotal = (Integer) row.get('TotalLicenses');
      Integer rowUsed = (Integer) row.get('UsedLicenses');
      if (rowTotal == null || rowTotal <= 0) {
        continue;
      }
      total += rowTotal;
      used += rowUsed == null ? 0 : rowUsed;
      found = true;
    }

    if (!found) {
      AccModel.Tile tile = new AccModel.Tile(
        'permsetlic',
        'Permission Set Licenses',
        'None',
        AccStatus.INFO
      );
      tile.tooltip = 'This org has no active permission set licences with a fixed allocation.';
      return tile;
    }

    Decimal utilisation = AccStatus.percent(used, total);
    AccModel.Tile tile = new AccModel.Tile(
      'permsetlic',
      'Permission Set Licenses',
      used + ' / ' + total,
      AccStatus.fromUsage(
        utilisation,
        AccStatus.LICENSE_HEALTHY,
        AccStatus.LICENSE_WARNING
      )
    );
    tile.tooltip =
      AccStatus.percentLabel(utilisation) +
      ' utilised across all active permission set licences.';
    return tile;
  }

  /**
   * Every other fixed-allocation user licence, combined.
   *
   * The specification asks for "Feature Licenses" here. Feature licences are
   * not exposed as a queryable object (only per-user checkbox fields, with no
   * queryable allocation), so this row reports the remaining user licences -
   * real numbers - instead of an unavailable placeholder.
   */
  private static AccModel.Tile otherUserLicenses(
    List<UserLicense> licenses,
    UserLicense primary
  ) {
    Integer used = 0;
    Integer total = 0;
    Boolean found = false;

    for (UserLicense licence : licenses) {
      if (
        licence.Id == primary.Id ||
        licence.TotalLicenses == null ||
        licence.TotalLicenses <= 0
      ) {
        continue;
      }
      total += licence.TotalLicenses;
      used += licence.UsedLicenses == null ? 0 : licence.UsedLicenses;
      found = true;
    }

    if (!found) {
      AccModel.Tile tile = new AccModel.Tile(
        'otherlic',
        'Other User Licenses',
        'None',
        AccStatus.INFO
      );
      tile.tooltip = 'This org has no other user licences with a fixed allocation.';
      return tile;
    }

    Decimal utilisation = AccStatus.percent(used, total);
    AccModel.Tile tile = new AccModel.Tile(
      'otherlic',
      'Other User Licenses',
      used + ' / ' + total,
      AccStatus.fromUsage(
        utilisation,
        AccStatus.LICENSE_HEALTHY,
        AccStatus.LICENSE_WARNING
      )
    );
    tile.tooltip =
      AccStatus.percentLabel(utilisation) +
      ' utilised. Feature licences have no queryable allocation, so they are not shown.';
    return tile;
  }
}
