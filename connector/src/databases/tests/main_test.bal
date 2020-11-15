import ballerina/io;
import ballerina/test;
import ballerina/java;


AuthConfig config = {
        baseUrl: BASE_URL,
        masterKey: MASTER_KEY,
        host: HOST,
        apiVersion:API_VERSION
};

@test:Config{
    enable: false

}
function createDB(){


    io:println("--------------Create database------------------------\n\n");

    Databases AzureCosmosClient = new(config);
    
    var result = AzureCosmosClient->createDatabase("heloojava",(),());

     if (result is Database) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }

    io:println("\n\n");

}

//create db with throughput / autoscale


@test:Config{
    enable: false

}
function listAllDB(){

    io:println("--------------List All databases------------------------\n\n");


    Databases AzureCosmosClient = new(config);
    
    var result = AzureCosmosClient->listDatabases();

    if (result is DBList) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }

    io:println("\n\n");
}

@test:Config{
    enable: false

}
function listOneDB(){


    io:println("--------------List one database------------------------\n\n");

    Databases AzureCosmosClient = new(config);
    
    var result = AzureCosmosClient->listOneDatabase("tempdb");

    if (result is Database) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }

    io:println("\n\n");

}

@test:Config{
    enable: false

}
function deleteDB(){

    io:println("--------------Delete one databse------------------------\n\n");


    Databases AzureCosmosClient = new(config);
    
    var result = AzureCosmosClient->deleteDatabase("heloo");

    io:println(result);
   
    io:println("\n\n");

}

@test:Config{
            enable: false

}
function createCollection(){

    io:println("--------------Create Collection-----------------------\n\n");


    Databases AzureCosmosClient = new(config);

    json partitionkey = {  
                            "paths": ["/AccountNumber"], 
                            "kind": "Hash",
                            "Version": 2
                        };
    string throughput = "400";

    var result = AzureCosmosClient->createCollection("tempdb","mycollection1",partitionkey,(),(),());


    if (result is Collection) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }   
    io:println("\n\n");

}

//create collection with autoscale indexing policy and throughput


@test:Config{
    enable: false

}
function getAllCollections(){

    io:println("--------------Get All collections-----------------------\n\n");


    Databases AzureCosmosClient = new(config);

    var result = AzureCosmosClient->getAllCollections("hikall");

    if (result is CollectionList) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }
   
    io:println("\n\n");

}

@test:Config{
        enable: false
}
function getOneCollection(){

    io:println("--------------Get One collections-----------------------\n\n");


    Databases AzureCosmosClient = new(config);

    var result = AzureCosmosClient->getOneCollection("tempdb","tempcoll");

    if (result is Collection) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }
   
    io:println("\n\n");

}

@test:Config{

    enable: false

}
function deleteCollection(){

    io:println("--------------Delete one collection------------------------\n\n");


    Databases AzureCosmosClient = new(config);
    
    var result = AzureCosmosClient->deleteCollection("tempdb","mycollection1");

    io:println(result);
   
    io:println("\n\n");

}

@test:Config{
    enable: false

}
function GetPartitionKeyRanges(){

   io:println("--------------Get partition key------------------------\n\n");


    Databases AzureCosmosClient = new(config);
    
    var result = AzureCosmosClient->getPartitionKeyRanges("tempdb","tempcoll");

    if (result is PartitionKeyList) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }   
    io:println("\n\n");

}


@test:Config{
    enable: false

}
function createDocument(){

    Databases AzureCosmosClient = new(config);

    var uuid = createRandomUUID();

 
    json custom = {
        "LastName": "keeeeeee",  
        "Parents": [  
            {  
            "FamilyName": null,  
            "FirstName": "Thomas"  
            },  
            {  
            "FamilyName": null,  
            "FirstName": "Mary Kay"  
            }  
        ],  
        "Children": [  
            {  
            "FamilyName": null,  
            "FirstName": "Henriette Thaulow",  
            "Gender": "female",  
            "Grade": 5,  
            "Pets": [  
                {  
                "GivenName": "Fluffy"  
                }  
            ]  
            }  
        ],  
        "Address": {  
            "State": "WA",  
            "County": "King",  
            "City": "Seattle"  
        },  
        "IsRegistered": true,
        "AccountNumber": 1234  
    };


    json body = {
            id: uuid.toString()    
    };
        

    json|error finalj =  body.mergeJson(custom);


    if finalj is json{

        var result = AzureCosmosClient->createDocument("hikall","mycollection1",finalj,true,(),<json>custom.AccountNumber);
       
        if result is Document {
            io:println(result);
        } else {
        test:assertFail(msg = result.message());
        }   
            io:println("\n\n");
    }
}

