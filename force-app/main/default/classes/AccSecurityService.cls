/**
 * Section 4 - Security & Access Health.
 *
 * Inventory comes from Profile, PermissionSet, PermissionSetGroup, Group and
 * UserRole. High-risk permission grants come from PermissionSetAssignment.
 *
 * The Security Health Score only deducts for findings this org can actually
 * prove. Certificate checks require Metadata API access, so they are reported
 * as unavailable and excluded from the score rather than silently scored as
 * clean - the donut tooltip says so.
 */
public with sharing class AccSecurityService {
  private static final Integer PENALTY_HIGH_RISK_PERMISSION = 10;
  private static final Integer PENALTY_MFA_BELOW_THRESHOLD = 10;

  public static AccModel.SecuritySection build(Decimal mfaAdoption) {
    AccModel.SecuritySection section = new AccModel.SecuritySection();

    Integer profiles = AccQuery.countOrNull('SELECT COUNT() FROM Profile');
    Integer permissionSets = AccQuery.countOrNull(
      'SELECT COUNT() FROM PermissionSet WHERE IsOwnedByProfile = false'
    );
    Integer permissionSetGroups = AccQuery.countOrNull(
      'SELECT COUNT() FROM PermissionSetGroup'
    );
    Integer publicGroups = AccQuery.countOrNull(
      'SELECT COUNT() FROM Group WHERE Type = \'Regular\''
    );
    Integer roles = AccQuery.countOrNull('SELECT COUNT() FROM UserRole');

    section.inventory.add(inventory('Profiles', profiles, 'utility:user'));
    section.inventory.add(
      inventory('Permission Sets', permissionSets, 'utility:groups')
    );
    section.inventory.add(
      inventory(
        'Permission Set Groups',
        permissionSetGroups,
        'utility:socialshare'
      )
    );
    section.inventory.add(
      inventory('Public Groups', publicGroups, 'utility:people')
    );
    section.inventory.add(inventory('Roles', roles, 'utility:hierarchy'));

    AccModel.Tile sharingRules = new AccModel.Tile(
      'Sharing Rules',
      'Sharing Rules',
      'N/A',
      AccStatus.INFO
    );
    sharingRules.icon = 'utility:share';
    sharingRules.unavailable = true;
    sharingRules.tooltip = 'Data Unavailable: sharing rules are Metadata API components and cannot be queried from Apex.';
    section.inventory.add(sharingRules);

    /* --- high-risk permission grants (real) --------------------------- */

    Integer modifyAll = distinctAssignees('PermissionsModifyAllData');
    Integer viewAll = distinctAssignees('PermissionsViewAllData');
    Integer riskyPermissionSets = AccQuery.countOrNull(
      'SELECT COUNT() FROM PermissionSet WHERE IsOwnedByProfile = false AND PermissionsModifyAllData = true'
    );
    Integer godModeProfiles = AccQuery.countOrNull(
      'SELECT COUNT() FROM PermissionSet WHERE IsOwnedByProfile = true AND PermissionsModifyAllData = true'
    );
    Integer privilegedWithoutMfa = privilegedWithoutMfa();

    section.alerts.add(
      alertTile('s1', 'Users with Modify All Data', modifyAll)
    );
    section.alerts.add(alertTile('s2', 'Users with View All Data', viewAll));
    section.alerts.add(unavailableAlert('s3', 'Expired Certificates'));
    section.alerts.add(unavailableAlert('s4', 'Certificates Expiring Soon'));
    section.alerts.add(
      alertTile('s5', 'MFA Not Enabled', privilegedWithoutMfa)
    );

    /* --- subsystem statuses, each from a concrete signal -------------- */

    section.subsystems.add(
      subsystem(
        'Profiles',
        godModeProfiles == null
          ? AccStatus.INFO
          : (godModeProfiles <= 1 ? AccStatus.HEALTHY : AccStatus.WARNING),
        godModeProfiles == null
          ? 'Profile permissions could not be read.'
          : godModeProfiles + ' profile(s) grant Modify All Data.'
      )
    );
    section.subsystems.add(
      subsystem(
        'Permission Sets',
        riskyPermissionSets == null
          ? AccStatus.INFO
          : (riskyPermissionSets == 0 ? AccStatus.HEALTHY : AccStatus.WARNING),
        riskyPermissionSets == null
          ? 'Permission set permissions could not be read.'
          : riskyPermissionSets + ' permission set(s) grant Modify All Data.'
      )
    );

    AccModel.Tile sharingSubsystem = subsystem(
      'Sharing Rules',
      AccStatus.INFO,
      'Data Unavailable: sharing rules require Metadata API access.'
    );
    sharingSubsystem.unavailable = true;
    sharingSubsystem.value = 'N/A';
    section.subsystems.add(sharingSubsystem);

    section.subsystems.add(
      subsystem(
        'Login Security',
        mfaAdoption == null
          ? AccStatus.INFO
          : AccStatus.fromScore(
              mfaAdoption,
              AccStatus.MFA_HEALTHY,
              AccStatus.MFA_WARNING
            ),
        mfaAdoption == null
          ? 'MFA enrolment could not be read.'
          : 'MFA adoption is ' + AccStatus.percentLabel(mfaAdoption) + '.'
      )
    );

    /* --- score -------------------------------------------------------- */

    Integer deduction = 0;
    List<String> ledger = new List<String>();

    if (riskyPermissionSets != null && riskyPermissionSets > 0) {
      Integer points = riskyPermissionSets * PENALTY_HIGH_RISK_PERMISSION;
      deduction += points;
      ledger.add(
        riskyPermissionSets + ' high-risk permission set(s) -' + points
      );
    }
    if (mfaAdoption != null && mfaAdoption < AccStatus.MFA_WARNING) {
      deduction += PENALTY_MFA_BELOW_THRESHOLD;
      ledger.add(
        'MFA adoption below ' +
          AccStatus.MFA_WARNING +
          '% -' +
          PENALTY_MFA_BELOW_THRESHOLD
      );
    }

    Decimal score = Math.max(0, 100 - deduction);
    section.score = score;
    section.status = AccStatus.fromScore(score);

    String tooltip = 'Security health ' + score + '/100.';
    if (!ledger.isEmpty()) {
      tooltip += ' Deductions: ' + String.join(ledger, ', ') + '.';
    }
    tooltip += ' Certificate checks are excluded - they require Metadata API access.';

    section.donut = new AccModel.Donut(
      score,
      section.status == AccStatus.HEALTHY
        ? 'Good'
        : AccStatus.label(section.status),
      section.status,
      tooltip
    );

    return section;
  }

  /* ==========================================================================
   * Helpers
   * ========================================================================== */

  /** Distinct active users granted a permission, via any permission set. */
  private static Integer distinctAssignees(String permissionField) {
    try {
      List<AggregateResult> results = (List<AggregateResult>) Database.query(
        'SELECT COUNT_DISTINCT(AssigneeId) total FROM PermissionSetAssignment ' +
          'WHERE PermissionSet.' +
          String.escapeSingleQuotes(permissionField) +
          ' = true AND Assignee.IsActive = true'
      );
      return results.isEmpty() ? 0 : (Integer) results[0].get('total');
    } catch (Exception e) {
      return null;
    }
  }

  private static Integer privilegedWithoutMfa() {
    if (!AccQuery.isQueryable('TwoFactorMethodsInfo')) {
      return null;
    }
    Set<Id> mfaUsers = AccQuery.distinctIds('TwoFactorMethodsInfo', 'UserId');
    Set<Id> privileged = new Set<Id>();
    for (PermissionSetAssignment assignment : [
      SELECT AssigneeId
      FROM PermissionSetAssignment
      WHERE
        PermissionSet.PermissionsModifyAllData = TRUE
        AND Assignee.IsActive = TRUE
      LIMIT 50000
    ]) {
      privileged.add(assignment.AssigneeId);
    }

    Integer missing = 0;
    for (Id userId : privileged) {
      if (!mfaUsers.contains(userId)) {
        missing++;
      }
    }
    return missing;
  }

  private static AccModel.Tile inventory(
    String label,
    Integer value,
    String icon
  ) {
    AccModel.Tile tile = new AccModel.Tile(
      label,
      label,
      value == null ? 'N/A' : AccStatus.number(value),
      AccStatus.INFO
    );
    tile.icon = icon;
    tile.unavailable = value == null;
    if (value == null) {
      tile.tooltip = 'Data Unavailable: this object is not readable by the running user.';
    }
    return tile;
  }

  private static AccModel.Tile alertTile(
    String id,
    String label,
    Integer count
  ) {
    AccModel.Tile tile = new AccModel.Tile(
      id,
      label,
      count == null ? 'N/A' : String.valueOf(count),
      count == null || count == 0 ? AccStatus.HEALTHY : AccStatus.CRITICAL
    );
    tile.count = count;
    tile.unavailable = count == null;
    return tile;
  }

  private static AccModel.Tile unavailableAlert(String id, String label) {
    AccModel.Tile tile = new AccModel.Tile(id, label, 'N/A', AccStatus.INFO);
    tile.unavailable = true;
    tile.tooltip = 'Data Unavailable: certificates are Metadata API components and cannot be queried from Apex.';
    return tile;
  }

  private static AccModel.Tile subsystem(
    String label,
    String status,
    String tooltip
  ) {
    AccModel.Tile tile = new AccModel.Tile(
      label,
      label,
      AccStatus.label(status),
      status
    );
    tile.tooltip = tooltip;
    return tile;
  }
}
