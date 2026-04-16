Skip to content 

[ ](../index.html "OWASP Cheat Sheet Series")

OWASP Cheat Sheet Series 

AJAX Security 

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
    * AJAX Security  [ AJAX Security  ](AJAX_Security_Cheat_Sheet.html) Table of contents 
      * Introduction 
        * Client-Side (JavaScript) 
          * Use innerHTML with extreme caution 
            * What is innerHTML? 
            * Why does innerHTML require extreme caution? 
              * Vulnerable Example 
            * When is innerHTML acceptable? 
            * Alternatives 
          * Use of textContent or innerText for DOM updates (for text-only content) 
            * What is textContent? 
            * What is innerText? 
            * When to Use textContent vs. innerText 
            * Note 
          * Don't use eval(), new Function() or other code evaluation tools 
          * Encode Data Before Use in an Output Context 
          * Don't rely on client logic for security 
          * Don't rely on client business logic 
          * Avoid writing serialization code 
          * Avoid building XML or JSON dynamically 
          * Never transmit secrets to the client 
          * Don't perform encryption in client-side code 
          * Don't perform security impacting logic on client-side 
        * Server-Side 
          * Use CSRF Protection 
          * Protect against JSON hijacking for older browsers 
            * Review AngularJS JSON hijacking defense mechanism 
            * Always return JSON with an object on the outside 
          * Avoid writing serialization code server-side 
          * Services can be called directly by users 
          * Avoid building XML or JSON by hand, use the framework 
          * Use JSON and XML schema for web services 
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
    * Client-Side (JavaScript) 
      * Use innerHTML with extreme caution 
        * What is innerHTML? 
        * Why does innerHTML require extreme caution? 
          * Vulnerable Example 
        * When is innerHTML acceptable? 
        * Alternatives 
      * Use of textContent or innerText for DOM updates (for text-only content) 
        * What is textContent? 
        * What is innerText? 
        * When to Use textContent vs. innerText 
        * Note 
      * Don't use eval(), new Function() or other code evaluation tools 
      * Encode Data Before Use in an Output Context 
      * Don't rely on client logic for security 
      * Don't rely on client business logic 
      * Avoid writing serialization code 
      * Avoid building XML or JSON dynamically 
      * Never transmit secrets to the client 
      * Don't perform encryption in client-side code 
      * Don't perform security impacting logic on client-side 
    * Server-Side 
      * Use CSRF Protection 
      * Protect against JSON hijacking for older browsers 
        * Review AngularJS JSON hijacking defense mechanism 
        * Always return JSON with an object on the outside 
      * Avoid writing serialization code server-side 
      * Services can be called directly by users 
      * Avoid building XML or JSON by hand, use the framework 
      * Use JSON and XML schema for web services 


# AJAX Security Cheat Sheet¶

## Introduction¶

This document will provide a starting point for AJAX security and will hopefully be updated and expanded reasonably often to provide more detailed information about specific frameworks and technologies.

**Before applying any specific control, developers must adopt a fundamental security mindset:** All data should be considered untrusted unless explicitly validated and safely handled. This applies to:

  * Client-side input
  * API response
  * Third-party integrations
  * Internal services and microservices
  * Cached responses
  * Browser storage (localStorage, sessionStorage)
  * Hidden form fields


### Client-Side (JavaScript)¶

#### Use `innerHTML` with extreme caution¶

Manipulating the Document Object Model (DOM) is common in web applications, especially in monolithic server-side rendering (e.g., PHP, ASP.NET) and AJAX-driven applications. While `innerHTML` seems like a convenient way to inject HTML content, it poses significant security risks on untrusted-data, particularly cross-site scripting (XSS).

##### What is `innerHTML`?¶

The `innerHTML` property sets or gets the HTML content of an element, including tags, which the browser parses and renders as part of the DOM. For example, setting `innerHTML = "<p>Hello</p>"` creates a paragraph element.

##### Why does `innerHTML` require extreme caution?¶

Using `innerHTML` with untrusted data (e.g., from API responses in AJAX) can allow malicious JavaScript to execute in the user’s browser, leading to XSS vulnerabilities. Potential risks include:

  * Stealing user session cookies.
  * Defacing the website.
  * Redirecting users to malicious sites.
  * Performing unauthorized actions (e.g., API calls on behalf of the user).
  * Keylogging user inputs.


###### Vulnerable Example¶
    
    
        document.getElementById('content').innerHTML = data; 
        // DANGER! The server may have returned a payload that executes scripts, for example: <img src=abc onerror=alert('xss!')>.
    

##### When is `innerHTML` acceptable?¶

