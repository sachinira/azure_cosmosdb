import ballerina/java;
import ballerina/time;
import ballerina/io;
import ballerina/crypto;
import ballerina/encoding;
import ballerina/http;
import ballerina/stringutils;
import ballerina/lang.'string as str;

function parseResponseToTuple(http:Response|http:ClientError httpResponse) returns  @tainted [json,Headers]|error{
    var responseBody = check parseResponseToJson(httpResponse);
    var responseHeaders = check parseHeadersToObject(httpResponse);
    return [responseBody,responseHeaders];
}

function parseDeleteResponseToTuple(http:Response|http:ClientError httpResponse) returns  @tainted 
[string,Headers]|error{
    var responseBody = check getDeleteResponse(httpResponse);
    var responseHeaders = check parseHeadersToObject(httpResponse);
    return [responseBody,responseHeaders];
}

# To handle sucess or error reponses to requests
# + httpResponse - http:Response or http:ClientError returned from an http:Request
# + return - If successful, returns json. Else returns error.  
function parseResponseToJson(http:Response|http:ClientError httpResponse) returns @tainted json|error { 
    if (httpResponse is http:Response) {
        var jsonResponse = httpResponse.getJsonPayload();
        if (jsonResponse is json) {
            if (httpResponse.statusCode != http:STATUS_OK && httpResponse.statusCode != http:STATUS_CREATED) {
                string code = "";    
                if (jsonResponse?.error_code != ()) {
                    code = jsonResponse.error_code.toString();
                } else if (jsonResponse?.'error != ()) {
                    code = jsonResponse.'error.toString();
                }
                string message = jsonResponse.message.toString();
                //errors handle 400 401 403 408 409 404
                string errorMessage = httpResponse.statusCode.toString() + " " + httpResponse.reasonPhrase; 
                if (code != "") {
                    errorMessage += " - " + code;
                }
                errorMessage += " : " + message;
                return prepareError(errorMessage);
            }
            return jsonResponse;
        } else {
            return prepareError("Error occurred while accessing the JSON payload of the response");
        }
    } else {
        return prepareError("Error occurred while invoking the REST API");
    }
}

# To handle the delete responses which return without a json payload
# + httpResponse - http:Response or http:ClientError returned from an http:Request
# + return - If successful, returns string. Else returns error.  
function getDeleteResponse(http:Response|http:ClientError httpResponse) returns @tainted string|error{
    if (httpResponse is http:Response) {
        if(httpResponse.statusCode == http:STATUS_NO_CONTENT){
            return string `${httpResponse.statusCode} Deleted Sucessfully`;
        } else if (httpResponse.statusCode == http:STATUS_NOT_FOUND) {
            return string `${httpResponse.statusCode} The resource/item with specified id is not found.`;
        } else{
            return prepareError(string `${httpResponse.statusCode} Error occurred while invoking the REST API.`);
        }
    } else {
        return prepareError("Error occurred while invoking the REST API");
    }
}

function parseHeadersToObject(http:Response|http:ClientError httpResponse) returns @tainted Headers|error{
    Headers responseHeaders = {};
    if (httpResponse is http:Response) {
        responseHeaders.continuationHeader = getHeaderIfExist(httpResponse,"x-ms-continuation");
        responseHeaders.sessionTokenHeader = getHeaderIfExist(httpResponse,"x-ms-session-token");
        responseHeaders.requestChargeHeader = getHeaderIfExist(httpResponse,"x-ms-request-charge");
        responseHeaders.resourceUsageHeader = getHeaderIfExist(httpResponse,"x-ms-resource-usage");
        responseHeaders.itemCountHeader = getHeaderIfExist(httpResponse,"x-ms-item-count");
        responseHeaders.etagHeader = getHeaderIfExist(httpResponse,"etag");
        responseHeaders.dateHeader = getHeaderIfExist(httpResponse,"Date");
        return responseHeaders;

    } else {
        return prepareError("Error occurred while invoking the REST API");
    }
}

function getHeaderIfExist(http:Response httpResponse, string headername) returns @tainted string?{
    if httpResponse.hasHeader(headername) {
        return httpResponse.getHeader(headername);
    }else{
        return ();
    }
}

function mapRequest(http:Request? req) returns http:Request { 
    http:Request newRequest = new;
    if req is http:Request{
        return req;
    } else {
        return newRequest;
    }
}

# To create a custom error instance
# + return - returns error.  
function prepareError(string message, error? err = ()) returns error { 
    error azureError;
    if (err is error) {
        azureError = AzureError(message, err);
    } else {
        azureError = AzureError(message);
    }
    return azureError;
}

