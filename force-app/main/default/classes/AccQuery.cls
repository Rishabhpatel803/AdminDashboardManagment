/**
 * AccQuery - defensive query helpers.
 *
 * Several objects the command center reads (LoginHistory, UserLogin,
 * TwoFactorMethodsInfo, SetupAuditTrail, FlowDefinitionView, ExternalCredential)
 * throw for orgs where the object is unavailable or the running admin lacks the
 * permission. A single failing metric must never blank the whole page, so every
 * risky read goes through here and returns null, which the UI renders as the
 * specification's "Data Unavailable" state.
 */
public with sharing class AccQuery {
  /** COUNT() query that yields null instead of throwing. */
  public static Integer countOrNull(String soql) {
    try {
      return Database.countQuery(soql);
    } catch (Exception e) {
      return null;
    }
  }

  /** Dynamic query that yields an empty list instead of throwing. */
  public static List<SObject> queryOrEmpty(String soql) {
    try {
      return Database.query(soql);
    } catch (Exception e) {
      return new List<SObject>();
    }
  }

  /** True when the object exists in this org and is queryable by this user. */
  public static Boolean isQueryable(String sobjectName) {
    try {
      Schema.SObjectType token = Schema.getGlobalDescribe().get(sobjectName);
      if (token == null) {
        return false;
      }
      return token.getDescribe().isQueryable() &&
        token.getDescribe().isAccessible();
    } catch (Exception e) {
      return false;
    }
  }

  /** Distinct Id values for a field, tolerating objects that reject aggregates. */
  public static Set<Id> distinctIds(String sobjectName, String fieldName) {
    Set<Id> ids = new Set<Id>();
    if (!isQueryable(sobjectName)) {
      return ids;
    }
    for (
      SObject row : queryOrEmpty(
        'SELECT ' +
          String.escapeSingleQuotes(fieldName) +
          ' FROM ' +
          String.escapeSingleQuotes(sobjectName) +
          ' LIMIT 50000'
      )
    ) {
      Object value = row.get(fieldName);
      if (value != null) {
        ids.add((Id) value);
      }
    }
    return ids;
  }
}
