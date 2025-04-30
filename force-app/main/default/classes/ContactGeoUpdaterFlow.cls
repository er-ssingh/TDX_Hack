public with sharing class ContactGeoUpdaterFlow {

    // Input structure for Flow or Agentforce
    public class GeoInput {
        @InvocableVariable(required=true)
        public String address;  // Full address string to geocode

        @InvocableVariable(required=true)
        public String registeredAccountNumber;  // Unique field to identify Contact
    }

    // Output structure for Flow response
    public class GeoOutput {
        @InvocableVariable
        public String statusMessage;  // Success or failure message
    }

    /**
     * Main invocable method callable from Flow or Agentforce
     */
    @InvocableMethod(label='Update Contact Geolocation' 
                     description='This action should only be called when you have asked the user about thier destination . It returns geo coordinates of the destination . PLEASE DONt MISTAKE IT')
    public static List<GeoOutput> updateContactGeoFromFlow(List<GeoInput> inputList) {
        List<GeoOutput> responseList = new List<GeoOutput>();

        for (GeoInput input : inputList) {
            GeoOutput output = new GeoOutput();

            System.debug('Received address: ' + input.address);
            System.debug('Registered Account Number: ' + input.registeredAccountNumber);

            // Perform geocoding using Google Maps
            GeoResult geoResult = geocodeAddress(input.address);

            if (!geoResult.success) {
                output.statusMessage = 'Geocoding failed: ' + geoResult.errorMessage;
                System.debug(output.statusMessage);
            } else {
                System.debug('Geocoding success: Lat = ' + geoResult.latitude + ', Lng = ' + geoResult.longitude);

                try {
                    // Query Contact using Registered_Account_Number__c
                    List<Contact> matchedContacts = [
                        SELECT Id, Name 
                        FROM Contact 
                        WHERE Registered_Account_Number__c = :input.registeredAccountNumber 
                        LIMIT 1
                    ];

                    if (matchedContacts.isEmpty()) {
                        output.statusMessage = 'No Contact found for Registered Account Number: ' + input.registeredAccountNumber;
                        System.debug(output.statusMessage);
                    } else {
                        Contact contactToUpdate = matchedContacts[0];
                        System.debug('Updating Contact: ' + contactToUpdate.Name + ' (Id: ' + contactToUpdate.Id + ')');

                        // Update geolocation fields with rounded values
                        contactToUpdate.Geo_Location__Latitude__s = geoResult.latitude;
                        contactToUpdate.Geo_Location__Longitude__s = geoResult.longitude;

                        update contactToUpdate;

                        output.statusMessage = 'Contact updated successfully. Lat: ' + geoResult.latitude + ', Lng: ' + geoResult.longitude;
                        System.debug(output.statusMessage);
                    }
                } catch (Exception ex) {
                    output.statusMessage = 'Error updating contact: ' + ex.getMessage();
                    System.debug(output.statusMessage);
                }
            }

            responseList.add(output);
        }

        return responseList;
    }

    /**
     * Calls Google Geocoding API to convert an address into coordinates
     */
    private static GeoResult geocodeAddress(String address) {
        GeoResult result = new GeoResult();
        System.debug('Initiating geocoding for address: ' + address);

        try {
            // Replace this API key with a secured one in custom settings
            String apiKey = 'AIzaSyDGCs3Mu9GkOZ6rhvbeOIWWWIWfcj95QTM';

            // URL encode the address
            String encodedAddress = EncodingUtil.urlEncode(address, 'UTF-8');
            String endpointUrl = 'https://maps.googleapis.com/maps/api/geocode/json?address=' + encodedAddress + '&key=' + apiKey;

            System.debug('Geocoding request URL: ' + endpointUrl);

            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpointUrl);
            request.setMethod('GET');

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> resultList = (List<Object>) jsonResponse.get('results');

                if (!resultList.isEmpty()) {
                    Map<String, Object> geometry = (Map<String, Object>) ((Map<String, Object>) resultList[0]).get('geometry');
                    Map<String, Object> location = (Map<String, Object>) geometry.get('location');

                    // Round coordinates to 6 decimal places
                    result.latitude = ((Decimal) location.get('lat')).setScale(6);
                    result.longitude = ((Decimal) location.get('lng')).setScale(6);
                    result.success = true;

                    System.debug('Geocoding success. Latitude: ' + result.latitude + ', Longitude: ' + result.longitude);
                } else {
                    result.success = false;
                    result.errorMessage = 'No results returned from geocoding API.';
                    System.debug('Geocoding API returned no results.');
                }
            } else {
                result.success = false;
                result.errorMessage = 'HTTP Error: ' + response.getStatusCode();
                System.debug('HTTP error: ' + response.getStatusCode());
            }
        } catch (Exception ex) {
            result.success = false;
            result.errorMessage = 'Exception during geocoding: ' + ex.getMessage();
            System.debug('Exception during geocoding: ' + ex.getMessage());
        }

        return result;
    }

    /**
     * Internal result structure for geocoding response
     */
    private class GeoResult {
        public Decimal latitude;
        public Decimal longitude;
        public Boolean success;
        public String errorMessage;
    }
}