# Returns the prepared URL.
# + paths - An array of paths prefixes
# + return - The prepared URL
function prepareUrl(string[] paths) returns string {
    string url = EMPTY_STRING;

    if (paths.length() > 0) {
        foreach var path in paths {
            if (!path.startsWith(FORWARD_SLASH)) {
                url = url + FORWARD_SLASH;
            }
            url = url + path;
        }
    }
    return <@untainted> url;
}

function convertToBoolean(json|error value) returns boolean { 
    if (value is json) {
        boolean|error result = 'boolean:fromString(value.toString());
        if (result is boolean) {
            return result;
        }
    }
    return false;
}

function convertToInt(json|error value) returns int {
    if (value is json) {
        int|error result = 'int:fromString(value.toString());
        if (result is int) {
            return result;
        }
    }
    return 0;
}

function mergeTwoArrays(any[] array1, any[] array2) returns any[]{
    foreach any element in array2 {
       array1.push(element);
    }
    return array1;
}

public function setThroughputOrAutopilotHeader(http:Request req, ThroughputProperties? throughputProperties) returns 
http:Request|error{

    if throughputProperties is ThroughputProperties{
        if throughputProperties.throughput is int &&  throughputProperties.maxThroughput is () {
            //validate throughput The minimum is 400 up to 1,000,000 (or higher by requesting a limit increase).
            req.setHeader("x-ms-offer-throughput",throughputProperties.maxThroughput.toString());
        } else if throughputProperties.throughput is () &&  throughputProperties.maxThroughput != () {
            req.setHeader("x-ms-cosmos-offer-autopilot-settings",throughputProperties.maxThroughput.toString());
        } else if throughputProperties.throughput is int &&  throughputProperties.maxThroughput != () {
            return 
            prepareError("Cannot set both x-ms-offer-throughput and x-ms-cosmos-offer-autopilot-settings headers at once");
        }
    }
    return req;
}

public function setPartitionKeyHeader(http:Request req, any pk) returns http:Request|error{
    req.setHeader("x-ms-documentdb-partitionkey",string `[${pk.toString()}]`);
    return req;
}

public function enableCrossPartitionKeyHeader(http:Request req, boolean isignore) returns http:Request|error{
    req.setHeader("x-ms-documentdb-query-enablecrosspartition",isignore.toString());
    return req;
}

public function setHeadersForQuery(http:Request req) returns http:Request|error{
    req.setHeader("Content-Type","application/query+json");
    req.setHeader("x-ms-documentdb-isquery","true");
    //req.setHeader("x-ms-documentdb-query-enablecrosspartition","true");
    return req;
}

public function setDocumentRequestOptions(http:Request req, RequestOptions requestOptions) returns http:Request|error{
    if requestOptions.indexingDirective is string {
        req.setHeader("x-ms-indexing-directive",requestOptions.indexingDirective.toString());
    }
    if requestOptions.isUpsertRequest == true {
        req.setHeader("x-ms-documentdb-is-upsert",requestOptions.isUpsertRequest.toString());
    }
    if requestOptions.maxItemCount is int{
        req.setHeader("x-ms-max-item-count",requestOptions.maxItemCount.toString()); 
    }
    if requestOptions.continuationToken is string{
        req.setHeader("x-ms-continuation",requestOptions.continuationToken.toString());
    }
    if requestOptions.consistancyLevel is string {
        req.setHeader("x-ms-consistency-level",requestOptions.consistancyLevel.toString());
    }
    if requestOptions.sessionToken is string {
        req.setHeader("x-ms-session-token",requestOptions.sessionToken.toString());
    }
    if requestOptions.changeFeedOption is string{
        req.setHeader("A-IM",requestOptions.changeFeedOption.toString()); 
    }
    if requestOptions.ifNoneMatch is string{
        req.setHeader("If-None-Match",requestOptions.ifNoneMatch.toString());
    }
    if requestOptions.PartitionKeyRangeId is string{
        req.setHeader("x-ms-documentdb-partitionkeyrangeid",requestOptions.PartitionKeyRangeId.toString());
    }
    if requestOptions.PartitionKeyRangeId is string{
        req.setHeader("If-Match",requestOptions.PartitionKeyRangeId.toString());
    }
    return req;
}

