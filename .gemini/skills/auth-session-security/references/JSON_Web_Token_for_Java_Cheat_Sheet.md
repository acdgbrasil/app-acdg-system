\--- redirect_from: "/cheatsheets/JSON_Web_Token_Cheat_Sheet_for_Java.html" \--- 

Skip to content 

[ ](../index.html "OWASP Cheat Sheet Series")

OWASP Cheat Sheet Series 

JSON Web Token for Java 

Initializing search 


[ OWASP/CheatSheetSeries  ](https://github.com/OWASP/CheatSheetSeries "Go to repository")

[ ](../index.html "OWASP Cheat Sheet Series") OWASP Cheat Sheet Series 

[ OWASP/CheatSheetSeries  ](https://github.com/OWASP/CheatSheetSeries "Go to repository")

  * [ Introduction  ](../index.html)
  * [ Index Alphabetical  ](../Glossary.html)
  * [ Index ASVS  ](../IndexASVS.html)
  * [ Index MASVS  ](../IndexMASVS.html)
  * [ Index Proactive Controls  ](../IndexProactiveControls.html)
  * [ Index Top 10  ](../IndexTopTen.html)
  * Cheatsheets  Cheatsheets 
    * [ AI Agent Security  ](AI_Agent_Security_Cheat_Sheet.html)
    * [ AJAX Security  ](AJAX_Security_Cheat_Sheet.html)
    * [ Abuse Case  ](Abuse_Case_Cheat_Sheet.html)
    * [ Access Control  ](Access_Control_Cheat_Sheet.html)
    * [ Attack Surface Analysis  ](Attack_Surface_Analysis_Cheat_Sheet.html)
    * [ Authentication  ](Authentication_Cheat_Sheet.html)
    * [ Authorization  ](Authorization_Cheat_Sheet.html)
    * [ Authorization Testing Automation  ](Authorization_Testing_Automation_Cheat_Sheet.html)
    * [ Automotive Security  ](Automotive_Security_Cheat_Sheet.html)
    * [ Bean Validation  ](Bean_Validation_Cheat_Sheet.html)
    * [ Browser Extension Vulnerabilities  ](Browser_Extension_Vulnerabilities_Cheat_Sheet.html)
    * [ C-Based Toolchain Hardening  ](C-Based_Toolchain_Hardening_Cheat_Sheet.html)
    * [ CI CD Security  ](CI_CD_Security_Cheat_Sheet.html)
    * [ Choosing and Using Security Questions  ](Choosing_and_Using_Security_Questions_Cheat_Sheet.html)
    * [ Clickjacking Defense  ](Clickjacking_Defense_Cheat_Sheet.html)
    * [ Content Security Policy  ](Content_Security_Policy_Cheat_Sheet.html)
    * [ Cookie Theft Mitigation  ](Cookie_Theft_Mitigation_Cheat_Sheet.html)
    * [ Credential Stuffing Prevention  ](Credential_Stuffing_Prevention_Cheat_Sheet.html)
    * [ Cross-Site Request Forgery Prevention  ](Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
    * [ Cross Site Scripting Prevention  ](Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
    * [ Cryptographic Storage  ](Cryptographic_Storage_Cheat_Sheet.html)
    * [ DOM Clobbering Prevention  ](DOM_Clobbering_Prevention_Cheat_Sheet.html)
    * [ DOM based XSS Prevention  ](DOM_based_XSS_Prevention_Cheat_Sheet.html)
    * [ Database Security  ](Database_Security_Cheat_Sheet.html)
    * [ Denial of Service  ](Denial_of_Service_Cheat_Sheet.html)
    * [ Dependency Graph SBOM  ](Dependency_Graph_SBOM_Cheat_Sheet.html)
    * [ Deserialization  ](Deserialization_Cheat_Sheet.html)
    * [ Django REST Framework  ](Django_REST_Framework_Cheat_Sheet.html)
    * [ Django Security  ](Django_Security_Cheat_Sheet.html)
    * [ Docker Security  ](Docker_Security_Cheat_Sheet.html)
    * [ DotNet Security  ](DotNet_Security_Cheat_Sheet.html)
    * [ Drone Security  ](Drone_Security_Cheat_Sheet.html)
    * [ Email Validation and Verification  ](Email_Validation_and_Verification_Cheat_Sheet.html)
    * [ Error Handling  ](Error_Handling_Cheat_Sheet.html)
    * [ File Upload  ](File_Upload_Cheat_Sheet.html)
    * [ Forgot Password  ](Forgot_Password_Cheat_Sheet.html)
    * [ GraphQL  ](GraphQL_Cheat_Sheet.html)
    * [ HTML5 Security  ](HTML5_Security_Cheat_Sheet.html)
    * [ HTTP Headers  ](HTTP_Headers_Cheat_Sheet.html)
    * [ HTTP Strict Transport Security  ](HTTP_Strict_Transport_Security_Cheat_Sheet.html)
    * [ Infrastructure as Code Security  ](Infrastructure_as_Code_Security_Cheat_Sheet.html)
    * [ Injection Prevention  ](Injection_Prevention_Cheat_Sheet.html)
    * [ Injection Prevention in Java  ](Injection_Prevention_in_Java_Cheat_Sheet.html)
    * [ Input Validation  ](Input_Validation_Cheat_Sheet.html)
    * [ Insecure Direct Object Reference Prevention  ](Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.html)
    * [ JAAS  ](JAAS_Cheat_Sheet.html)
    * JSON Web Token for Java  [ JSON Web Token for Java  ](JSON_Web_Token_for_Java_Cheat_Sheet.html) Table of contents 
      * Introduction 
      * Token Structure 
      * Objective 
      * Consideration about Using JWT 
      * Issues 
        * None Hashing Algorithm 
          * Symptom 
          * How to Prevent 
          * Implementation Example 
        * Token Sidejacking 
          * Symptom 
          * How to Prevent 
          * Implementation example 
        * No Built-In Token Revocation by the User 
          * Symptom 
          * How to Prevent 
          * Implementation Example 
            * Block List Storage 
            * Token Revocation Management 
        * Token Information Disclosure 
          * Symptom 
          * How to Prevent 
          * Implementation Example 
            * Token Ciphering 
            * Creation / Validation of the Token 
        * Token Storage on Client Side 
          * Symptom 
          * How to Prevent 
          * Implementation Example 
        * Weak Token Secret 
          * Symptom 
          * How to Prevent 
          * Further Reading 
    * [ Java Security  ](Java_Security_Cheat_Sheet.html)
    * [ Key Management  ](Key_Management_Cheat_Sheet.html)
    * [ Kubernetes Security  ](Kubernetes_Security_Cheat_Sheet.html)
    * [ LDAP Injection Prevention  ](LDAP_Injection_Prevention_Cheat_Sheet.html)
    * [ LLM Prompt Injection Prevention  ](LLM_Prompt_Injection_Prevention_Cheat_Sheet.html)
    * [ Laravel  ](Laravel_Cheat_Sheet.html)
    * [ Legacy Application Management  ](Legacy_Application_Management_Cheat_Sheet.html)
    * [ Logging  ](Logging_Cheat_Sheet.html)
    * [ Logging Vocabulary  ](Logging_Vocabulary_Cheat_Sheet.html)
    * [ MCP Security  ](MCP_Security_Cheat_Sheet.html)
    * [ Mass Assignment  ](Mass_Assignment_Cheat_Sheet.html)
    * [ Microservices Security  ](Microservices_Security_Cheat_Sheet.html)
    * [ Microservices based Security Arch Doc  ](Microservices_based_Security_Arch_Doc_Cheat_Sheet.html)
    * [ Mobile Application Security  ](Mobile_Application_Security_Cheat_Sheet.html)
    * [ Multi Tenant Security  ](Multi_Tenant_Security_Cheat_Sheet.html)
    * [ Multifactor Authentication  ](Multifactor_Authentication_Cheat_Sheet.html)
    * [ NPM Security  ](NPM_Security_Cheat_Sheet.html)
    * [ Network Segmentation  ](Network_Segmentation_Cheat_Sheet.html)
    * [ NoSQL Security  ](NoSQL_Security_Cheat_Sheet.html)
    * [ NodeJS Docker  ](NodeJS_Docker_Cheat_Sheet.html)
    * [ Nodejs Security  ](Nodejs_Security_Cheat_Sheet.html)
    * [ OAuth2  ](OAuth2_Cheat_Sheet.html)
    * [ OS Command Injection Defense  ](OS_Command_Injection_Defense_Cheat_Sheet.html)
    * [ PHP Configuration  ](PHP_Configuration_Cheat_Sheet.html)
    * [ Password Storage  ](Password_Storage_Cheat_Sheet.html)
    * [ Pinning  ](Pinning_Cheat_Sheet.html)
    * [ Prototype Pollution Prevention  ](Prototype_Pollution_Prevention_Cheat_Sheet.html)
    * [ Query Parameterization  ](Query_Parameterization_Cheat_Sheet.html)
    * [ REST Assessment  ](REST_Assessment_Cheat_Sheet.html)
    * [ REST Security  ](REST_Security_Cheat_Sheet.html)
    * [ Ruby on Rails  ](Ruby_on_Rails_Cheat_Sheet.html)
    * [ SAML Security  ](SAML_Security_Cheat_Sheet.html)
    * [ SQL Injection Prevention  ](SQL_Injection_Prevention_Cheat_Sheet.html)
    * [ Secrets Management  ](Secrets_Management_Cheat_Sheet.html)
    * [ Secure AI Model Ops  ](Secure_AI_Model_Ops_Cheat_Sheet.html)
    * [ Secure Cloud Architecture  ](Secure_Cloud_Architecture_Cheat_Sheet.html)
    * [ Secure Code Review  ](Secure_Code_Review_Cheat_Sheet.html)
    * [ Secure Product Design  ](Secure_Product_Design_Cheat_Sheet.html)
    * [ Securing Cascading Style Sheets  ](Securing_Cascading_Style_Sheets_Cheat_Sheet.html)
    * [ Security Terminology  ](Security_Terminology_Cheat_Sheet.html)
    * [ Server Side Request Forgery Prevention  ](Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)
    * [ Serverless FaaS Security  ](Serverless_FaaS_Security_Cheat_Sheet.html)
    * [ Session Management  ](Session_Management_Cheat_Sheet.html)
    * [ Software Supply Chain Security  ](Software_Supply_Chain_Security_Cheat_Sheet.html)
    * [ Subdomain Takeover Prevention  ](Subdomain_Takeover_Prevention_Cheat_Sheet.html)
    * [ Symfony  ](Symfony_Cheat_Sheet.html)
    * [ TLS Cipher String  ](TLS_Cipher_String_Cheat_Sheet.html)
    * [ Third Party Javascript Management  ](Third_Party_Javascript_Management_Cheat_Sheet.html)
    * [ Third Party Payment Gateway Integration  ](Third_Party_Payment_Gateway_Integration_Cheat_Sheet.html)
    * [ Threat Modeling  ](Threat_Modeling_Cheat_Sheet.html)
    * [ Transaction Authorization  ](Transaction_Authorization_Cheat_Sheet.html)
    * [ Transport Layer Protection  ](Transport_Layer_Protection_Cheat_Sheet.html)
    * [ Transport Layer Security  ](Transport_Layer_Security_Cheat_Sheet.html)
    * [ Unvalidated Redirects and Forwards  ](Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html)
    * [ User Privacy Protection  ](User_Privacy_Protection_Cheat_Sheet.html)
    * [ Virtual Patching  ](Virtual_Patching_Cheat_Sheet.html)
    * [ Vulnerability Disclosure  ](Vulnerability_Disclosure_Cheat_Sheet.html)
    * [ Vulnerable Dependency Management  ](Vulnerable_Dependency_Management_Cheat_Sheet.html)
    * [ WebSocket Security  ](WebSocket_Security_Cheat_Sheet.html)
    * [ Web Service Security  ](Web_Service_Security_Cheat_Sheet.html)
    * [ XML External Entity Prevention  ](XML_External_Entity_Prevention_Cheat_Sheet.html)
    * [ XML Security  ](XML_Security_Cheat_Sheet.html)
    * [ XSS Filter Evasion  ](XSS_Filter_Evasion_Cheat_Sheet.html)
    * [ XS Leaks  ](XS_Leaks_Cheat_Sheet.html)
    * [ Zero Trust Architecture  ](Zero_Trust_Architecture_Cheat_Sheet.html)
    * [ gRPC Security  ](gRPC_Security_Cheat_Sheet.html)


Table of contents 

  * Introduction 
  * Token Structure 
  * Objective 
  * Consideration about Using JWT 
  * Issues 
    * None Hashing Algorithm 
      * Symptom 
      * How to Prevent 
      * Implementation Example 
    * Token Sidejacking 
      * Symptom 
      * How to Prevent 
      * Implementation example 
    * No Built-In Token Revocation by the User 
      * Symptom 
      * How to Prevent 
      * Implementation Example 
        * Block List Storage 
        * Token Revocation Management 
    * Token Information Disclosure 
      * Symptom 
      * How to Prevent 
      * Implementation Example 
        * Token Ciphering 
        * Creation / Validation of the Token 
    * Token Storage on Client Side 
      * Symptom 
      * How to Prevent 
      * Implementation Example 
    * Weak Token Secret 
      * Symptom 
      * How to Prevent 
      * Further Reading 


# JSON Web Token Cheat Sheet for Java¶

## Introduction¶

Many applications use **JSON Web Tokens** (JWT) to allow the client to indicate its identity for further exchange after authentication.

From [JWT.IO](https://jwt.io/introduction):

> JSON Web Token (JWT) is an open standard (RFC 7519) that defines a compact and self-contained way for securely transmitting information between parties as a JSON object. This information can be verified and trusted because it is digitally signed. JWTs can be signed using a secret (with the HMAC algorithm) or a public/private key pair using RSA.

JWTs are used to carry information related to the identity and characteristics (claims) of a client. This information is signed by the server to ensure it has not been tampered with after being sent to the client. This prevents an attacker from modifying the identity or characteristics — for example, changing the role from a simple user to an admin or altering the client's login.

The token is created during authentication (it is issued upon successful authentication) and is verified by the server before any processing. Applications use the token to allow a client to present what is essentially an "identity card" to the server. The server can then securely verify the token's validity and integrity. This approach is stateless and portable, meaning it works across different client and server technologies, and over various transport channels — although HTTP is the most commonly used.

## Token Structure¶

Token structure example taken from [JWT.IO](https://jwt.io/#debugger):

`[Base64(HEADER)].[Base64(PAYLOAD)].[Base64(SIGNATURE)]`
    
    
    eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
    eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.
    TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ
    

Chunk 1: **Header**
    
    
    {
      "alg": "HS256",
      "typ": "JWT"
    }
    

Chunk 2: **Payload**
    
    
    {
      "sub": "1234567890",
      "name": "John Doe",
      "admin": true
    }
    

Chunk 3: **Signature**
    
    
    HMACSHA256( base64UrlEncode(header) + "." + base64UrlEncode(payload), KEY )
    

## Objective¶

This cheatsheet provides tips to prevent common security issues when using JSON Web Tokens (JWT) with Java.

The tips presented in this article are part of a Java project that was created to show the correct way to handle creation and validation of JSON Web Tokens.

You can find the Java project [here](https://github.com/righettod/poc-jwt), it uses the official [JWT library](https://jwt.io/#libraries).

In the rest of the article, the term **token** refers to the **JSON Web Tokens** (JWT).

## Consideration about Using JWT¶

Even if a JWT is "easy" to use and allow to expose services (mostly REST style) in a stateless way, it's not the solution that fits for all applications because it comes with some caveats, like for example the question of the storage of the token (tackled in this cheatsheet) and others...

If your application does not need to be fully stateless, you can consider using traditional session system provided by all web frameworks and follow the advice from the dedicated [session management cheat sheet](Session_Management_Cheat_Sheet.html). However, for stateless applications, when well implemented, it's a good candidate.

## Issues¶

### None Hashing Algorithm¶

#### Symptom¶

This attack, described [here](https://auth0.com/blog/critical-vulnerabilities-in-json-web-token-libraries/), occurs when an attacker alters the token and changes the hashing algorithm to indicate, through the _none_ keyword, that the integrity of the token has already been verified. As explained in the link above _some libraries treated tokens signed with the none algorithm as a valid token with a verified signature_ , so an attacker can alter the token claims and the modified token will still be trusted by the application.

#### How to Prevent¶

First, use a JWT library that is not exposed to this vulnerability.

Last, during token validation, explicitly request that the expected algorithm was used.

#### Implementation Example¶
    
    
    // HMAC key - Block serialization and storage as String in JVM memory
    private transient byte[] keyHMAC = ...;
    
    ...
    
    //Create a verification context for the token requesting
    //explicitly the use of the HMAC-256 hashing algorithm
    JWTVerifier verifier = JWT.require(Algorithm.HMAC256(keyHMAC)).build();
    
    //Verify the token, if the verification fail then a exception is thrown
    DecodedJWT decodedToken = verifier.verify(token);
    

### Token Sidejacking¶

#### Symptom¶

This attack occurs when a token has been intercepted/stolen by an attacker and they use it to gain access to the system using targeted user identity.

#### How to Prevent¶

One way to prevent this is by adding a "user context" to the token. The user context should consist of the following:

  * A random string generated during the authentication phase. This string is sent to the client as a hardened cookie (with the following flags: [HttpOnly + Secure](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#Secure_and_HttpOnly_cookies), [SameSite](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#SameSite_cookies), [Max-Age](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie), and [cookie prefixes](https://googlechrome.github.io/samples/cookie-prefixes/)). Avoid setting the _expires_ header so the cookie is cleared when the browser is closed. Set _Max-Age_ to a value equal to or less than the JWT's expiry time — never more.
  * A SHA256 hash of the random string will be stored in the token (instead of the raw value) in order to prevent any XSS issues allowing the attacker to read the random string value and setting the expected cookie.


Avoid using IP addresses as part of the context. IP addresses can change during a single session due to legitimate reasons — for example, when a user accesses the application on a mobile device and switches network providers. Additionally, IP tracking can raise concerns related to [GDPR compliance](https://gdpr.eu/) in the EU.

During token validation, if the received token does not contain the correct context (e.g., if it is being replayed by an attacker), it must be rejected.

#### Implementation example¶

Code to create the token after successful authentication.
    
    
    // HMAC key - Block serialization and storage as String in JVM memory
    private transient byte[] keyHMAC = ...;
    // Random data generator
    private SecureRandom secureRandom = new SecureRandom();
    
    ...
    
    //Generate a random string that will constitute the fingerprint for this user
    byte[] randomFgp = new byte[50];
    secureRandom.nextBytes(randomFgp);
    String userFingerprint = DatatypeConverter.printHexBinary(randomFgp);
    
    //Add the fingerprint in a hardened cookie - Add cookie manually because
    //SameSite attribute is not supported by javax.servlet.http.Cookie class
    String fingerprintCookie = "__Secure-Fgp=" + userFingerprint
                               + "; SameSite=Strict; HttpOnly; Secure";
    response.addHeader("Set-Cookie", fingerprintCookie);
    
    //Compute a SHA256 hash of the fingerprint in order to store the
    //fingerprint hash (instead of the raw value) in the token
    //to prevent an XSS to be able to read the fingerprint and
    //set the expected cookie itself
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    byte[] userFingerprintDigest = digest.digest(userFingerprint.getBytes("utf-8"));
    String userFingerprintHash = DatatypeConverter.printHexBinary(userFingerprintDigest);
    
    //Create the token with a validity of 15 minutes and client context (fingerprint) information
    Calendar c = Calendar.getInstance();
    Date now = c.getTime();
    c.add(Calendar.MINUTE, 15);
    Date expirationDate = c.getTime();
    Map<String, Object> headerClaims = new HashMap<>();
    headerClaims.put("typ", "JWT");
    String token = JWT.create().withSubject(login)
       .withExpiresAt(expirationDate)
       .withIssuer(this.issuerID)
       .withIssuedAt(now)
       .withNotBefore(now)
       .withClaim("userFingerprint", userFingerprintHash)
       .withHeader(headerClaims)
       .sign(Algorithm.HMAC256(this.keyHMAC));
    

Code to validate the token.
    
    
    // HMAC key - Block serialization and storage as String in JVM memory
    private transient byte[] keyHMAC = ...;
    
    ...
    
    //Retrieve the user fingerprint from the dedicated cookie
    String userFingerprint = null;
    if (request.getCookies() != null && request.getCookies().length > 0) {
     List<Cookie> cookies = Arrays.stream(request.getCookies()).collect(Collectors.toList());
     Optional<Cookie> cookie = cookies.stream().filter(c -> "__Secure-Fgp"
                                                .equals(c.getName())).findFirst();
     if (cookie.isPresent()) {
       userFingerprint = cookie.get().getValue();
     }
    }
    
    //Compute a SHA256 hash of the received fingerprint in cookie in order to compare
    //it to the fingerprint hash stored in the token
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    byte[] userFingerprintDigest = digest.digest(userFingerprint.getBytes("utf-8"));
    String userFingerprintHash = DatatypeConverter.printHexBinary(userFingerprintDigest);
    
    //Create a verification context for the token
    JWTVerifier verifier = JWT.require(Algorithm.HMAC256(keyHMAC))
                                  .withIssuer(issuerID)
                                  .withClaim("userFingerprint", userFingerprintHash)
                                  .build();
    
    //Verify the token, if the verification fail then an exception is thrown
    DecodedJWT decodedToken = verifier.verify(token);
    

### No Built-In Token Revocation by the User¶

#### Symptom¶

This problem is inherent to JWT because a token only becomes invalid when it expires. The user has no built-in feature to explicitly revoke the validity of a token. This means that if it is stolen, a user cannot revoke the token itself thereby blocking the attacker.

#### How to Prevent¶

Since JWTs are stateless, There is no session maintained on the server(s) serving client requests. As such, there is no session to invalidate on the server side. A well implemented Token Sidejacking solution (as explained above) should alleviate the need for maintaining denylist on server side. This is because a hardened cookie used in the Token Sidejacking can be considered as secure as a session ID used in the traditional session system, and unless both the cookie and the JWT are intercepted/stolen, the JWT is unusable. A logout can thus be 'simulated' by clearing the JWT from session storage. If the user chooses to close the browser instead, then both the cookie and sessionStorage are cleared automatically.

Another way to protect against this is to implement a token denylist that will be used to mimic the "logout" feature that exists with traditional session management system.

The denylist will keep a digest (SHA-256 encoded in HEX) of the token with a revocation date. This entry must endure at least until the expiration of the token.

When the user wants to "logout" then it call a dedicated service that will add the provided user token to the denylist resulting in an immediate invalidation of the token for further usage in the application.

#### Implementation Example¶

##### Block List Storage¶

A database table with the following structure will be used as the central denylist storage.
    
    
    create table if not exists revoked_token(jwt_token_digest varchar(255) primary key,
    revocation_date timestamp default now());
    

##### Token Revocation Management¶

Code in charge of adding a token to the denylist and checking if a token is revoked.
    
    
    /**
    * Handle the revocation of the token (logout).
    * Use a DB in order to allow multiple instances to check for revoked token
    * and allow cleanup at centralized DB level.
    */
    public class TokenRevoker {
    
     /** DB Connection */
     @Resource("jdbc/storeDS")
     private DataSource storeDS;
    
     /**
      * Verify if a digest encoded in HEX of the ciphered token is present
      * in the revocation table
      *
      * @param jwtInHex Token encoded in HEX
      * @return Presence flag
      * @throws Exception If any issue occur during communication with DB
      */
     public boolean isTokenRevoked(String jwtInHex) throws Exception {
         boolean tokenIsPresent = false;
         if (jwtInHex != null && !jwtInHex.trim().isEmpty()) {
             //Decode the ciphered token
             byte[] cipheredToken = DatatypeConverter.parseHexBinary(jwtInHex);
    
             //Compute a SHA256 of the ciphered token
             MessageDigest digest = MessageDigest.getInstance("SHA-256");
             byte[] cipheredTokenDigest = digest.digest(cipheredToken);
             String jwtTokenDigestInHex = DatatypeConverter.printHexBinary(cipheredTokenDigest);
    
             //Search token digest in HEX in DB
             try (Connection con = this.storeDS.getConnection()) {
                 String query = "select jwt_token_digest from revoked_token where jwt_token_digest = ?";
                 try (PreparedStatement pStatement = con.prepareStatement(query)) {
                     pStatement.setString(1, jwtTokenDigestInHex);
                     try (ResultSet rSet = pStatement.executeQuery()) {
                         tokenIsPresent = rSet.next();
                     }
                 }
             }
         }
    
         return tokenIsPresent;
     }
    
    
     /**
      * Add a digest encoded in HEX of the ciphered token to the revocation token table
      *
      * @param jwtInHex Token encoded in HEX
      * @throws Exception If any issue occur during communication with DB
      */
     public void revokeToken(String jwtInHex) throws Exception {
         if (jwtInHex != null && !jwtInHex.trim().isEmpty()) {
             //Decode the ciphered token
             byte[] cipheredToken = DatatypeConverter.parseHexBinary(jwtInHex);
    
             //Compute a SHA256 of the ciphered token
             MessageDigest digest = MessageDigest.getInstance("SHA-256");
             byte[] cipheredTokenDigest = digest.digest(cipheredToken);
             String jwtTokenDigestInHex = DatatypeConverter.printHexBinary(cipheredTokenDigest);
    
             //Check if the token digest in HEX is already in the DB and add it if it is absent
             if (!this.isTokenRevoked(jwtInHex)) {
                 try (Connection con = this.storeDS.getConnection()) {
                     String query = "insert into revoked_token(jwt_token_digest) values(?)";
                     int insertedRecordCount;
                     try (PreparedStatement pStatement = con.prepareStatement(query)) {
                         pStatement.setString(1, jwtTokenDigestInHex);
                         insertedRecordCount = pStatement.executeUpdate();
                     }
                     if (insertedRecordCount != 1) {
                         throw new IllegalStateException("Number of inserted record is invalid," +
                         " 1 expected but is " + insertedRecordCount);
                     }
                 }
             }
    
         }
     }
    

### Token Information Disclosure¶

#### Symptom¶

This attack occurs when an attacker has access to a token (or a set of tokens) and extracts information stored in it (the contents of JWTs are base64 encoded, but is not encrypted by default) in order to obtain information about the system. Information can be for example the security roles, login format...

#### How to Prevent¶

A way to protect against this attack is to cipher the token using, for example, a symmetric algorithm.

It's also important to protect the ciphered data against attack like [Padding Oracle](https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/09-Testing_for_Weak_Cryptography/02-Testing_for_Padding_Oracle.html) or any other attack using cryptanalysis.

In order to achieve all these goals, the _AES-[GCM](https://en.wikipedia.org/wiki/Galois/Counter_Mode)_ algorithm is used which provides _Authenticated Encryption with Associated Data_.

More details from [here](https://github.com/google/tink/blob/master/docs/PRIMITIVES.md#deterministic-authenticated-encryption-with-associated-data):
    
    
    AEAD primitive (Authenticated Encryption with Associated Data) provides functionality of symmetric
    authenticated encryption.
    
    Implementations of this primitive are secure against adaptive chosen ciphertext attacks.
    
    When encrypting a plaintext one can optionally provide associated data that should be authenticated
    but not encrypted.
    
    That is, the encryption with associated data ensures authenticity (ie. who the sender is) and
    integrity (ie. data has not been tampered with) of that data, but not its secrecy.
    
    See RFC5116: https://tools.ietf.org/html/rfc5116
    

**Note:**

Here ciphering is added mainly to hide internal information but it's very important to remember that the first protection against tampering of the JWT is the signature. So, the token signature and its verification must be always in place.

#### Implementation Example¶

##### Token Ciphering¶

Code in charge of managing the ciphering. [Google Tink](https://github.com/google/tink) dedicated crypto library is used to handle ciphering operations in order to use built-in best practices provided by this library.
    
    
    /**
     * Handle ciphering and deciphering of the token using AES-GCM.
     *
     * @see "https://github.com/google/tink/blob/master/docs/JAVA-HOWTO.md"
     */
    public class TokenCipher {
    
        /**
         * Constructor - Register AEAD configuration
         *
         * @throws Exception If any issue occur during AEAD configuration registration
         */
        public TokenCipher() throws Exception {
            AeadConfig.register();
        }
    
        /**
         * Cipher a JWT
         *
         * @param jwt          Token to cipher
         * @param keysetHandle Pointer to the keyset handle
         * @return The ciphered version of the token encoded in HEX
         * @throws Exception If any issue occur during token ciphering operation
         */
        public String cipherToken(String jwt, KeysetHandle keysetHandle) throws Exception {
            //Verify parameters
            if (jwt == null || jwt.isEmpty() || keysetHandle == null) {
                throw new IllegalArgumentException("Both parameters must be specified!");
            }
    
            //Get the primitive
            Aead aead = AeadFactory.getPrimitive(keysetHandle);
    
            //Cipher the token
            byte[] cipheredToken = aead.encrypt(jwt.getBytes(), null);
    
            return DatatypeConverter.printHexBinary(cipheredToken);
        }
    
        /**
         * Decipher a JWT
         *
         * @param jwtInHex     Token to decipher encoded in HEX
         * @param keysetHandle Pointer to the keyset handle
         * @return The token in clear text
         * @throws Exception If any issue occur during token deciphering operation
         */
        public String decipherToken(String jwtInHex, KeysetHandle keysetHandle) throws Exception {
            //Verify parameters
            if (jwtInHex == null || jwtInHex.isEmpty() || keysetHandle == null) {
                throw new IllegalArgumentException("Both parameters must be specified !");
            }
    
            //Decode the ciphered token
            byte[] cipheredToken = DatatypeConverter.parseHexBinary(jwtInHex);
    
            //Get the primitive
            Aead aead = AeadFactory.getPrimitive(keysetHandle);
    
            //Decipher the token
            byte[] decipheredToken = aead.decrypt(cipheredToken, null);
    
            return new String(decipheredToken);
        }
    }
    

##### Creation / Validation of the Token¶

Use the token ciphering handler during the creation and the validation of the token.

Load keys (ciphering key was generated and stored using [Google Tink](https://github.com/google/tink/blob/master/docs/JAVA-HOWTO.md#generating-new-keysets)) and setup cipher.
    
    
    //Load keys from configuration text/json files in order to avoid to storing keys as a String in JVM memory
    private transient byte[] keyHMAC = Files.readAllBytes(Paths.get("src", "main", "conf", "key-hmac.txt"));
    private transient KeysetHandle keyCiphering = CleartextKeysetHandle.read(JsonKeysetReader.withFile(
    Paths.get("src", "main", "conf", "key-ciphering.json").toFile()));
    
    ...
    
    //Init token ciphering handler
    TokenCipher tokenCipher = new TokenCipher();
    

Token creation.
    
    
    //Generate the JWT token using the JWT API...
    //Cipher the token (String JSON representation)
    String cipheredToken = tokenCipher.cipherToken(token, this.keyCiphering);
    //Send the ciphered token encoded in HEX to the client in HTTP response...
    

Token validation.
    
    
    //Retrieve the ciphered token encoded in HEX from the HTTP request...
    //Decipher the token
    String token = tokenCipher.decipherToken(cipheredToken, this.keyCiphering);
    //Verify the token using the JWT API...
    //Verify access...
    

### Token Storage on Client Side¶

#### Symptom¶

This occurs when an application stores the token in a manner exhibiting the following behavior:

  * Automatically sent by the browser (_Cookie_ storage).
  * Retrieved even if the browser is restarted (Use of browser _localStorage_ container).
  * Retrieved in case of [XSS](Cross_Site_Scripting_Prevention_Cheat_Sheet.html) issue (Cookie accessible to JavaScript code or Token stored in browser local/session storage).


#### How to Prevent¶

  1. Store the token using the browser _sessionStorage_ container, or use JavaScript _closures_ with _private_ variables
  2. Add it as a _Bearer_ HTTP `Authentication` header with JavaScript when calling services.
  3. Add [fingerprint](JSON_Web_Token_for_Java_Cheat_Sheet.html#token-sidejacking) information to the token.


By storing the token in browser _sessionStorage_ container it exposes the token to being stolen through an XSS attack. However, fingerprints added to the token prevent reuse of the stolen token by the attacker on their machine. To close a maximum of exploitation surfaces for an attacker, add a browser [Content Security Policy](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html) to harden the execution context.

But, we know that _sessionStorage_ is not always practical due to its per-tab scope, and the storage method for tokens should balance _security_ and _usability_.

_LocalStorage_ is a better method than _sessionStorage_ for usability because it allows the session to persist between browser restarts and across tabs, but you must use strict security controls:

  * Tokens stored in _localStorage_ should have _short expiration times_ (e.g., _15-30 minutes idle timeout, 8-hour absolute timeout_).
  * Implement mechanisms such as _token rotation_ and _refresh tokens_ to minimize risk.


If _session persistence across tabs_ and _sessionStorage_ are required, consider using _BroadcastChannel API_ or _Single Sign-On (SSO)_ to re-authenticate users automatically when they open new tabs.

An alternative to storing token in browser _sessionStorage_ or in _localStorage_ is to use JavaScript private variable or Closures. In this, access to all web requests are routed through a JavaScript module that encapsulates the token in a private variable which can not be accessed other than from within the module.

_Note:_

  * The remaining case is when an attacker uses the user's browsing context as a proxy to use the target application through the legitimate user but the Content Security Policy can prevent communication with non expected domains.
  * It's also possible to implement the authentication service in a way that the token is issued within a hardened cookie, but in this case, protection against a [Cross-Site Request Forgery](Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html) attack must be implemented.


#### Implementation Example¶

JavaScript code to store the token after authentication.
    
    
    /* Handle request for JWT token and local storage*/
    function authenticate() {
        const login = $("#login").val();
        const postData = "login=" + encodeURIComponent(login) + "&password=test";
    
        $.post("/services/authenticate", postData, function (data) {
            if (data.status == "Authentication successful!") {
                ...
                sessionStorage.setItem("token", data.token);
            }
            else {
                ...
                sessionStorage.removeItem("token");
            }
        })
        .fail(function (jqXHR, textStatus, error) {
            ...
            sessionStorage.removeItem("token");
        });
    }
    

JavaScript code to add the token as a _Bearer_ HTTP Authentication header when calling a service, for example a service to validate token here.
    
    
    /* Handle request for JWT token validation */
    function validateToken() {
        var token = sessionStorage.getItem("token");
    
        if (token == undefined || token == "") {
            $("#infoZone").removeClass();
            $("#infoZone").addClass("alert alert-warning");
            $("#infoZone").text("Obtain a JWT token first :)");
            return;
        }
    
        $.ajax({
            url: "/services/validate",
            type: "POST",
            beforeSend: function (xhr) {
                xhr.setRequestHeader("Authorization", "bearer " + token);
            },
            success: function (data) {
                ...
            },
            error: function (jqXHR, textStatus, error) {
                ...
            },
        });
    }
    

JavaScript code to implement closures with private variables:
    
    
    function myFetchModule() {
        // Protect the original 'fetch' from getting overwritten via XSS
        const fetch = window.fetch;
    
        const authOrigins = ["https://yourorigin", "http://localhost"];
        let token = '';
    
        this.setToken = (value) => {
            token = value
        }
    
        this.fetch = (resource, options) => {
            let req = new Request(resource, options);
            destOrigin = new URL(req.url).origin;
            if (token && authOrigins.includes(destOrigin)) {
                req.headers.set('Authorization', token);
            }
            return fetch(req)
        }
    }
    
    ...
    
    // usage:
    const myFetch = new myFetchModule()
    
    function login() {
      fetch("/api/login")
          .then((res) => {
              if (res.status == 200) {
                  return res.json()
              } else {
                  throw Error(res.statusText)
              }
          })
          .then(data => {
              myFetch.setToken(data.token)
              console.log("Token received and stored.")
          })
          .catch(console.error)
    }
    
    ...
    
    // after login, subsequent api calls:
    function makeRequest() {
        myFetch.fetch("/api/hello", {headers: {"MyHeader": "foobar"}})
            .then((res) => {
                if (res.status == 200) {
                    return res.text()
                } else {
                    throw Error(res.statusText)
                }
            }).then(responseText => console.log("helloResponse", responseText))
            .catch(console.error)
    }
    

### Weak Token Secret¶

#### Symptom¶

When the token is protected using an HMAC based algorithm, the security of the token is entirely dependent on the strength of the secret used with the HMAC. If an attacker can obtain a valid JWT, they can then carry out an offline attack and attempt to crack the secret using tools such as [John the Ripper](https://github.com/magnumripper/JohnTheRipper) or [Hashcat](https://github.com/hashcat/hashcat).

If they are successful, they would then be able to modify the token and re-sign it with the key they had obtained. This could let them escalate their privileges, compromise other users' accounts, or perform other actions depending on the contents of the JWT.

There are a number of [guides](https://www.notsosecure.com/crafting-way-json-web-tokens/) that document this process in greater detail.

#### How to Prevent¶

The simplest way to prevent this attack is to ensure that the secret used to sign the JWTs is strong and unique, in order to make it harder for an attacker to crack. As this secret would never need to be typed by a human, it should be at least 64 characters, and generated using a [secure source of randomness](Cryptographic_Storage_Cheat_Sheet.html#secure-random-number-generation).

Alternatively, consider the use of tokens that are signed with RSA rather than using an HMAC and secret key.

#### Further Reading¶

  * [{JWT}.{Attack}.Playbook](https://github.com/ticarpi/jwt_tool/wiki) \- A project documents the known attacks and potential security vulnerabilities and misconfigurations of JSON Web Tokens.
  * [JWT Best Practices Internet Draft](https://datatracker.ietf.org/doc/draft-ietf-oauth-jwt-bcp/)


©Copyright  \- Cheat Sheets Series Team - This work is licensed under [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/). 

Made with [ Material for MkDocs ](https://squidfunk.github.io/mkdocs-material/)
