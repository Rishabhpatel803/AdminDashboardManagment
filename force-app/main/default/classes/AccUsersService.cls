/**
 * Section 2 - Users & Access Overview, sourced from User, LoginHistory,
 * UserLogin, TwoFactorMethodsInfo and PermissionSetAssignment.
 */
public with sharing class AccUsersService {
  /** Spec Sec 2: "Inactive for 60+ Days" alert window. */
  private static final Integer STALE_LOGIN_DAYS = 60;

  public static AccModel.UsersSection build() {
    AccModel.UsersSection section = new AccModel.UsersSection();

    Integer active = [SELECT COUNT() FROM User WHERE IsActive = TRUE];
    Integer inactive = [SELECT COUNT() FROM User WHERE IsActive = FALSE];
    Integer logins = loginsToday();
    Integer locked = lockedUsers();

    Set<Id> mfaUsers = AccQuery.distinctIds('TwoFactorMethodsInfo', 'UserId');
    Boolean mfaAvailable = AccQuery.isQueryable('TwoFactorMethodsInfo');

    Integer mfaActive = 0;
    if (mfaAvailable && !mfaUsers.isEmpty()) {
      mfaActive = [
        SELECT COUNT()
        FROM User
        WHERE IsActive = TRUE AND Id IN :mfaUsers
      ];
    }

    /* --- KPI tiles ---------------------------------------------------- */

    section.kpis.add(
      new AccModel.Tile(
        'active',
        'Active Users',
        AccStatus.number(active),
        AccStatus.HEALTHY
      )
    );

    AccModel.Tile inactiveTile = new AccModel.Tile(
      'inactive',
      'Inactive Users',
      AccStatus.number(inactive),
      AccStatus.INFO
    );
    section.kpis.add(inactiveTile);

    section.kpis.add(
      counted(
        'logins',
        'Logins Today',
        logins,
        AccStatus.INFO,
        'LoginHistory is not readable by this user.'
      )
    );

    AccModel.Tile lockedTile = counted(
      'locked',
      'Locked Users',
      locked,
      locked != null && locked > 0 ? AccStatus.CRITICAL : AccStatus.HEALTHY,
      'UserLogin is not readable by this user.'
    );
    section.kpis.add(lockedTile);

    /*
     * Password expiry policy lives in SecuritySettings metadata and is not
     * exposed to SOQL, so this KPI cannot be calculated from the org.
     */
    AccModel.Tile passwords = new AccModel.Tile(
      'passwords',
      'Passwords Expiring Soon',
      'N/A',
      AccStatus.INFO
    );
    passwords.wide = true;
    passwords.unavailable = true;
    passwords.tooltip = 'Data Unavailable: the password expiry policy is stored in SecuritySettings metadata and cannot be queried from Apex.';
    section.kpis.add(passwords);

    AccModel.Tile mfaTile;
    if (mfaAvailable) {
      Decimal adoption = AccStatus.percent(mfaActive, active);
      section.mfaAdoption = adoption;
      mfaTile = new AccModel.Tile(
        'mfa',
        'MFA Adoption',
        AccStatus.percentLabel(adoption),
        AccStatus.fromScore(
          adoption,
          AccStatus.MFA_HEALTHY,
          AccStatus.MFA_WARNING
        )
      );
      mfaTile.tooltip =
        AccStatus.number(mfaActive) +
        ' of ' +
        AccStatus.number(active) +
        ' active users have a registered MFA method.';
    } else {
      mfaTile = new AccModel.Tile('mfa', 'MFA Adoption', 'N/A', AccStatus.INFO);
      mfaTile.unavailable = true;
      mfaTile.tooltip = 'Data Unavailable: TwoFactorMethodsInfo is not readable in this org.';
    }
    mfaTile.wide = true;
    section.kpis.add(mfaTile);

    /* --- Admin Alerts panel ------------------------------------------- */

    section.alerts.add(
      alert('ua1', 'Users Locked Out', locked, AccStatus.CRITICAL)
    );
    section.alerts.add(
      alert('ua2', 'Inactive for 60+ Days', staleLogins(), AccStatus.WARNING)
    );

    Integer privilegedWithoutMfa = mfaAvailable
      ? privilegedWithoutMfa(mfaUsers)
      : null;
    AccModel.Tile mfaAlert = alert(
      'ua3',
      'Users Without MFA',
      privilegedWithoutMfa,
      AccStatus.CRITICAL
    );
    mfaAlert.tooltip = 'Active users with Modify All Data that have no registered MFA method.';
    section.alerts.add(mfaAlert);

    section.status = AccStatus.worst(
      new List<String>{
        lockedTile.status,
        mfaTile.unavailable == true ? AccStatus.INFO : mfaTile.status
      }
    );
    return section;
  }

  /* ==========================================================================
   * Individual metrics
   * ========================================================================== */

  private static Integer loginsToday() {
    Integer viaCount = AccQuery.countOrNull(
      'SELECT COUNT() FROM LoginHistory WHERE LoginTime = TODAY AND Status = \'Success\''
    );
    if (viaCount != null) {
      return viaCount;
    }
    // LoginHistory rejects COUNT() in some orgs; fall back to a bounded scan.
    if (!AccQuery.isQueryable('LoginHistory')) {
      return null;
    }
    List<SObject> rows = AccQuery.queryOrEmpty(
      'SELECT Id FROM LoginHistory WHERE LoginTime = TODAY AND Status = \'Success\' LIMIT 50000'
    );
    return rows.isEmpty() && !AccQuery.isQueryable('LoginHistory')
      ? null
      : rows.size();
  }

  private static Integer lockedUsers() {
    return AccQuery.countOrNull(
      'SELECT COUNT() FROM UserLogin WHERE IsPasswordLocked = TRUE'
    );
  }

  private static Integer staleLogins() {
    Datetime cutoff = Datetime.now().addDays(-STALE_LOGIN_DAYS);
    try {
      return [
        SELECT COUNT()
        FROM User
        WHERE
          IsActive = TRUE
          AND (LastLoginDate < :cutoff
          OR LastLoginDate = NULL)
      ];
    } catch (Exception e) {
      return null;
    }
  }

  /** Active users holding Modify All Data with no registered MFA method. */
  private static Integer privilegedWithoutMfa(Set<Id> mfaUsers) {
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

  /* ==========================================================================
   * Tile builders
   * ========================================================================== */

  private static AccModel.Tile counted(
    String id,
    String label,
    Integer value,
    String status,
    String unavailableReason
  ) {
    if (value == null) {
      AccModel.Tile tile = new AccModel.Tile(id, label, 'N/A', AccStatus.INFO);
      tile.unavailable = true;
      tile.tooltip = 'Data Unavailable: ' + unavailableReason;
      return tile;
    }
    return new AccModel.Tile(id, label, AccStatus.number(value), status);
  }

  private static AccModel.Tile alert(
    String id,
    String label,
    Integer count,
    String status
  ) {
    AccModel.Tile tile = new AccModel.Tile(
      id,
      label,
      count == null ? 'N/A' : String.valueOf(count),
      count == null || count == 0 ? AccStatus.HEALTHY : status
    );
    tile.count = count;
    tile.unavailable = count == null;
    return tile;
  }
}