The fundamental security rule is to never use innerHTML with untrusted data. However, in limited cases, such as legacy monolithic applications with no viable alternatives, innerHTML may be used cautiously:

  * **Static, Hardcoded HTML** : For small, fixed HTML snippets that are part of your application’s source code and contain no user input:


    
    
    document.getElementById('footer').innerHTML = '<p>© 2025 My Company. All rights reserved.</p>';
    

  * **Sanitized HTML** : For user-generated HTML (e.g., in rich text editors), sanitize with a library like [DOMPurify](DOM_Clobbering_Prevention_Cheat_Sheet.html#1-html-sanitization) before using innerHTML:


    
    
    import DOMPurify from 'dompurify';
    const userInput = '<img src=abc onerror=alert("xss")>';
    document.getElementById('content').innerHTML = DOMPurify.sanitize(userInput); // Safe, removes malicious code
    

##### Alternatives¶

  * Use Templating Engines (with auto-escaping) for reusable, structured HTML snippets.
  * Use Modern Frameworks (React, Vue, Angular, Svelte) for complex applications. They standardize DOM manipulation, provide reactivity, and inherently handle sanitization for dynamic data. However, developers must avoid unsafe APIs (e.g., `dangerouslySetInnerHTML` in React, `[innerHTML]` in Angular) to prevent XSS vulnerabilities.


#### Use of `textContent` or `innerText` for DOM updates (for text-only content)¶

In AJAX and monolithic server-side rendering applications (e.g., PHP, ASP.NET), dynamic Document Object Model (DOM) updates are common for rendering text-only content from APIs or user inputs.

##### What is `textContent`?¶

The `textContent` property sets or gets the plain text content of an element. It treats inserted HTML tags as literal text and does not parse them. It is ideal for most text-only updates, such as displaying user comments, etc.
    
    
    const userInput = '<script>alert("OWASP")</script>';
    document.getElementById('content').textContent = userInput; // Displays plain text
    

##### What is `innerText`?¶

The `innerText` property sets or gets the visible text content of an element, respecting CSS styling (e.g., ignoring text in `display: none` elements). It also reflects rendered text formatting, such as line breaks or spacing.
    
    
    const userInput = 'OWASP'; 
    document.getElementById('content').innerText = userInput;
    

##### When to Use `textContent` vs. `innerText`¶

  * **Use`textContent`**: Use textContent in monolithic applications to safely insert plain text content returned from APIs.
  * **Use`innerText`**: Only when CSS visibility or rendered text formatting (e.g. ignoring text in `display: none` elements) is required.


> Note: `textContent` is slightly faster and more predictable; use it unless you need to respect rendered text formatting (`innerText`).

##### Note¶

  * While `textContent` and `innerText` are safe for inserting plain text into the DOM, they do not protect against XSS in other contexts such as HTML attributes, JavaScript event handlers, or URLs. Always validate and sanitize untrusted input.
  * Modern Frameworks like React, Vue, Angular, or Svelte automatically update text-only content so there is no need to manually use `textContent` or `innerText`.


#### Don't use `eval()`, `new Function()` or other code evaluation tools¶

`eval()` function is dangerous, never use it. Needing to use eval() usually indicates a problem in your design.

> Note: Using `eval()` or `new Function()` opens doors to remote code execution and XSS. Avoid it entirely.

#### Encode Data Before Use in an Output Context¶

When using data to build HTML, script, CSS, XML, JSON, etc., make sure you take into account how that data must be presented in a literal sense to keep its logical meaning.

Data should be properly encoded before being used in this manner to prevent injection style issues, and to make sure the logical meaning is preserved.

[Check out the OWASP Java Encoder Project.](https://owasp.org/www-project-java-encoder/)

#### Don't rely on client logic for security¶

Don't forget that the user controls the client-side logic. A number of browser plugins are available to set breakpoints, skip code, change values, etc. Never rely on client logic for security.

#### Don't rely on client business logic¶

As with security logic, make sure any important business rules are duplicated on the server side so a user cannot bypass them, which could lead to unexpected or costly behavior.

#### Avoid writing serialization code¶

This is hard and even a small mistake can cause large security issues. There are already a lot of frameworks to provide this functionality.

Refer to the [JSON page](https://www.json.org/) for more info.

#### Avoid building XML or JSON dynamically¶

Just like building HTML or SQL you may cause XML injection bugs, so stay away from this or at least use an encoding library or safe JSON or XML library to make attributes and element data safe.

  * [XSS (Cross Site Scripting) Prevention](Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
  * [SQL Injection Prevention](SQL_Injection_Prevention_Cheat_Sheet.html)


#### Never transmit secrets to the client¶

Anything sent to the client can be read or modified by the user, so keep all that secret stuff on the server please.

#### Don't perform encryption in client-side code¶

Use TLS/SSL and encrypt on the server!

#### Don't perform security impacting logic on client-side¶

This principle serves as a fail-safe—if a security decision is ambiguous, perform it on the server.

### Server-Side¶

#### Use CSRF Protection¶

Take a look at the [Cross-Site Request Forgery (CSRF) Prevention](Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html) cheat sheet.

#### Protect against JSON hijacking for older browsers¶

##### Review AngularJS JSON hijacking defense mechanism¶

See the [JSON Vulnerability Protection](https://docs.angularjs.org/api/ng/service/$http#json-vulnerability-protection) section of the AngularJS documentation.

##### Always return JSON with an object on the outside¶

Always have the outside primitive be an object for JSON strings:

**Exploitable:**
    
    
    [{"object": "inside an array"}]
    

**Not exploitable:**
    
    
    {"object": "not inside an array"}
    

**Also not exploitable:**
    
    
    {"result": [{"object": "inside an array"}]}
    

#### Avoid writing serialization code server-side¶

Remember reference vs. value types; use a reviewed library.

#### Services can be called directly by users¶

Even though you only expect your AJAX client-side code to call those services, a malicious user can also call them directly.

Validate inputs and treat them as if they are under user control.

#### Avoid building XML or JSON by hand, use the framework¶

Use the framework to serialize data; building payloads by hand can introduce security issues.

#### Use JSON and XML schema for web services¶

Use a third-party library to validate web service inputs.

©Copyright  \- Cheat Sheets Series Team - This work is licensed under [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/). 

Made with [ Material for MkDocs ](https://squidfunk.github.io/mkdocs-material/)
