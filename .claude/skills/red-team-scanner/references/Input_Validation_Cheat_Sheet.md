Skip to content 

[ ](../index.html "OWASP Cheat Sheet Series")

OWASP Cheat Sheet Series 

Input Validation 

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
    * Input Validation  [ Input Validation  ](Input_Validation_Cheat_Sheet.html) Table of contents 
      * Introduction 
      * Goals of Input Validation 
      * Input Validation Strategies 
      * Implementing Input Validation 
        * Allowlist vs Denylist 
        * Validating Free-form Unicode Text 
        * Regular Expressions (Regex) 
      * Allow List Regular Expression Examples 
      * Client-side vs Server-side Validation 
      * Validating Rich User Content 
      * Preventing XSS and Content Security Policy 
      * File Upload Validation 
        * Upload Verification 
        * Upload Storage 
        * Public Serving of Uploaded Content 
        * Beware of Specific File Types 
        * Image Upload Verification 
      * Email Address Validation 
        * Syntactic Validation 
        * Semantic Validation 
          * Disposable Email Addresses 
          * Sub-Addressing 
      * References 
    * [ Insecure Direct Object Reference Prevention  ](Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.html)
    * [ JAAS  ](JAAS_Cheat_Sheet.html)
    * [ JSON Web Token for Java  ](JSON_Web_Token_for_Java_Cheat_Sheet.html)
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
  * Goals of Input Validation 
  * Input Validation Strategies 
  * Implementing Input Validation 
    * Allowlist vs Denylist 
    * Validating Free-form Unicode Text 
    * Regular Expressions (Regex) 
  * Allow List Regular Expression Examples 
  * Client-side vs Server-side Validation 
  * Validating Rich User Content 
  * Preventing XSS and Content Security Policy 
  * File Upload Validation 
    * Upload Verification 
    * Upload Storage 
    * Public Serving of Uploaded Content 
    * Beware of Specific File Types 
    * Image Upload Verification 
  * Email Address Validation 
    * Syntactic Validation 
    * Semantic Validation 
      * Disposable Email Addresses 
      * Sub-Addressing 
  * References 


# Input Validation Cheat Sheet¶

## Introduction¶

This article is focused on providing clear, simple, actionable guidance for providing Input Validation security functionality in your applications.

## Goals of Input Validation¶

Input validation is performed to ensure only properly formed data is entering the workflow in an information system, preventing malformed data from persisting in the database and triggering malfunction of various downstream components. Input validation should happen as early as possible in the data flow, preferably as soon as the data is received from the external party.

