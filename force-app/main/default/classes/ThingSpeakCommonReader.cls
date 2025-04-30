public class ThingSpeakCommonReader {
    private static final String API_KEY = 'DSM62AI9PULXIVFM'; // Read API key
    private static final String WRITE_API_KEY = '51B4UP22H6EL0LUX';

    private static final String CHANNEL_ID = '1059894'; // Replace with your Channel ID
    private static final String ENDPOINT_URL = 'https://api.thingspeak.com/channels/' + CHANNEL_ID + '/feeds.json';
    
    private static final String FIXED_COMMON_VALUE = '200';
    private static final String ENDPOINT1_URL = 'https://api.thingspeak.com/update';

    @future(callout=true)
    public static void send199Value() {
        // Build parameters with fixed common value and empty other fields
        Map<String, String> params = new Map<String, String>{
            'api_key' => WRITE_API_KEY,
            'field5' => FIXED_COMMON_VALUE,
            'field2' => '',
            'field3' => '',
            'field4' => '',
            'field6' => '',
            'field7' => '',
            'field8' => ''
        };

        // Construct URL
        String queryString = '';
        for(String key : params.keySet()) {
            queryString += '&' + key + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8');
        }
        String fullUrl = ENDPOINT1_URL + '?' + queryString.substring(1);

        // Create and send request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(fullUrl);
        req.setMethod('POST');
        req.setTimeout(120000);

        try {
            HttpResponse res = new Http().send(req);
            handleResponse1(res);
        } catch(Exception e) {
            System.debug('Error sending 199: ' + e.getMessage());
        }
    }

    private static void handleResponse1(HttpResponse res) {
        if(res.getStatusCode() == 200) {
            System.debug('Successfully sent 199. Response: ' + res.getBody());
        } else {
            System.debug('Failed to send 199. Status: ' + res.getStatusCode());
        }
    }

    @future(callout=true)
    public static void readLatestValues() {
        // Parameters to get the most recent entry
        Map<String, String> params = new Map<String, String>{
            'api_key' => API_KEY,
            'results' => '1' // Fetch the latest entry
        };

        // Build the query string
        String queryString = '';
        for (String key : params.keySet()) {
            queryString += '&' + key + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8');
        }
        String fullUrl = ENDPOINT_URL + '?' + queryString.substring(1); // Remove leading '&'

        // Create and configure the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(fullUrl);
        req.setMethod('GET');
        req.setTimeout(12000); // Timeout in milliseconds

        try {
            HttpResponse res = new Http().send(req);
            handleResponse(res);
        } catch (Exception e) {
            System.debug('Error reading data: ' + e.getMessage());
        }
    }

    private static void handleResponse(HttpResponse res) {
        if (res.getStatusCode() == 200) {
            System.debug('Raw Response: ' + res.getBody());
            
            // Parse the JSON response
            try {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> feeds = (List<Object>) responseMap.get('feeds');
                
                if (feeds != null && !feeds.isEmpty()) {
                    Map<String, Object> latestEntry = (Map<String, Object>) feeds.get(0);
                    System.debug('Latest Entry Details:');
                    System.debug('Timestamp: ' + latestEntry.get('created_at'));
                    System.debug('Field5 (Fixed Value): ' + latestEntry.get('field5')); // Field from sender code
                    // Add other fields as needed (field2, field3, etc.)
                }
            } catch (Exception e) {
                System.debug('JSON Parsing Error: ' + e.getMessage());
            }
        } else {
            System.debug('Request Failed. Status Code: ' + res.getStatusCode());
        }
    }
}