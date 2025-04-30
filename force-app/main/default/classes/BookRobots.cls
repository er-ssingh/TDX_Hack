public with sharing class BookRobots {

    public class BookingInput {
        @InvocableVariable(required=true)
        public Id contactId;
        
        @InvocableVariable(required=true)
        public Decimal longitude;  // Full address string to geocode
        
        @InvocableVariable(required=true)
       	public Decimal latitude;  // Full address string to geocode

    }

    public class BookingOutput {
        @InvocableVariable
        public Id orderId;

        @InvocableVariable
        public String statusMessage;
    }

    @InvocableMethod(label='Book Closest Robotic Car' description='Finds the closest Robotic Car to the contact and creates an order.')
    public static List<BookingOutput> bookClosestCar(List<BookingInput> inputs) {
        List<BookingOutput> results = new List<BookingOutput>();

        for (BookingInput input : inputs) {
            BookingOutput output = new BookingOutput();

            try {
                // Step 1: Get Contact's coordinates and contact info
                Contact con = [
                    SELECT Id, FirstName, MobilePhone, 
                           Geo_Location__Latitude__s, Geo_Location__Longitude__s 
                    FROM Contact 
                    WHERE Id = :input.contactId 
                    LIMIT 1
                ];

                if (con.Geo_Location__Latitude__s == null || con.Geo_Location__Longitude__s == null) {
                    output.statusMessage = 'Contact does not have valid location coordinates.';
                    results.add(output);
                    continue;
                }

                // Step 2: Query closest Robotic Car
                List<Robotic_Car__c> nearbyCars = [
                    SELECT Id 
                    FROM Robotic_Car__c 
                    WHERE DISTANCE(Geo_Location__c, GEOLOCATION(:con.Geo_Location__Latitude__s, :con.Geo_Location__Longitude__s), 'km') < 50
                    ORDER BY DISTANCE(Geo_Location__c, GEOLOCATION(:con.Geo_Location__Latitude__s, :con.Geo_Location__Longitude__s), 'km')
                    LIMIT 1
                ];

                if (nearbyCars.isEmpty()) {
                    output.statusMessage = 'No nearby Robotic Car found within 50 km.';
                } else {
                    // Step 3: Create Order
                    Robotic_Car_Order__c order = new Robotic_Car_Order__c(
                        Contact__c = con.Id,
                        Robotic_Car__c = nearbyCars[0].Id,
                        Date_Time_of_Order__c = Date.today(),
                        Status__c = 'On Going',
                        Destination_Geo_Location__Latitude__s = input.latitude,
                        Destination_Geo_Location__Longitude__s = input.latitude
                        
                    );
                    insert order;

                    output.orderId = order.Id;
                    output.statusMessage = 'Order created successfully! ';
                    
                    // Step 4: Send mobile number notification
                    if (isValidMobile(con.MobilePhone)) {
                        String cleanedNumber = con.MobilePhone.replaceAll('[^0-9]', '');
                        String lastTenDigits = cleanedNumber.substring(cleanedNumber.length() - 10);

                        System.debug(lastTenDigits);


                        ThinkSpeakChannel2.sendMobileNumber(
                            lastTenDigits, 
                            con.FirstName
                        );
                        output.statusMessage += 'Information About your Contact Number Also Sent to the Robot Successfully';
                    } else {
                        output.statusMessage += ' Invalid mobile number - notification not sent.';
                    }
                }
            } catch (Exception e) {
                output.statusMessage = 'Error: ' + e.getMessage();
            }

            results.add(output);
        }

        return results;
    }

    private static Boolean isValidMobile(String mobileNumber) {
        System.Debug(mobileNumber);
        return String.isNotBlank(mobileNumber);
    }
}