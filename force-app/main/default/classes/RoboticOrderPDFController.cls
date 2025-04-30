public with sharing class RoboticOrderPDFController {
    public static void generatePDFAndAttach(Id orderId) {
        Robotic_Car_Order__c order = [
            SELECT Name, Contact__c, Amount_To_Be_Paid__c,
                   Contact__r.Email, Contact__r.FirstName, Contact__r.Wallet_Amount__c
            FROM Robotic_Car_Order__c
            WHERE Id = :orderId
            LIMIT 1
        ];

        try {
            if (order.Contact__c == null || String.isBlank(order.Contact__r.Email)) {
                System.debug('No Contact or Contact Email found. Skipping PDF generation/email.');
                return;
            }

            // Step 1: Calculate updated wallet amount
            Decimal currentWallet = order.Contact__r.Wallet_Amount__c != null ? order.Contact__r.Wallet_Amount__c : 0;
            Decimal amountToDeduct = order.Amount_To_Be_Paid__c != null ? order.Amount_To_Be_Paid__c : 0;
            Decimal updatedWalletBalance = currentWallet - amountToDeduct;

            // Step 2: Update Contact and Order with calculated wallet values
            Contact updatedContact = new Contact(
                Id = order.Contact__c,
                Wallet_Amount__c = updatedWalletBalance
            );

            Robotic_Car_Order__c updatedOrder = new Robotic_Car_Order__c(
                Id = order.Id,
                Available_Wallet_Amount1__c = updatedWalletBalance,
                Is_Wallet_Updated__c = true
            );

            update new List<SObject>{ updatedContact, updatedOrder };

            // Step 3: Re-fetch updated Order record to ensure PDF has latest wallet value
            order = [
                SELECT Name, Contact__c, Available_Wallet_Amount1__c,
                       Contact__r.Email, Contact__r.FirstName
                FROM Robotic_Car_Order__c
                WHERE Id = :orderId
                LIMIT 1
            ];

            // Step 4: Generate PDF
            PageReference pdfPage = Page.RoboticCarOrder;
            pdfPage.getParameters().put('id', order.Id);
            Blob pdfBlob = pdfPage.getContent();
            String fileName = 'RoboticOrder_' + order.Name + '.pdf';

            // Step 5: Attach PDF to Contact
            Attachment attachment = new Attachment();
            attachment.ParentId = order.Contact__c;
            attachment.Name = fileName;
            attachment.Body = pdfBlob;
            attachment.ContentType = 'application/pdf';
            insert attachment;

            // Step 6: Send Personalized Email
            String contactFirstName = order.Contact__r.FirstName != null ? order.Contact__r.FirstName : 'Customer';
            //String bodyText = 'Hello,\n\nHi ' + contactFirstName +
                //'!! Your recently booked Autonomous Robotic Car order details are attached as a PDF in this email.' +
                //'\n\nRegards,\nRobotic Car Team';
            String bodyText = getJourneyConfirmationMessage(order.Id);

            Messaging.EmailFileAttachment pdfAttachment = new Messaging.EmailFileAttachment();
            pdfAttachment.setFileName(fileName);
            pdfAttachment.setBody(pdfBlob);
            pdfAttachment.setContentType('application/pdf');

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { order.Contact__r.Email });
            mail.setSubject('Your Robotic Car Order Details');
            mail.setPlainTextBody(bodyText);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { pdfAttachment });
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

            System.debug('PDF generated and wallet updated successfully.');

        } catch (Exception ex) {
            System.debug('PDF Generation, Attachment, Email or Wallet Update failed: ' + ex.getMessage());
        }
    }
    public static String getJourneyConfirmationMessage(Id orderId) {
    try {
        // Prepare input for prompt template
        ConnectApi.EinsteinPromptTemplateGenerationsInput promptGenerationsInput = 
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();

        // Map for holding input parameters
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        Map<String, String> input = new Map<String, String>();

        // Set only the order ID as required by the prompt template
        input.put('Id', orderId);

        // Add wrapped value
        ConnectApi.WrappedValue inputValueMap = new ConnectApi.WrappedValue();
        inputValueMap.value = input;
        inputParams.put('Input:Order', inputValueMap); // Match this with your prompt template's expected input variable

        // Set hyper parameters
        promptGenerationsInput.inputParams = inputParams;
        promptGenerationsInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        promptGenerationsInput.additionalConfig.numGenerations = 1;
        promptGenerationsInput.additionalConfig.enablePiiMasking = false;
        promptGenerationsInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';

        // Set if it's a preview or not
        promptGenerationsInput.isPreview = false;

        // Call the service to generate messages for the prompt template
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = 
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                'JourneyConfirmation', 
                promptGenerationsInput
            );
        System.debug(generationsOutput.generations[0].text);
        // Return the generated response
        if (generationsOutput.generations != null && !generationsOutput.generations.isEmpty()) {
            return generationsOutput.generations[0].text;
        }

        return null;
        
    } catch (Exception ex) {
        System.debug('Error calling JourneyConfirmation prompt template: ' + ex.getMessage());
        return null;
    }
}

}