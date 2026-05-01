Skip to content 

[ ](../index.html "OWASP Cheat Sheet Series")

OWASP Cheat Sheet Series 

Error Handling 

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
    * Error Handling  [ Error Handling  ](Error_Handling_Cheat_Sheet.html) Table of contents 
      * Introduction 
      * Context 
      * Objective 
      * Proposition 
        * Standard Java Web Application 
        * Java SpringMVC/SpringBoot web application 
        * ASP NET Core web application 
        * ASP NET Web API web application 
      * Sources of the prototype 
      * Appendix HTTP Errors 
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
  * Context 
  * Objective 
  * Proposition 
    * Standard Java Web Application 
    * Java SpringMVC/SpringBoot web application 
    * ASP NET Core web application 
    * ASP NET Web API web application 
  * Sources of the prototype 
  * Appendix HTTP Errors 


# Error Handling Cheat Sheet¶

## Introduction¶

Error handling is a part of the overall security of an application. Except in movies, an attack always begins with a **Reconnaissance** phase in which the attacker will try to gather as much technical information (often _name_ and _version_ properties) as possible about the target, such as the application server, frameworks, libraries, etc.

Unhandled errors can assist an attacker in this initial phase, which is very important for the rest of the attack.

The following [link](https://web.archive.org/web/20230929111320/https://cipher.com/blog/a-complete-guide-to-the-phases-of-penetration-testing/) provides a description of the different phases of an attack.

## Context¶

Issues at the error handling level can reveal a lot of information about the target and can also be used to identify injection points in the target's features.

Below is an example of the disclosure of a technology stack, here the Struts2 and Tomcat versions, via an exception rendered to the user:
    
    
    HTTP Status 500 - For input string: "null"
    
    type Exception report
    
    message For input string: "null"
    
    description The server encountered an internal error that prevented it from fulfilling this request.
    
    exception
    
    java.lang.NumberFormatException: For input string: "null"
        java.lang.NumberFormatException.forInputString(NumberFormatException.java:65)
        java.lang.Integer.parseInt(Integer.java:492)
        java.lang.Integer.parseInt(Integer.java:527)
        sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
        sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        java.lang.reflect.Method.invoke(Method.java:606)
        com.opensymphony.xwork2.DefaultActionInvocation.invokeAction(DefaultActionInvocation.java:450)
        com.opensymphony.xwork2.DefaultActionInvocation.invokeActionOnly(DefaultActionInvocation.java:289)
        com.opensymphony.xwork2.DefaultActionInvocation.invoke(DefaultActionInvocation.java:252)
        org.apache.struts2.interceptor.debugging.DebuggingInterceptor.intercept(DebuggingInterceptor.java:256)
        com.opensymphony.xwork2.DefaultActionInvocation.invoke(DefaultActionInvocation.java:246)
        ...
    
    note: The full stack trace of the root cause is available in the Apache Tomcat/7.0.56 logs.
    

Below is an example of disclosure of a SQL query error, along with the site installation path, that can be used to identify an injection point:
    
    
    Warning: odbc_fetch_array() expects parameter /1 to be resource, boolean given
    in D:\app\index_new.php on line 188
    

The [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/01-Information_Gathering/) provides different techniques to obtain technical information from an application.

## Objective¶

The article shows how to configure a global error handler as part of your application's runtime configuration. In some cases, it may be more efficient to define this error handler as part of your code. The outcome being that when an unexpected error occurs then a generic response is returned by the application but the error details are logged server side for investigation, and not returned to the user.

The following schema shows the target approach:

As most recent application topologies are _API based_ , we assume in this article that the backend exposes only a REST API and does not contain any user interface content. The application should try and exhaustively cover all possible failure modes and use 5xx errors only to indicate responses to requests that it cannot fulfill, but not provide any content as part of the response that would reveal implementation details. For that, [RFC 7807 - Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc7807) defines a document format.  
For the error logging operation itself, the [logging cheat sheet](Logging_Cheat_Sheet.html) should be used. This article focuses on the error handling part.

## Proposition¶

For each technology stack, the following configuration options are proposed:

### Standard Java Web Application¶

For this kind of application, a global error handler can be configured at the **web.xml** deployment descriptor level.

We propose here a configuration that can be used from Servlet specification _version 2.5_ and above.

With this configuration, any unexpected error will cause a redirection to the page **error.jsp** in which the error will be traced and a generic response will be returned.

Configuration of the redirection into the **web.xml** file:
    
    
    <?xml version="1.0" encoding="UTF-8"?>
    <web-app xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ns="http://java.sun.com/xml/ns/javaee"
    xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd"
    version="3.0">
    ...
        <error-page>
            <exception-type>java.lang.Exception</exception-type>
            <location>/error.jsp</location>
        </error-page>
    ...
    </web-app>
    

Content of the **error.jsp** file:
    
    
    <%@ page language="java" isErrorPage="true" contentType="application/json; charset=UTF-8"
        pageEncoding="UTF-8"%>
    <%
    String errorMessage = exception.getMessage();
    //Log the exception via the content of the implicit variable named "exception"
    //...
    //We build a generic response with a JSON format because we are in a REST API app context
    //We also add an HTTP response header to indicate to the client app that the response is an error
    response.setHeader("X-ERROR", "true");
    //Note that we're using an internal server error response
    //In some cases it may be prudent to return 4xx error codes, when we have misbehaving clients
    response.setStatus(500);
    %>
    {"message":"An error occur, please retry"}
    

### Java SpringMVC/SpringBoot web application¶

With [SpringMVC](https://docs.spring.io/spring/docs/current/spring-framework-reference/web.html) or [SpringBoot](https://spring.io/projects/spring-boot), you can define a global error handler by implementing the following class in your project. Spring Framework 6 introduced [the problem details based on RFC 7807](https://github.com/spring-projects/spring-framework/issues/27052).

We indicate to the handler, via the annotation [@ExceptionHandler](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/bind/annotation/ExceptionHandler.html), to act when any exception extending the class _java.lang.Exception_ is thrown by the application. We also use the [ProblemDetail class](https://docs.spring.io/spring-framework/docs/6.0.0/javadoc-api/org/springframework/http/ProblemDetail.html) to create the response object.
    
    
    import org.springframework.http.HttpStatus;
    import org.springframework.http.ProblemDetail;
    import org.springframework.web.bind.annotation.ExceptionHandler;
    import org.springframework.web.bind.annotation.RestControllerAdvice;
    import org.springframework.web.context.request.WebRequest;
    import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
    
    /**
     * Global error handler in charge of returning a generic response in case of unexpected error situation.
     */
    @RestControllerAdvice
    public class RestResponseEntityExceptionHandler extends ResponseEntityExceptionHandler {
    
        @ExceptionHandler(value = {Exception.class})
        public ProblemDetail handleGlobalError(RuntimeException exception, WebRequest request) {
            //Log the exception via the content of the parameter named "exception"
            //...
            //Note that we're using an internal server error response
            //In some cases it may be prudent to return 4xx error codes, if we have misbehaving clients
            //By specification, the content-type can be "application/problem+json" or "application/problem+xml"
            return ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR, "An error occur, please retry");
        }
    }
    

References:

  * [Exception handling with Spring](https://www.baeldung.com/exception-handling-for-rest-with-spring)
  * [Exception handling with SpringBoot](https://www.toptal.com/java/spring-boot-rest-api-error-handling)


### ASP NET Core web application¶

With [ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/?view=aspnetcore-2.2), you can define a global error handler by indicating that the exception handler is a dedicated API Controller.

Content of the API Controller dedicated to the error handling:
    
    
    using Microsoft.AspNetCore.Authorization;
    using Microsoft.AspNetCore.Diagnostics;
    using Microsoft.AspNetCore.Mvc;
    using System;
    using System.Collections.Generic;
    using System.Net;
    
    namespace MyProject.Controllers
    {
        /// <summary>
        /// API Controller used to intercept and handle all unexpected exception
        /// </summary>
        [Route("api/[controller]")]
        [ApiController]
        [AllowAnonymous]
        public class ErrorController : ControllerBase
        {
            /// <summary>
            /// Action that will be invoked for any call to this Controller in order to handle the current error
            /// </summary>
            /// <returns>A generic error formatted as JSON because we are in a REST API app context</returns>
            [HttpGet]
            [HttpPost]
            [HttpHead]
            [HttpDelete]
            [HttpPut]
            [HttpOptions]
            [HttpPatch]
            public JsonResult Handle()
            {
                //Get the exception that has implied the call to this controller
                Exception exception = HttpContext.Features.Get<IExceptionHandlerFeature>()?.Error;
                //Log the exception via the content of the variable named "exception" if it is not NULL
                //...
                //We build a generic response with a JSON format because we are in a REST API app context
                //We also add an HTTP response header to indicate to the client app that the response
                //is an error
                var responseBody = new Dictionary<String, String>{ {
                    "message", "An error occur, please retry"
                } };
                JsonResult response = new JsonResult(responseBody);
                //Note that we're using an internal server error response
                //In some cases it may be prudent to return 4xx error codes, if we have misbehaving clients
                response.StatusCode = (int)HttpStatusCode.InternalServerError;
                Request.HttpContext.Response.Headers.Remove("X-ERROR");
                Request.HttpContext.Response.Headers.Add("X-ERROR", "true");
                return response;
            }
        }
    }
    

Definition in the application **Startup.cs** file of the mapping of the exception handler to the dedicated error handling API controller:
    
    
    using Microsoft.AspNetCore.Builder;
    using Microsoft.AspNetCore.Hosting;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.Extensions.Configuration;
    using Microsoft.Extensions.DependencyInjection;
    
    namespace MyProject
    {
        public class Startup
        {
    ...
            public void Configure(IApplicationBuilder app, IHostingEnvironment env)
            {
                //First we configure the error handler middleware!
                //We enable the global error handler in others environments than DEV
                //because debug page are useful during implementation
                if (env.IsDevelopment())
                {
                    app.UseDeveloperExceptionPage();
                }
                else
                {
                    //Our global handler is defined on "/api/error" URL so we indicate to the
                    //exception handler to call this API controller
                    //on any unexpected exception raised by the application
                    app.UseExceptionHandler("/api/error");
    
                    //To customize the response content type and text, use the overload of
                    //UseStatusCodePages that takes a content type and format string.
                    app.UseStatusCodePages("text/plain", "Status code page, status code: {0}");
                }
    
                //We configure others middlewares, remember that the declaration order is important...
                app.UseMvc();
                //...
            }
        }
    }
    

References:

  * [Exception handling with ASP.Net Core](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/error-handling?view=aspnetcore-2.1)


### ASP NET Web API web application¶

With [ASP.NET Web API](https://www.asp.net/web-api) (from the standard .NET framework and not from the .NET Core framework), you can define and register handlers in order to trace and handle any error that occurs in the application.

Definition of the handler for the tracing of the error details:
    
    
    using System;
    using System.Web.Http.ExceptionHandling;
    
    namespace MyProject.Security
    {
        /// <summary>
        /// Global logger used to trace any error that occurs at application wide level
        /// </summary>
        public class GlobalErrorLogger : ExceptionLogger
        {
            /// <summary>
            /// Method in charge of the management of the error from a tracing point of view
            /// </summary>
            /// <param name="context">Context containing the error details</param>
            public override void Log(ExceptionLoggerContext context)
            {
                //Get the exception
                Exception exception = context.Exception;
                //Log the exception via the content of the variable named "exception" if it is not NULL
                //...
            }
        }
    }
    

Definition of the handler for the management of the error in order to return a generic response:
    
    
    using Newtonsoft.Json;
    using System;
    using System.Collections.Generic;
    using System.Net;
    using System.Net.Http;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using System.Web.Http;
    using System.Web.Http.ExceptionHandling;
    
    namespace MyProject.Security
    {
        /// <summary>
        /// Global handler used to handle any error that occurs at application wide level
        /// </summary>
        public class GlobalErrorHandler : ExceptionHandler
        {
            /// <summary>
            /// Method in charge of handle the generic response send in case of error
            /// </summary>
            /// <param name="context">Error context</param>
            public override void Handle(ExceptionHandlerContext context)
            {
                context.Result = new GenericResult();
            }
    
            /// <summary>
            /// Class used to represent the generic response send
            /// </summary>
            private class GenericResult : IHttpActionResult
            {
                /// <summary>
                /// Method in charge of creating the generic response
                /// </summary>
                /// <param name="cancellationToken">Object to cancel the task</param>
                /// <returns>A task in charge of sending the generic response</returns>
                public Task<HttpResponseMessage> ExecuteAsync(CancellationToken cancellationToken)
                {
                    //We build a generic response with a JSON format because we are in a REST API app context
                    //We also add an HTTP response header to indicate to the client app that the response
                    //is an error
                    var responseBody = new Dictionary<String, String>{ {
                        "message", "An error occur, please retry"
                    } };
                    // Note that we're using an internal server error response
                    // In some cases it may be prudent to return 4xx error codes, if we have misbehaving clients 
                    HttpResponseMessage response = new HttpResponseMessage(HttpStatusCode.InternalServerError);
                    response.Headers.Add("X-ERROR", "true");
                    response.Content = new StringContent(JsonConvert.SerializeObject(responseBody),
                                                         Encoding.UTF8, "application/json");
                    return Task.FromResult(response);
                }
            }
        }
    }
    

Registration of the both handlers in the application **WebApiConfig.cs** file:
    
    
    using MyProject.Security;
    using System.Web.Http;
    using System.Web.Http.ExceptionHandling;
    
    namespace MyProject
    {
        public static class WebApiConfig
        {
            public static void Register(HttpConfiguration config)
            {
                //Register global error logging and handling handlers in first
                config.Services.Replace(typeof(IExceptionLogger), new GlobalErrorLogger());
                config.Services.Replace(typeof(IExceptionHandler), new GlobalErrorHandler());
                //Rest of the configuration
                //...
            }
        }
    }
    

Setting customErrors section to the **Web.config** file within the `csharp <system.web>` node as follows.
    
    
    <configuration>
        ...
        <system.web>
            <customErrors mode="RemoteOnly"
                          defaultRedirect="~/ErrorPages/Oops.aspx" />
            ...
        </system.web>
    </configuration>
    

References:

  * [Exception handling with ASP.Net Web API](https://exceptionnotfound.net/the-asp-net-web-api-exception-handling-pipeline-a-guided-tour/)

  * [ASP.NET Error Handling](https://docs.microsoft.com/en-us/aspnet/web-forms/overview/getting-started/getting-started-with-aspnet-45-web-forms/aspnet-error-handling)


## Sources of the prototype¶

The source code of all the sandbox projects created to find the right setup to use is stored in this [GitHub repository](https://github.com/righettod/poc-error-handling).

## Appendix HTTP Errors¶

A reference for HTTP errors can be found here [RFC 2616](https://www.ietf.org/rfc/rfc2616.txt). Using error messages that do not provide implementation details is important to avoid information leakage. In general, consider using 4xx error codes for requests that are due to an error on the part of the HTTP client (e.g. unauthorized access, request body too large) and use 5xx to indicate errors that are triggered on server side, due to an unforeseen bug. Ensure that applications are monitored for 5xx errors which are a good indication of the application failing for some sets of inputs.

©Copyright  \- Cheat Sheets Series Team - This work is licensed under [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/). 

Made with [ Material for MkDocs ](https://squidfunk.github.io/mkdocs-material/)