//with indexing or upsert headers


@test:Config{
    enable: false

}
function GetDocumentList(){

   io:println("--------------Get all documents------------------------\n\n");


    Databases AzureCosmosClient = new(config);
    
    var result = AzureCosmosClient->listAllDocuments("tempdb","tempcoll");

    if (result is DocumentList) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }   
    io:println("\n\n");

}

@test:Config{
    enable: false

}
function GetOneDocument(){

   io:println("--------------Get one document------------------------\n\n");

    string documentid = "d0513dd9-dcf7-46c4-becc-0a533c93258a";
    int partitionkey = 1234;

    Databases AzureCosmosClient = new(config);
    
    var result = AzureCosmosClient->listOneDocument("hikall","mycollection1",documentid,partitionkey);

    if (result is Document) {
        io:println(result);
    } else {
        test:assertFail(msg = result.message());
    }   
    io:println("\n\n");

}

@test:Config{
    enable: false
}
function replaceDocument(){

    Databases AzureCosmosClient = new(config);


    string documentid = "5404636f-f2bc-4ee4-b18a-5eacfd0c978d";
    int partitionkey = 1234;

    json id = {
        "id": documentid,
        "AccountNumber": partitionkey
    };

 
    json custom = {
        "LastName": "keeeeeee",  
        "Parents": [  
            {  
            "FamilyName": null,  
            "FirstName": "Thomas"  
            },  
            {  
            "FamilyName": null,  
            "FirstName": "Mary Kay"  
            }  
        ],  
        "Children": [  
            {  
            "FamilyName": null,  
            "FirstName": "Henriette Thaulow",  
            "Gender": "female",  
            "Grade": 5,  
            "Pets": [  
                {  
                "GivenName": "Fluffy"  
                }  
            ]  
            }  
        ],  
        "Address": {  
            "State": "WA",  
            "County": "King",  
            "City": "Seattle"  
        },  
        "IsRegistered": true
    };

    json|error finalj = custom.mergeJson(id);

    var result = AzureCosmosClient->replaceDocument("hikall","mycollection1",<json>finalj,documentid,partitionkey);
       
        if result is Document {
            io:println(result);
        } else {
        test:assertFail(msg = result.message());
        }   
            io:println("\n\n");
    
}

@test:Config{
    enable: false
}
function deleteDocument(){

    Databases AzureCosmosClient = new(config);


    string documentid = "f8c9c347-d50e-4ba4-860e-6b11aea51012";
    int partitionkey = 1234;


    var result = AzureCosmosClient->deleteDocument("hikall","mycollection1",documentid,partitionkey);
       
        if result is string {
            io:println(result);
        } else {
        test:assertFail(msg = result.message());
        }   
            io:println("\n\n");
    
}

@test:Config{
}
function queryDocument(){

    Databases AzureCosmosClient = new(config);

    int partitionkey = 1234;

    json query = {  
        "query": "SELECT * FROM Families f WHERE f.id = @id AND f.address.city = @city",  
        "parameters": [  
            {  
            "name": "@id",  
            "value": "AndersenFamily"  
            },  
            {  
            "name": "@city",  
            "value": "NY"  
            }  
        ]  
    };   

    


    var result = AzureCosmosClient->queryDocument("hikall","mycollection1",query,partitionkey);
       
        if result is json {
            io:println(result);
        } else {
        test:assertFail(msg = result.message());
        }   
            io:println("\n\n");
    
}

function createRandomUUID() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;




