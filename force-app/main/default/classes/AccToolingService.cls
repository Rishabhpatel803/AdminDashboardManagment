/**
 * AccToolingService - self-callout bridge to this org's own Tooling API.
 *
 * ApexOrgWideCoverage and DeployRequest are Tooling API objects; Apex SOQL
 * (Database.query) cannot see them at all - querying either raises
 * "Entity is not supported". The Tooling REST API can, so this class calls
 * this SAME org's own Tooling endpoint over HTTP, authenticated with the
 * running user's own session.
 *
 * UserInfo.getSessionId() returns a usable session only when Apex executes
 * inside an authenticated UI context (Lightning/Aura/LWC or Visualforce) -
 * it is null for pure API, Batch, Queueable, Scheduled or trigger contexts.
 * Since this is called from the Admin Command Center LWC inside Lightning
 * Experience, a session is expected to be present; every call is still
 * wrapped so a missing session degrades to a specific, actionable message
 * instead of breaking the page.
 */
public with sharing class AccToolingService {
  private static final String API_VERSION = 'v67.0';

  public class ToolingException extends Exception {
  }

  /**
   * Runs a Tooling API SOQL query and returns its "records" array as loosely
   * typed maps. Throws ToolingException with a specific, actionable reason
   * on any failure - callers decide how to degrade.
   */
  public static List<Object> query(String soql) {
    String sessionId = UserInfo.getSessionId();
    if (String.isBlank(sessionId)) {
      throw new ToolingException(
        'No active UI session is available to Apex (UserInfo.getSessionId() is blank). ' +
          'This happens outside Lightning/Visualforce context; reload the Admin Command Center page in Lightning Experience.'
      );
    }

    String domain;
    try {
      domain = Url.getOrgDomainUrl().toExternalForm();
    } catch (Exception e) {
      throw new ToolingException('Could not resolve this org\'s domain: ' + e.getMessage());
    }

    String endpoint =
      domain + '/services/data/' + API_VERSION + '/tooling/query/?q=' + EncodingUtil.urlEncode(soql, 'UTF-8');

    HttpRequest request = new HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod('GET');
    request.setHeader('Authorization', 'Bearer ' + sessionId);
    request.setHeader('Content-Type', 'application/json');
    request.setTimeout(15000);

    HttpResponse response;
    try {
      response = new Http().send(request);
    } catch (Exception e) {
      throw new ToolingException('Tooling API callout failed: ' + e.getMessage());
    }

    if (response.getStatusCode() != 200) {
      throw new ToolingException(
        'Tooling API returned HTTP ' +
          response.getStatusCode() +
          ': ' +
          truncate(response.getBody(), 200)
      );
    }

    Map<String, Object> body;
    try {
      body = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    } catch (Exception e) {
      throw new ToolingException('Could not parse the Tooling API response: ' + e.getMessage());
    }

    Object records = body.get('records');
    return records instanceof List<Object> ? (List<Object>) records : new List<Object>();
  }

  /** Best-effort query: returns an empty list instead of throwing. Callers that
   *  need to distinguish "no data" from "could not ask" should call query()
   *  directly and catch ToolingException themselves. */
  public static List<Object> queryOrEmpty(String soql) {
    try {
      return query(soql);
    } catch (Exception e) {
      return new List<Object>();
    }
  }

  private static String truncate(String text, Integer maxLength) {
    if (text == null) {
      return '';
    }
    return text.length() > maxLength ? text.substring(0, maxLength) + '...' : text;
  }
}
