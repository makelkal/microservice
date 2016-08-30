*** Settings ***
Library     Selenium2Library    10.0  1.0      #timeout, implicit_wait
Library     RequestsLibrary
Library     OperatingSystem
Library     Collections
Library     String

Test Setup  Open Browser And Navigate to Add Order Page
Suite Setup  Initialize Session
Suite Teardown  Delete All Sessions
#Test Teardown  Close Browser

*** Variables ***
# Execution specific
${BROWSER}                        chrome
${REMOTE_URL}                     ${EMPTY}
${ORDER_URL}
${CUSTOMER_SERVICE_URL}
${CATALOG_SERVICE_URL}

*** Test Cases ***
Order a product from a catalog
  Given product "Torspo" is added to the catalog
    and customer "Teemu Selanne" is added
  When I order product "Torspo"
   and I select customer "Teemu Selanne"
   And I submit the order
  Then I can verify my order

*** Keywords ***
Get JSON Template  [Arguments]  ${form}
  [Documentation]  Reads the json template. Template name is given as an argument.
  ...              Template should reside at the same directory as the test case.
  ${json}=  Get File  ${CURDIR}${/}${form}  encoding=utf-8
  Set Test Variable  ${TEMPLATE}  ${json}

Initialize Session
  [Documentation]  Creates context for REST API calls.
  Set Log Level         TRACE
  ${headers}=  Create Dictionary  Content-type=application/json  Accept=*/*  Accept-language=en-US,en;fi  Cache-control=no-cache
  Set Suite Variable  ${HEADERS}  ${headers}
  Create Session  custsrv  ${CUSTOMER_SERVICE_URL}  headers=${headers}
  Create Session  catalogsrv  ${CATALOG_SERVICE_URL}  headers=${headers}

Open Browser And Navigate to Add Order Page
  [Documentation]
  ${remote}=  Get Variable Value  ${REMOTE_URL}  None
  Run Keyword If  "${remote}"=="None"   Open Browser   ${ORDER_URL}  ${BROWSER}  None
  Run Keyword Unless  "${remote}"=="None"  Open Browser  ${ORDER_URL}  ${BROWSER}  None  ${REMOTE_URL}
  :FOR  ${INDEX}  IN RANGE  1  10
  \  ${passed}=  Run Keyword And Return Status  Wait Until Page Contains  Order : View all  5s
  \  Run Keyword Unless  ${passed}  Reload Page
  \  RUn Keyword If  ${passed}  Exit For Loop
  Click Link  Add Order
  Wait Until Page Contains   Order : Add
  Sleep  2s
  Reload Page

Product "${name}" is added to the catalog
  Get JSON Template  catalog.json
  Set Test Variable  ${CATALOG_ITEM}  ${name}
  Set Test Variable  ${CATALOG_PRICE}  120
  ${data}=  Replace Variables  ${TEMPLATE}
  Post JSON data  catalogsrv  /catalog  ${data}

Customer "${name}" is added
  Get JSON Template  customer.json
  Run Keyword If  "${name}"=="Teemu Selanne"  Add User Teemu Selanne
  ${data}=  Replace Variables  ${TEMPLATE}
  Post JSON data  custsrv  /customer  ${data}

Add User Teemu Selanne
  Set Test Variable  ${NAME}  Selanne
  Set Test Variable  ${FIRSTNAME}  Teemu
  Set Test Variable  ${EMAIL}  teemu.selanne@gmail.com
  Set Test Variable  ${STREET}  Madre Selva LN
  Set Test Variable  ${CITY}  San Diego

Post JSON data  [Arguments]  ${session}  ${uri}  ${data}
  [Documentation]  Posts Customer data through REST API.
  Log  ${data}
  ${resp}=  Post Request  ${session}  ${uri}  data=${data}
  Log  ${resp.text}
  Should Be Equal As Strings  ${resp.status_code}  201
  ${actual}=  To Json  ${resp.content}
  Log  ${actual}
  [Return]  ${actual}

I select customer "${name}"
  Select From List  customerId  ${name}

I order product "${product}"
  Click Button  addLine
  Input Text  orderLine0.count  1
  Select From List  orderLine0.itemId  ${product}

I submit the order
  Click Button  submit
  Wait Until Page Contains  Success

I can verify my order
  Go To  ${ORDER_URL}
  Click Link  xpath=//table/tbody/tr[last()]/td/a
  ${name}=  Get Text  xpath=//div[text()='Customer']/following-sibling::div
  Should Be Equal  ${NAME}  ${name}
  ${price}=  Get Text  xpath=//div[text()='Total price']/following-sibling::div
  Should Be Equal  ${CATALOG_PRICE}  ${price}
