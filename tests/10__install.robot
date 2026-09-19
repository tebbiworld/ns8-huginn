*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Variables ***
${CONFIG}    {"host":"huginn.ci.test","lets_encrypt":false,"http2https":true,"smtp_host":"mail.ci.test","smtp_port":587,"smtp_username":"ci","smtp_password":"Smtp#Pass 1","openai_api_key":"sk-ci-123","invitation_code":"invite-ci"}

*** Test Cases ***
Install the module
    # The update scenario starts from the last published release and reaches
    # the image under test through update-module below.
    IF    '${SCENARIO}' == 'update'
        ${output}  ${rc} =    Execute Command    add-module ${UPDATE_FROM} 1    return_rc=True
    ELSE
        ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1    return_rc=True
    END
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${module_id}    ${output.module_id}

Configure the module
    Run task    module/${module_id}/configure-module    ${CONFIG}    decode_json=${FALSE}

Huginn answers behind Traefik
    Wait Until Keyword Succeeds    60 times    10 seconds    Login page is served

Remember the secrets before the update
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    Set Global Variable    ${ADMIN_PW_BEFORE}    ${cfg['admin_password']}
    Should Not Be Empty    ${ADMIN_PW_BEFORE}

Update to the image under test
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}
    Run on node    api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'
    Wait Until Keyword Succeeds    60 times    10 seconds    Login page is served
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    # the migration must move the secrets, not regenerate them
    Should Be Equal    ${cfg['admin_password']}    ${ADMIN_PW_BEFORE}

Configuration reads back
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${cfg['host']}    huginn.ci.test
    Should Be Equal    ${cfg['smtp_host']}    mail.ci.test
    Should Be Equal    ${cfg['smtp_password']}    Smtp#Pass 1
    Should Be Equal    ${cfg['openai_api_key']}    sk-ci-123
    Should Be Equal    ${cfg['invitation_code']}    invite-ci

Secrets are stored in passwords.env only
    Secrets are kept out of the module environment    ${module_id}

*** Keywords ***
Login page is served
    ${out} =    Run on node    curl -fsSk -H 'Host: huginn.ci.test' https://127.0.0.1/users/sign_in
    Should Contain    ${out}    Huginn
