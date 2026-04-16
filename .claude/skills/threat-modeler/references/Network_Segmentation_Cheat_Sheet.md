Skip to content 

[ ](../index.html "OWASP Cheat Sheet Series")

OWASP Cheat Sheet Series 

Network Segmentation 

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
    * Network Segmentation  [ Network Segmentation  ](Network_Segmentation_Cheat_Sheet.html) Table of contents 
      * Introduction 
      * Content 
      * Schematic symbols 
      * Three-layer network architecture 
        * FRONTEND 
        * MIDDLEWARE 
        * BACKEND 
        * Example of Three-layer network architecture 
      * Interservice interaction 
        * Many applications on the same network 
      * Network security policy 
        * Examples of individual policy provisions 
          * Permissions for CI/CD 
          * Secure logging 
          * Permissions for monitoring systems 
      * Useful links 
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
  * Content 
  * Schematic symbols 
  * Three-layer network architecture 
    * FRONTEND 
    * MIDDLEWARE 
    * BACKEND 
    * Example of Three-layer network architecture 
  * Interservice interaction 
    * Many applications on the same network 
  * Network security policy 
    * Examples of individual policy provisions 
      * Permissions for CI/CD 
      * Secure logging 
      * Permissions for monitoring systems 
  * Useful links 


# Network segmentation Cheat Sheet¶

## Introduction¶

Network segmentation is the core of multi-layer defense in depth for modern services. Segmentation slow down an attacker if he cannot implement attacks such as:

  * SQL-injections, see [SQL Injection Prevention Cheat Sheet](SQL_Injection_Prevention_Cheat_Sheet.html);
  * compromise of workstations of employees with elevated privileges;
  * compromise of another server in the perimeter of the organization;
  * compromise of the target service through the compromise of the LDAP directory, DNS server, and other corporate services and sites published on the Internet.


The main goal of this cheat sheet is to show the basics of network segmentation to effectively counter attacks by building a secure and maximally isolated service network architecture.

Segmentation will avoid the following situations:

  * executing arbitrary commands on a public web server (NginX, Apache, Internet Information Service) prevents an attacker from gaining direct access to the database;
  * having unauthorized access to the database server, an attacker cannot access CnC on the Internet.


## Content¶

  * Schematic symbols;
  * Three-layer network architecture;
  * Interservice interaction;
  * Network security policy;
  * Useful links.


## Schematic symbols¶

Elements used in network diagrams:

Crossing the border of the rectangle means crossing the firewall: 

In the image above, traffic passes through two firewalls with the names FW1 and FW2

In the image above, traffic passes through one firewall, behind which there are two VLANs

Further, the schemes do not contain firewall icons so as not to overload the schemes

## Three-layer network architecture¶

By default, developed information systems should consist of at least three components (**security zones**):

  1. [FRONTEND](Network_Segmentation_Cheat_Sheet.html#FRONTEND);
  2. [MIDDLEWARE](Network_Segmentation_Cheat_Sheet.html#MIDDLEWARE);
  3. [BACKEND](Network_Segmentation_Cheat_Sheet.html#BACKEND).


### FRONTEND¶

FRONTEND - A frontend is a set of segments with the following network elements:

  * balancer;
  * application layer firewall;
  * web server;
  * web cache.


### MIDDLEWARE¶

MIDDLEWARE - a set of segments to accommodate the following network elements:

  * web applications that implement the logic of the information system (processing requests from clients, other services of the company and external services; execution of requests);
  * authorization services;
  * analytics services;
  * message queues;
  * stream processing platform.


### BACKEND¶

BACKEND - a set of network segments to accommodate the following network elements:

  * SQL database;
  * LDAP directory (Domain controller);
  * storage of cryptographic keys;
  * file server.


### Example of Three-layer network architecture¶

The following example shows an organization's local network. The organization is called "Сontoso".

The edge firewall contains 2 VLANs of **FRONTEND** security zone:

  * _DMZ Inbound_ \- a segment for hosting services and applications accessible from the Internet, they must be protected by WAF;
  * _DMZ Outgoing_ \- a segment for hosting services that are inaccessible from the Internet, but have access to external networks (the firewall does not contain any rules for allowing traffic from external networks).


The internal firewall contains 4 VLANs:

  * **MIDDLEWARE** security zone contains only one VLAN with name _APPLICATIONS_ \- a segment designed to host information system applications that interact with each other (interservice communication) and interact with other services;
  * **BACKEND** security zone contains:
    * _DATABASES_ \- a segment designed to delimit various databases of an automated system;
    * _AD SERVICES_ \- segment designed to host various Active Directory services, in the example only one server with a domain controller Contoso.com is shown;
    * _LOGS_ \- segment, designed to host servers with logs, servers centrally store application logs of an automated system.


## Interservice interaction¶

Usually some information systems of the company interact with each other. It is important to define a firewall policy for such interactions. The base allowed interactions are indicated by the green arrows in the image below:  The image above also shows the allowed access from the FRONTEND and MIDDLEWARE segments to external networks (the Internet, for example).

From this image follows:

  1. Access between FRONTEND and MIDDLEWARE segments of different information systems is prohibited;
  2. Access from the MIDDLEWARE segment to the BACKEND segment of another service is prohibited (access to a foreign database bypassing the application server is prohibited).


Forbidden accesses are indicated by red arrows in the image below: 

### Many applications on the same network¶

If you prefer to have fewer networks in your organization and host more applications on each network, it is acceptable to host the load balancer on those networks. This balancer will balance traffic to applications on the network. In this case, it will be necessary to open one port to such a network, and balancing will be performed, for example, based on the HTTP request parameters. An example of such segmentation: 

As you can see, there is only one incoming access to each network, access is opened up to the balancer in the network. However, in this case, segmentation no longer works, access control between applications from different network segments is performed at the 7th level of the OSI model using a balancer.

## Network security policy¶

The organization must define a "paper" policy that describes firewall rules and basic allowed network access. This policy is at least useful:

  * network administrators;
  * security representatives;
  * IT auditors;
  * architects of information systems and software;
  * developers;
  * IT administrators.


It is convenient when the policy is described by similar images. The information is presented as concisely and simply as possible.

### Examples of individual policy provisions¶

Examples in the network policy will help colleagues quickly understand what access is potentially allowed and can be requested.

#### Permissions for CI/CD¶

The network security policy may define, for example, the basic permissions allowed for the software development system. Let's look at an example of what such a policy might look like: 

#### Secure logging¶

It is important that in the event of a compromise of any information system, its logs are not subsequently modified by an attacker. To do this, you can do the following: copy the logs to a separate server, for example, using the syslog protocol, which does not allow an attacker to modify the logs, syslog only allows you to add new events to the logs. The network security policy for this activity looks like this:  In this example, we are also talking about application logs that may contain security events, as well as potentially important events that may indicate an attack.

#### Permissions for monitoring systems¶

Suppose a company uses Zabbix as an IT monitoring system. In this case, the policy might look like this: 

## Useful links¶

  * Full network segmentation cheat sheet by [sergiomarotco](https://github.com/sergiomarotco): [link](https://github.com/sergiomarotco/Network-segmentation-cheat-sheet).


©Copyright  \- Cheat Sheets Series Team - This work is licensed under [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/). 

Made with [ Material for MkDocs ](https://squidfunk.github.io/mkdocs-material/)
