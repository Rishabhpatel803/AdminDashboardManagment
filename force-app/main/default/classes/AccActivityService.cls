/**
 * Section 13 - Recent Admin Activity, sourced from SetupAuditTrail.
 *
 * Limited to the specification's 5 most recent entries, most recent first.
 */
public with sharing class AccActivityService {
  private static final Integer LIMIT_ROWS = 5;

  private static final Map<String, String> ICON_BY_SECTION = new Map<String, String>{
    'Manage Users' => 'utility:adduser',
    'Security' => 'utility:lock',
    'Sharing Rules' => 'utility:share',
    'Manage Flow' => 'utility:flow',
    'Deployments' => 'utility:upload',
    'Companies' => 'utility:company'
  };

  public static List<AccModel.Activity> build() {
    List<AccModel.Activity> activity = new List<AccModel.Activity>();

    List<SetupAuditTrail> rows;
    try {
      rows = [
        SELECT CreatedDate, Action, Section, Display, CreatedBy.Name
        FROM SetupAuditTrail
        ORDER BY CreatedDate DESC
        LIMIT :LIMIT_ROWS
      ];
    } catch (Exception e) {
      return activity;
    }

    for (SetupAuditTrail row : rows) {
      AccModel.Activity item = new AccModel.Activity();
      item.id = String.valueOf(row.CreatedDate.getTime()) + '-' + row.Action;
      item.timeLabel = row.CreatedDate.format('hh:mm a');
      item.action = humanizeAction(row.Action);
      item.target = String.isBlank(row.Display)
        ? (row.CreatedBy != null ? row.CreatedBy.Name : '-')
        : row.Display;
      item.icon = ICON_BY_SECTION.containsKey(row.Section)
        ? ICON_BY_SECTION.get(row.Section)
        : 'utility:activity';
      item.status = AccStatus.INFO;
      activity.add(item);
    }
    return activity;
  }

  /** SetupAuditTrail.Action is a compact code, e.g. "createduser" - spaced out for display. */
  private static String humanizeAction(String action) {
    if (String.isBlank(action)) {
      return 'Configuration Changed';
    }
    String spaced = action.replaceAll('([a-z])([A-Z])', '$1 $2')
      .replace('_', ' ');
    return spaced.substring(0, 1).toUpperCase() + spaced.substring(1);
  }
}
