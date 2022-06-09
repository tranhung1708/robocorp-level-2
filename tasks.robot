*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
...                 Author: www.github.com/joergschultzelutter

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             Collections
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets
Library             OperatingSystem


*** Variables ***
${img_folder}       ${CURDIR}${/}image_files
${pdf_folder}       ${CURDIR}${/}pdf_files
${output_folder}    ${CURDIR}${/}output

${orders_file}      ${CURDIR}${/}orders.csv
${zip_file}         ${output_folder}${/}pdf_archive.zip
${csv_url}          https://robotsparebinindustries.com/orders.csv


*** Test Cases ***
Order robots from RobotSpareBin Industries Inc
    Directory Cleanup
    Get The Program Author Name From Our Vault
    ${username}=    Get The User Name
    Open the robot order website

    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit The Order
        ${orderid}    ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=    Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file    IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Create a ZIP file of the receipts

    Log Out And Close The Browser
    Display the success dialog    USER_NAME=${username}


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    maximized=True    headless=True

Directory Cleanup
    Create Directory    ${output_folder}
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}

Get orders
    Download    url=${csv_url}    target_file=${orders_file}    overwrite=True
    ${table}=    Read table from CSV    path=${orders_file}
    RETURN    ${table}

Close the annoying modal
    # Define local variables for the UI elements
    Wait And Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]

Fill the form
    [Arguments]    ${myrow}
    Wait Until Element Is Visible    //*[@id="head"]
    Select From List By Value    //*[@id="head"]    ${myrow}[Head]

    Wait Until Element Is Enabled    body
    Select Radio Button    body    ${myrow}[Body]

    Wait Until Element Is Enabled    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Input Text
    ...    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    ...    ${myrow}[Legs]
    Wait Until Element Is Enabled    //*[@id="address"]
    Input Text    //*[@id="address"]    ${myrow}[Address]

Preview the robot
    # Define local variables for the UI elements
    Click Button    //*[@id="preview"]
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]

Submit the order
    Click button    //*[@id="order"]
    Page Should Contain Element    //*[@id="receipt"]

Take a screenshot of the robot
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]
    Wait Until Element Is Visible    //img[@alt='Head']
    Wait Until Element Is Visible    //img[@alt='Body']
    Wait Until Element Is Visible    //img[@alt='Legs']
    Wait Until Element Is Visible    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]

    #get the order ID
    ${orderid}=    Get Text    //*[@id="receipt"]/p[1]

    # Create the File Name
    Set Local Variable    ${fully_qualified_img_filename}    ${img_folder}${/}${orderid}.png

    Capture Element Screenshot    //*[@id="robot-preview-image"]    ${fully_qualified_img_filename}
    RETURN    ${orderid}    ${fully_qualified_img_filename}

Go to order another robot
    # Define local variables for the UI elements
    Set Local Variable    ${btn_order_another_robot}    //*[@id="order-another"]
    Click Button    ${btn_order_another_robot}

Log Out And Close The Browser
    Close Browser

Create a Zip File of the Receipts
    Archive Folder With ZIP    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf

Store the receipt as a PDF file
    [Arguments]    ${ORDER_NUMBER}
    Wait Until Element Is Visible    //*[@id="receipt"]
    ${order_receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Set Local Variable    ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf
    Html To Pdf    content=${order_receipt_html}    output_path=${fully_qualified_pdf_filename}
    RETURN    ${fully_qualified_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}
    Open PDF    ${PDF_FILE}
    @{myfiles}=    Create List    ${IMG_FILE}
    Add Files To Pdf    ${myfiles}    ${PDF_FILE}    ${True}
    Close All Pdfs

Get The Program Author Name From Our Vault
    ${secret}=    Get Secret    mysecrets

Get The User Name
    Add heading    I am your RoboCorp Order Genie
    Add text input    myname    label=What is thy name, oh sire?    placeholder=Give me some input here
    ${result}=    Run dialog
    RETURN    ${result.myname}

Display the success dialog
    [Arguments]    ${USER_NAME}
    Add icon    Success
    Add heading    Your orders have been processed
    Add text    Dear ${USER_NAME} - all orders have been processed. Have a nice day!
    Run dialog    title=Success
