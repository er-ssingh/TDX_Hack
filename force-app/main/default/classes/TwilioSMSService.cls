public class TwilioSMSService {
    // Twilio credentials — should ideally be stored in Custom Metadata/Custom Settings
    private static final String ACCOUNT_SID = 'AC0da148328b39466e907c6d5bfe252ddb';
    private static final String AUTH_TOKEN = '29baea9343564a5636b42ce14f781517';
    private static final String TWILIO_PHONE_NUMBER = '+19809444195';

    // Wrapper class to accept input from Flow
    public class InputWrapper {
        @InvocableVariable(label='Phone Number' )
        public String phone;//required=true
        
        @InvocableVariable(label='Customer Name')
        public String customerName;

        @InvocableVariable(label='Car Name' )
        public String carName;//required=true
        
        @InvocableVariable(label='Car Number' )
        public String carNumber;//required=true
        
        @InvocableVariable(label='Message' )
        public String message;//required=true


        
        
        
    }

    @InvocableMethod(label='Send Booking Confirmation'
                     description='Send SMS to customer with car booking details.')
    public static void sendSMS(List<InputWrapper> requests) {
        System.debug('requests=====' + requests);
        for (InputWrapper input : requests) {
            try {
                // Build the message
                String messageBody = 'Hello ' + input.customerName + ',\n'+
                                     'This Message is from Salesforce Org.\n'+
                                     'Booking for Autonomous Car \"'+ input.carName + '\",' +  input.carNumber + ' '+
                    				 'has been Successfully Completed.\n'+
                                     'You may Call or send SMS to get Geo Location.\n'+
                                     'Thanks !!';
                // Prepare endpoint
                String endpoint = 'https://api.twilio.com/2010-04-01/Accounts/' + ACCOUNT_SID + '/Messages.json';

                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

                // Basic Auth
                Blob auth = Blob.valueOf(ACCOUNT_SID + ':' + AUTH_TOKEN);
                String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(auth);
                req.setHeader('Authorization', authorizationHeader);

                // Encode request body
                String body = 'To=' + EncodingUtil.urlEncode(input.phone, 'UTF-8') +
                              '&From=' + EncodingUtil.urlEncode(TWILIO_PHONE_NUMBER, 'UTF-8') +
                              '&Body=' + EncodingUtil.urlEncode(input.message, 'UTF-8');
                req.setBody(body);

                // Send the request
                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() != 201) {
                    System.debug('Failed to send SMS: ' + res.getBody());
                } else {
                    System.debug('SMS sent successfully to ' + input.phone);
                }
            } catch (Exception e) {
                System.debug('Exception while sending SMS: ' + e.getMessage());
            }
        }
    }
}