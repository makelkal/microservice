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
${CATALOG_LISTVIEW_XPATH}  //div[contains(text(),'List / add / remove items')]/..//a[contains(text(),'Catalog')]

*** Test Cases ***
Order a product from a catalog
  Given product "Torspo" is added to the catalog
    And customer "Teemu Selanne" is added
  When I order product "Torspo"
    And I select customer "Teemu Selanne"
    And I submit the order
  Then I can verify my order

Delete an existing order
  Given Product "Koho" is ordered by "Jari Kurri"
  When I have an order "Koho" for "Jari Kurri"
    And I press delete button for "Jari Kurri" order
  Then I can verify my order for "Jari Kurri" is deleted

Remove item from catalog
  Given product "Montreal" is added to the catalog
  When I press delete of item "Montreal" in catalog
  Then item "Montreal" is not visible in the catalog

Add item to catalog
  Given item "Bauer" should not be in the catalog
  When I add item "Bauer"
    And I set item price "89" to
    And I submit the item
  Then I can see my item "Bauer" in the catalog

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
  Set Test Variable  ${CATALOG_PRICE}  120.0
  ${data}=  Replace Variables  ${TEMPLATE}
  ${result}=  Post JSON data  catalogsrv  /catalog  ${data}
  Set Test Variable  ${CATALOG_ID}  ${result['id']}
  Log  ${CATALOG_ID}

Customer "${name}" is added
    Get JSON Template  customer.json
    Run Keyword If  "${name}"=="Teemu Selanne"  Add User Teemu Selanne
    Run Keyword If  "${name}"=="Jari Kurri"  Add User Jari Kurri
    ${data}=  Replace Variables  ${TEMPLATE}
    Post JSON data  custsrv  /customer  ${data}

Add User Teemu Selanne
    Set Test Variable  ${NAME}  Selanne
    Set Test Variable  ${FIRSTNAME}  Teemu
    Set Test Variable  ${EMAIL}  teemu.selanne@gmail.com
    Set Test Variable  ${STREET}  Madre Selva LN
    Set Test Variable  ${CITY}  San Diego

Add User Jari Kurri
  Set Test Variable  ${NAME}  Kurri
  Set Test Variable  ${FIRSTNAME}  Jari
  Set Test Variable  ${EMAIL}  jari.kurri@nhl.com
  Set Test Variable  ${STREET}  East Street 1
  Set Test Variable  ${CITY}  New York

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

Product "${catalog_item}" is ordered by "${customer}"
  Given product "${catalog_item}" is added to the catalog
    and customer "${customer}" is added
  When I order product "${catalog_item}"
   And I select customer "${customer}"
   And I submit the order
  Then I can verify my order

I have an order "${catalog_item}" for "${customer}"
  Go To  ${ORDER_URL}
  Wait Until Page Contains  Add Order
  Click Link  xpath=//table/tbody/tr[last()]/td/a
  Wait Until Page Contains  ${customer}
  Wait Until Page Contains  ${catalog_item}

I press delete button for "${customer}" order
  Go To  ${ORDER_URL}
  Wait Until Page Contains  Add Order
  Page Should contain  ${customer}
  Click Element  xpath=//table/tbody/tr[last()]//td[contains(text(),'${customer}')]/..//input[contains(@class,'btn-link')]

I can verify my order for "${customer}" is deleted
  Go To  ${ORDER_URL}
  Wait Until Page Contains  Add Order
  Page Should not contain  ${customer}

I Remove The Catalog Through Service API #not working since no delete implementation in microservice demo
  ${resp}=  Delete Request  catalogsrv  ${CATALOG_SERVICE_URL}/catalog/${CATALOG_ID}
  Should Be Equal As Strings  ${resp.status_code}  204

I press delete of item "${catalog_item}" in catalog
  Page Should Contain Link  Home
  Click Link  Home
  Wait Until Element Is Visible  xpath=${CATALOG_LISTVIEW_XPATH}
  Click Element  xpath=${CATALOG_LISTVIEW_XPATH}
  Click Element  xpath=//td[contains(text(),'${catalog_item}')]/..//input[contains(@class,'btn-link')]
  Wait Until Page Contains  Success

item "${catalog_item}" is not visible in the catalog
  Wait Until Element Is Not Visible  xpath=//td[contains(text(),'${catalog_item}')]

remove item "${catalog_item}" from catalog
  When I press delete of item "${catalog_item}" in catalog
  Then item "${catalog_item}" is not visible in the catalog

item "${catalog_item}" should not be in the catalog
  Wait Until Page Contains  Order : Add
  Click Link  Home
  Wait Until Element Is Visible  xpath=${CATALOG_LISTVIEW_XPATH}
  Click Element  xpath=${CATALOG_LISTVIEW_XPATH}
  Wait Until Page Contains  Item : View all
  ${passed}=  Run Keyword And Return Status  Page Should Not Contain  ${catalog_item}
  Run Keyword Unless  ${passed}  remove item "${catalog_item}" from catalog

I add item "${catalog_item}"
  Page Should Contain Link  Home
  Click Link  Home
  Wait Until Element Is Visible  xpath=${CATALOG_LISTVIEW_XPATH}
  Click Element  xpath=${CATALOG_LISTVIEW_XPATH}
  Wait Until Page Contains  Item : View all
  Click Link  Add Item
  Input Text  id=name  ${catalog_item}

I set item price "${price}" to
  Input Text  id=price  ${price}

I submit the item
  Click Button  Submit
  Wait Until Page Contains  Success

I can see my item "${catalog_item}" in the catalog
  Page Should Contain Link  Home
  Click Link  Home
  Wait Until Element Is Visible  xpath=${CATALOG_LISTVIEW_XPATH}
  Click Element  xpath=${CATALOG_LISTVIEW_XPATH}
  Wait Until Page Contains  Item : View all
  Page Should Contain  ${catalog_item}



