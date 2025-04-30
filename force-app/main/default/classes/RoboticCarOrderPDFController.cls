public with sharing class RoboticCarOrderPDFController {
    public String orderTimeIST { get; set; }
    public String orderCompletionTimeIST { get; set; }
    public String formattedCurrentDate { get; set; }

    public RoboticCarOrderPDFController(ApexPages.StandardController stdController) {
        Id orderId = stdController.getId();

        // Use System.now() to get UTC time and let Salesforce convert to the user's time zone automatically
        DateTime istNow = System.now();  // Current time in UTC, Salesforce will convert to user's time zone
        formattedCurrentDate = istNow.format('dd-MMM-yyyy HH:mm:ss'); // Display in user time zone

        if (orderId != null) {
            Robotic_Car_Order__c order = [
                SELECT Id, Date_Time_of_Order__c, Date_Time_of_Order_Completion__c
                FROM Robotic_Car_Order__c
                WHERE Id = :orderId
                LIMIT 1
            ];

            if (order.Date_Time_of_Order__c != null) {
                // Do NOT manually adjust for IST, Salesforce will automatically adjust to user's time zone
                orderTimeIST = order.Date_Time_of_Order__c.format('dd-MMM-yyyy HH:mm:ss'); 
            }

            if (order.Date_Time_of_Order_Completion__c != null) {
                // Same for Order Completion time
                orderCompletionTimeIST = order.Date_Time_of_Order_Completion__c.format('dd-MMM-yyyy HH:mm:ss');
            }
        }
    }
}