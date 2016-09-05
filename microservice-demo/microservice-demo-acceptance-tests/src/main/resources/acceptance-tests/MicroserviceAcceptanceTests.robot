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