# To attach required basic headers to call REST endpoint
# + req - http:Request to add headers to
# + host - 
# + keyToken - master or resource token
# + tokenType - denotes the type of token: master or resource.
# + tokenVersion - denotes the version of the token, currently 1.0.
# + params - an object of type HeaderParamaters
# + return - If successful, returns same http:Request with newly appended headers. Else returns error.  
public function setHeaders(http:Request req, string host, string keyToken, string tokenType, string tokenVersion,
HeaderParamaters params) returns http:Request|error{
    req.setHeader("x-ms-version",params.apiVersion);
    req.setHeader("Host",host);
    req.setHeader("Accept","*/*");
    req.setHeader("Connection","keep-alive");

    string? date = check getTime();
    if date is string
    {
        string? s = generateTokenNew(params.verb,params.resourceType,params.resourceId,keyToken,tokenType,tokenVersion);
        req.setHeader("x-ms-date",date);
        if s is string {
            req.setHeader("Authorization",s);
        } else {
            io:println("token is null");
        }
    } else {
        io:println("date is null");
    }
    return req;
}

# To construct the hashed token signature for a token to set  'Authorization' header
# + verb - HTTP verb, such as GET, POST, or PUT
# + resourceType - identifies the type of resource that the request is for, Eg. "dbs", "colls", "docs"
# + resourceId -dentity property of the resource that the request is directed at
# + keyToken - master or resource token
# + tokenType - denotes the type of token: master or resource.
# + tokenVersion - denotes the version of the token, currently 1.0.
# + return - If successful, returns string which is the  hashed token signature. Else returns ().  
public function generateTokenNew(string verb, string resourceType, string resourceId, string keyToken, string tokenType, 
string tokenVersion) returns string?{
    var token = generateTokenJ(java:fromString(verb),java:fromString(resourceType),java:fromString(resourceId),
    java:fromString(keyToken),java:fromString(tokenType),java:fromString(tokenVersion));
    return java:toString(token);

}

# To construct the hashed token signature for a token 
# + return - If successful, returns string representing UTC date and time 
#               (in "HTTP-date" format as defined by RFC 7231 Date/Time Formats). Else returns error.  
public function getTime() returns string?|error{
    time:Time time1 = time:currentTime();
    var time2 = check time:toTimeZone(time1, "Europe/London");
    string|error timeString = time:format(time2, "EEE, dd MMM yyyy HH:mm:ss z");
    return timeString;
}

# To construct resource type  which is used to create the hashed token signature 
# + url - string parameter part of url to extract the resource type
# + return - Returns the resource type extracted from url as a string  
public function getResourceType(string url) returns string{
    string resourceType = EMPTY_STRING;
    string[] urlParts = stringutils:split(url,FORWARD_SLASH);
    int count = urlParts.length()-1;
    if count % 2 != 0{
        resourceType = urlParts[count];
        if count > 1{
            int? i = str:lastIndexOf(url,FORWARD_SLASH);
        }
    } else {
        resourceType = urlParts[count-1];
    }
    return resourceType;
}

# To construct resource id  which is used to create the hashed token signature 
# + url - string parameter part of url to extract the resource id
# + return - Returns the resource id extracted from url as a string 
public function getResourceId(string url) returns string{
    string resourceId = EMPTY_STRING;
    string[] urlParts = stringutils:split(url,FORWARD_SLASH);
    int count = urlParts.length()-1;
    if count % 2 != 0{
        if count > 1{
            int? i = str:lastIndexOf(url,FORWARD_SLASH);
            if i is int {
                resourceId = str:substring(url,1,i);
            }
        }
    } else {
        resourceId = str:substring(url,1);
    }
    return resourceId;
}

public function generateToken(string verb, string resourceType, string resourceId, string keys, string keyType, 
string tokenVersion, string date) returns string?|error{    
    string authorization;
    string payload = verb.toLowerAscii()+"\n" 
        +resourceType.toLowerAscii()+"\n"
        +resourceId+"\n"
        +date.toLowerAscii()+"\n"
        +""+"\n";
    var decoded = encoding:decodeBase64Url(keys);

    if decoded is byte[]
    {
        byte[] k = crypto:hmacSha256(payload.toBytes(),decoded);
        string  t = k.toBase16();
        string signature = encoding:encodeBase64Url(k);
        authorization = 
        check encoding:encodeUriComponent(string `type=${keyType}&ver=${tokenVersion}&sig=${signature}=`, "UTF-8");   
        return authorization;
    } else {     
        io:println("Decoding error");
    }
}

function generateTokenJ(handle verb, handle resourceType, handle resourceId, handle keyToken, handle tokenType, 
handle tokenVersion) returns handle = @java:Method {
    name: "generate",
    'class: "com.sachini.TokenCreate"
} external;