Data from all potentially untrusted sources should be subject to input validation, including not only Internet-facing web clients but also backend feeds over extranets, from [suppliers, partners, vendors or regulators](https://badcyber.com/several-polish-banks-hacked-information-stolen-by-unknown-attackers/), each of which may be compromised on their own and start sending malformed data.

Input Validation should not be used as the _primary_ method of preventing [XSS](Cross_Site_Scripting_Prevention_Cheat_Sheet.html), [SQL Injection](SQL_Injection_Prevention_Cheat_Sheet.html) and other attacks which are covered in respective [cheat sheets](https://cheatsheetseries.owasp.org/) but can significantly contribute to reducing their impact if implemented properly.

## Input Validation Strategies¶

Input validation should be applied at both syntactic and semantic levels:

  * **Syntactic** validation should enforce correct syntax of structured fields (e.g. SSN, date, currency symbol).
  * **Semantic** validation should enforce correctness of their _values_ in the specific business context (e.g. start date is before end date, price is within expected range).


It is always recommended to prevent attacks as early as possible in the processing of the user's (attacker's) request. Input validation can be used to detect unauthorized input before it is processed by the application.

## Implementing Input Validation¶

Input validation can be implemented using any programming technique that allows effective enforcement of syntactic and semantic correctness, for example:

  * Data type validators available natively in web application frameworks (such as [Django Validators](https://docs.djangoproject.com/en/1.11/ref/validators/), [Apache Commons Validators](https://commons.apache.org/proper/commons-validator/apidocs/org/apache/commons/validator/package-summary.html#doc.Usage.validator) etc).
  * Validation against [JSON Schema](http://json-schema.org/) and [XML Schema (XSD)](https://www.w3schools.com/xml/schema_intro.asp) for input in these formats.
  * Type conversion (e.g. `Integer.parseInt()` in Java, `int()` in Python) with strict exception handling
  * Minimum and maximum value range check for numerical parameters and dates, minimum and maximum length check for strings.
  * Array of allowed values for small sets of string parameters (e.g. days of week).
  * Regular expressions for any other structured data covering the whole input string `(^...$)` and **not** using "any character" wildcard (such as `.` or `\S`)
  * Denylisting known dangerous patterns can be used as an additional layer of defense, but it should supplement - not replace - allowlisting, to help catch some commonly observed attacks or patterns without relying on it as the main validation method.


### Allowlist vs Denylist¶

It is a common mistake to use denylist validation in order to try to detect possibly dangerous characters and patterns like the apostrophe `'` character, the string `1=1`, or the `<script>` tag, but this is a massively flawed approach as it is trivial for an attacker to bypass such filters.

Plus, such filters frequently prevent authorized input, like `O'Brian`, where the `'` character is fully legitimate. For more information on XSS filter evasion please see [this wiki page](https://owasp.org/www-community/xss-filter-evasion-cheatsheet).

While denylisting can be useful as an additional layer of defense to catch some common malicious patterns, it should not be relied upon as the primary method. Allowlisting remains the more robust and secure approach for preventing potentially harmful input.

Allowlist validation is appropriate for all input fields provided by the user. Allowlist validation involves defining exactly what IS authorized, and by definition, everything else is not authorized.

If it's well structured data, like dates, social security numbers, zip codes, email addresses, etc. then the developer should be able to define a very strong validation pattern, usually based on regular expressions, for validating such input.

If the input field comes from a fixed set of options, like a drop down list or radio buttons, then the input needs to match exactly one of the values offered to the user in the first place. Any failure to validate a value against this discrete list of options on the server side is a high security event and should be logged as a high severity event as it indicates that an attacker is tampering with the client-side code.

### Validating Free-form Unicode Text¶

Free-form text, especially with Unicode characters, is perceived as difficult to validate due to a relatively large space of characters that need to be allowed.

It's also free-form text input that highlights the importance of proper context-aware output encoding and quite clearly demonstrates that input validation is **not** the primary safeguards against Cross-Site Scripting. If your users want to type apostrophe `'` or less-than sign `<` in their comment field, they might have perfectly legitimate reason for that and the application's job is to properly handle it throughout the whole life cycle of the data.

The primary means of input validation for free-form text input should be:

  * **Normalization:** Ensure canonical encoding is used across all the text and no invalid characters are present.
  * **Character category allowlisting:** Unicode allows listing categories such as "decimal digits" or "letters" which not only covers the Latin alphabet but also various other scripts used globally (e.g. Arabic, Cyrillic, CJK ideographs etc).
  * **Individual character allowlisting:** If you allow letters and ideographs in names and also want to allow apostrophe `'` for Irish names, but don't want to allow the whole punctuation category.


References:

  * [Input validation of free-form Unicode text in Python](https://web.archive.org/web/20170717174432/https://ipsec.pl/python/2017/input-validation-free-form-unicode-text-python.html/)
  * [UAX 31: Unicode Identifier and Pattern Syntax](https://unicode.org/reports/tr31/)
  * [UAX 15: Unicode Normalization Forms](https://www.unicode.org/reports/tr15/)
  * [UAX 24: Unicode Script Property](https://unicode.org/reports/tr24/)


### Regular Expressions (Regex)¶

Developing regular expressions can be complicated, and is well beyond the scope of this cheat sheet.

There are lots of resources on the internet about how to write regular expressions, including this [site](https://www.regular-expressions.info/) and the [OWASP Validation Regex Repository](https://owasp.org/www-community/OWASP_Validation_Regex_Repository).

When designing regular expression, be aware of [RegEx Denial of Service (ReDoS) attacks](https://owasp.org/www-community/attacks/Regular_expression_Denial_of_Service_-_ReDoS). These attacks cause a program using a poorly designed Regular Expression to operate very slowly and utilize CPU resources for a very long time.

In summary, input validation should:

  * Be applied to all input data, at minimum.
  * Define the allowed set of characters to be accepted.
  * Define a minimum and maximum length for the data (e.g. `{1,25}`).


## Allow List Regular Expression Examples¶

Validating a U.S. Zip Code (5 digits plus optional -4)
    
    
    ^\d{5}(-\d{4})?$
    

Validating U.S. State Selection From a Drop-Down Menu
    
    
    ^(AA|AE|AP|AL|AK|AS|AZ|AR|CA|CO|CT|DE|DC|FM|FL|GA|GU|
    HI|ID|IL|IN|IA|KS|KY|LA|ME|MH|MD|MA|MI|MN|MS|MO|MT|NE|
    NV|NH|NJ|NM|NY|NC|ND|MP|OH|OK|OR|PW|PA|PR|RI|SC|SD|TN|
    TX|UT|VT|VI|VA|WA|WV|WI|WY)$
    

**Java Regex Usage Example:**

Example validating the parameter "zip" using a regular expression.
    
    
    private static final Pattern zipPattern = Pattern.compile("^\d{5}(-\d{4})?$");
    
    public void doPost( HttpServletRequest request, HttpServletResponse response) {
      try {
          String zipCode = request.getParameter( "zip" );
          if ( !zipPattern.matcher( zipCode ).matches() ) {
              throw new YourValidationException( "Improper zipcode format." );
          }
          // do what you want here, after its been validated ..
      } catch(YourValidationException e ) {
          response.sendError( response.SC_BAD_REQUEST, e.getMessage() );
      }
    }
    

Some Allowlist validators have also been predefined in various open source packages that you can leverage. For example:

  * [Apache Commons Validator](http://commons.apache.org/proper/commons-validator/)


## Client-side vs Server-side Validation¶

Input validation **must** be implemented on the server-side before any data is processed by an application’s functions, as any JavaScript-based input validation performed on the client-side can be circumvented by an attacker who disables JavaScript or uses a web proxy. Implementing both client-side JavaScript-based validation for UX and server-side validation for security is the recommended approach, leveraging each for their respective strengths.

## Validating Rich User Content¶

It is very difficult to validate rich content submitted by a user. For more information, please see the XSS cheat sheet on [Sanitizing HTML Markup with a Library Designed for the Job](Cross_Site_Scripting_Prevention_Cheat_Sheet.html).

## Preventing XSS and Content Security Policy¶

All user data controlled must be encoded when returned in the HTML page to prevent the execution of malicious data (e.g. XSS). For example `<script>` would be returned as `&lt;script&gt;`

The type of encoding is specific to the context of the page where the user controlled data is inserted. For example, HTML entity encoding is appropriate for data placed into the HTML body. However, user data placed into a script would need JavaScript specific output encoding.

Detailed information on XSS prevention here: [OWASP XSS Prevention Cheat Sheet](Cross_Site_Scripting_Prevention_Cheat_Sheet.html)

## File Upload Validation¶

Many websites allow users to upload files, such as a profile picture or more. This section helps provide that feature securely.

Check the [File Upload Cheat Sheet](File_Upload_Cheat_Sheet.html).

### Upload Verification¶

  * Use input validation to ensure the uploaded filename uses an expected extension type.
  * Ensure the uploaded file is not larger than a defined maximum file size.
  * If the website supports ZIP file upload, do a validation check before unzipping the file. The check includes the target path, level of compression, estimated unzip size.


### Upload Storage¶

  * Use a new filename to store the file on the OS. Do not use any user controlled text for this filename or for the temporary filename.
  * When the file is uploaded to web, it's suggested to rename the file on storage. For example, the uploaded filename is _test.JPG_ , rename it to _JAI1287uaisdjhf.JPG_ with a random filename. The purpose of doing it to prevent the risks of direct file access and ambiguous filename to evade the filter, such as `test.jpg;.asp or /../../../../../test.jpg`.
  * Uploaded files should be analyzed for malicious content (anti-malware, static analysis, etc).
  * The client should not be able to specify the file path; it should be defined by the server.


### Public Serving of Uploaded Content¶

  * Ensure uploaded images are served with the correct content-type (e.g. `image/jpeg`, `application/x-xpinstall`)


### Beware of Specific File Types¶

The upload feature should be using an allowlist approach to only allow specific file types and extensions. However, it is important to be aware of the following file types that, if allowed, could result in security vulnerabilities:

  * **crossdomain.xml** / **clientaccesspolicy.xml:** allows cross-domain data loading in Flash, Java and Silverlight. If permitted on sites with authentication this can permit cross-domain data theft and CSRF attacks. Note this can get pretty complicated depending on the specific plugin version in question, so its best to just prohibit files named "crossdomain.xml" or "clientaccesspolicy.xml".
  * **.htaccess** and **.htpasswd:** Provides server configuration options on a per-directory basis, and should not be permitted. See [HTACCESS documentation](http://en.wikipedia.org/wiki/Htaccess).
  * Web executable script files are suggested not to be allowed such as `aspx, asp, css, swf, xhtml, rhtml, shtml, jsp, js, pl, php, cgi`.


### Image Upload Verification¶

  * Use image rewriting libraries to verify the image is valid and to strip away extraneous content.
  * Set the extension of the stored image to be a valid image extension based on the detected content type of the image from image processing (e.g. do not just trust the header from the upload).
  * Ensure the detected content type of the image is within a list of defined image types (jpg, PNG, etc)


## Email Address Validation¶

### Syntactic Validation¶

The format of email addresses is defined by [RFC 5321](https://tools.ietf.org/html/rfc5321#section-4.1.2), and is far more complicated than most people realise. As an example, the following are all considered to be valid email addresses:

  * `"><script>alert(1);</script>"@example.org`
  * `user+subaddress@example.org`
  * `user@[IPv6:2001:db8::1]`
  * `" "@example.org`


Properly parsing email addresses for validity with regular expressions is very complicated, although there are a number of [publicly available documents on regex](https://datatracker.ietf.org/doc/html/draft-seantek-mail-regexen-03#rfc.section.3).

The biggest caveat on this is that although the RFC defines a very flexible format for email addresses, most real world implementations (such as mail servers) use a far more restricted address format, meaning that they will reject addresses that are _technically_ valid. Although they may be technically correct, these addresses are of little use if your application will not be able to actually send emails to them.

As such, the best way to validate email addresses is to perform some basic initial validation, and then pass the address to the mail server and catch the exception if it rejects it. This means that the application can be confident that its mail server can send emails to any addresses it accepts. The initial validation could be as simple as:

  * The email address contains two parts, separated with an `@` symbol.
  * The email address does not contain dangerous characters (such as backticks, single or double quotes, or null bytes).
    * Exactly which characters are dangerous will depend on how the address is going to be used (echoed in page, inserted into database, etc).
  * The domain part contains only letters, numbers, hyphens (`-`) and periods (`.`).
  * The email address is a reasonable length:
    * The local part (before the `@`) should be no more than 63 characters.
    * The total length should be no more than 254 characters.


### Semantic Validation¶

Semantic validation is about determining whether the email address is correct and legitimate. The most common way to do this is to send an email to the user, and require that they click a link in the email, or enter a code that has been sent to them. This provides a basic level of assurance that:

  * The email address is correct.
  * The application can successfully send emails to it.
  * The user has access to the mailbox.


The links that are sent to users to prove ownership should contain a token that is:

  * At least 32 characters long.
  * Generated using a [secure source of randomness](Cryptographic_Storage_Cheat_Sheet.html#secure-random-number-generation).
  * Single use.
  * Time limited (e.g, expiring after eight hours).


After validating the ownership of the email address, the user should then be required to authenticate on the application through the usual mechanism.

#### Disposable Email Addresses¶

In some cases, users may not want to give their real email address when registering on the application, and will instead provide a disposable email address. These are publicly available addresses that do not require the user to authenticate, and are typically used to reduce the amount of spam received by users' primary email addresses.

Blocking disposable email addresses is almost impossible, as there are a large number of websites offering these services, with new domains being created every day. There are a number of publicly available lists and commercial lists of known disposable domains, but these will always be incomplete.

If these lists are used to block the use of disposable email addresses then the user should be presented with a message explaining why they are blocked (although they are likely to simply search for another disposable provider rather than giving their legitimate address).

If it is essential that disposable email addresses are blocked, then registrations should only be allowed from specifically-allowed email providers. However, if this includes public providers such as Google or Yahoo, users can simply register their own disposable address with them.

#### Sub-Addressing¶

Sub-addressing allows a user to specify a _tag_ in the local part of the email address (before the `@` sign), which will be ignored by the mail server. For example, if that `example.org` domain supports sub-addressing, then the following email addresses are equivalent:

  * `user@example.org`
  * `user+site1@example.org`
  * `user+site2@example.org`


Many mail providers (such as Microsoft Exchange) do not support sub-addressing. The most notable provider who does is Gmail, although there are many others that also do.

Some users will use a different _tag_ for each website they register on, so that if they start receiving spam to one of the sub-addresses they can identify which website leaked or sold their email address.

Because it could allow users to register multiple accounts with a single email address, some sites may wish to block sub-addressing by stripping out everything between the `+` and `@` signs. This is not generally recommended, as it suggests that the website owner is either unaware of sub-addressing or wishes to prevent users from identifying them when they leak or sell email addresses. Additionally, it can be trivially bypassed by using disposable email addresses, or simply registering multiple email accounts with a trusted provider.

## References¶

  * [OWASP Top 10 Proactive Controls 2024: C3: Validate all Input & Handle Exceptions](https://top10proactive.owasp.org/the-top-10/c3-validate-input-and-handle-exceptions)
  * [CWE-20 Improper Input Validation](https://cwe.mitre.org/data/definitions/20.html)
  * [OWASP Top 10 2021: A03:2021-Injection](https://owasp.org/Top10/A03_2021-Injection/)
  * [Snyk: Improper Input Validation](https://learn.snyk.io/lesson/improper-input-validation/)


©Copyright  \- Cheat Sheets Series Team - This work is licensed under [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/). 

Made with [ Material for MkDocs ](https://squidfunk.github.io/mkdocs-material/)
