/*
    Copyright (c) 2009,2012, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2011,2012
* @description Enum for triggers and static utils for settings and collections
*/
public class Relationships_Utils {
	private static Relationship_Settings__c RelationshipSettings;
	
	public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
    
    public static Relationship_Settings__c getRelationshipSettings(){
        if (RelationshipSettings == null){
            RelationshipSettings = Relationship_Settings__c.getOrgDefaults();
            
            //if we don't have org defaults...
            if (RelationshipSettings.Id == null){
                RelationshipSettings = new Relationship_Settings__c(
                    Reciprocal_Method__c = 'List Setting'
                );
                insert RelationshipSettings;	
            }
        }	
    	return RelationshipSettings;
    }    

    private static Map<String, Relationship_Auto_Create__c> AutoCreateMap;
    public static Map<String, Relationship_Auto_Create__c> getAutoCreateMap(){
    	if(AutoCreateMap == null){
    		AutoCreateMap = Relationship_Auto_Create__c.getAll();
    	}
    	return AutoCreateMap;
    }    
    private static Boolean contactAutoCreate;
    public static Boolean hasContactAutoCreate{get{
        if (contactAutoCreate == null){
            for(String s : getAutoCreateMap().keySet()){
        	   if (getAutoCreateMap().get(s).Object__c == 'Contact'){
        	       contactAutoCreate = true;
        	       break;
        	   }        		
        	}     
        	if (contactAutoCreate != true)contactAutoCreate = false;   	
        }	    	
        return contactAutoCreate;	
    }}
    
    private static Boolean cmAutoCreate;
    public static Boolean hasCMAutoCreate{get{
        if (cmAutoCreate == null){
        	for(String s : getAutoCreateMap().keySet()){
        		if(getAutoCreateMap().get(s).Object__c == 'CampaignMember'){
        			cmAutoCreate = true;
        			break;
        		}
        	}
            if (cmAutoCreate != true)cmAutoCreate = false;
        }	
    	return cmAutoCreate;
    }}
    
    public static Relationship_Error__c createRelationshipError(Database.SaveResult s, Relationship__c r){
        Relationship_Error__c re = new Relationship_Error__c();
        re.Error_Date_Time__c = system.now();
        
        string recordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/';
        
        if (s.getId() != null)
            recordURL += s.getId();
        else            
            recordURL += r.ReciprocalRelationship__c;
                     
        if (recordURL.startsWith('http:')){
            recordURL = recordURL.replaceFirst('http:', 'https:');
        }            
        re.Error_Record_Link__c = recordURL; 
        
        if (s.getErrors()[0].getStatusCode() == system.Statuscode.REQUIRED_FIELD_MISSING){
            re.Error_Type__c = 'Required Field Missing';   
        }
        else if (s.getErrors()[0].getStatusCode() == system.Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION){
            re.Error_Type__c = 'Custom Validation Rule Failed';
        }
        else{
            re.Error_Type__c = 'Other';
        }
        
        //trim error message
        if (s.getErrors()[0].getMessage().length() > 255)
            re.Full_Error_Message__c = s.getErrors()[0].getMessage().substring(0, 254);
        else
            re.Full_Error_Message__c = s.getErrors()[0].getMessage();
    
        return re;
    }
    
    //modified csv parser to load initial static resource for recip settings
    //http://wiki.developerforce.com/page/Code_Samples#Parse_a_CSV_with_APEX
    public static List<List<String>> parseCSV(String contents,Boolean skipHeaders) {
	    List<List<String>> allFields = new List<List<String>>();
	
	    // replace instances where a double quote begins a field containing a comma
	    // in this case you get a double quote followed by a doubled double quote
	    // do this for beginning and end of a field
	    contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
	    // now replace all remaining double quotes - we do this so that we can reconstruct
	    // fields with commas inside assuming they begin and end with a double quote
	    contents = contents.replaceAll('""','DBLQT');
	    // we are not attempting to handle fields with a newline inside of them
	    // so, split on newline to get the spreadsheet rows
	    List<String> lines = new List<String>();
	    try {
	        lines = contents.split('\n');
	    } catch (System.ListException e) {
	        System.debug('Limits exceeded?' + e.getMessage());
	    }
	    Integer num = 0;
	    for(String line : lines) {
	        // check for blank CSV lines (only commas)
	        if (line.replaceAll(',','').trim().length() == 0) break;
	        
	        List<String> fields = line.split(',');  
	        List<String> cleanFields = new List<String>();
	        String compositeField;
	        Boolean makeCompositeField = false;
	        for(String field : fields) {
                cleanFields.add(field.replaceAll('DBLQT','"'));	            
	        }
	        
	        allFields.add(cleanFields);
	    }
	    if (skipHeaders) allFields.remove(0);
	    return allFields;       
    }
}