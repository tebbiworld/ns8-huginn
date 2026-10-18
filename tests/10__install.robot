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
    Should Not Be Empty    ${cfg['admin_password']}
    ${h} =    Secret hash    ${module_id}    SEED_PASSWORD
    Set Global Variable    ${ADMIN_PW_BEFORE}    ${h}

Update to the image under test
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}
    Run on node    api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'
    Wait Until Keyword Succeeds    60 times    10 seconds    Login page is served
    # the migration must move the secrets, not regenerate them
    ${h} =    Secret hash    ${module_id}    SEED_PASSWORD
    Should Be Equal    ${h}    ${ADMIN_PW_BEFORE}

Configuration reads back
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${cfg['host']}    huginn.ci.test
    Should Be Equal    ${cfg['smtp_host']}    mail.ci.test
    Should Be True    ${cfg['smtp_password_set']}
    Should Be True    ${cfg['openai_api_key_set']}
    Should Be True    ${cfg['invitation_code_set']}
    Should Be True    ${cfg['admin_password_set']}

The settings page receives no secrets
    ${out} =    Run on node    api-cli run module/${module_id}/get-configuration
    FOR    ${secret}    IN    Smtp#Pass 1    sk-ci-123    invite-ci
        Should Not Contain    ${out}    ${secret}
    END
    ${pw} =    Run task    module/${module_id}/get-admin-password    {}
    Should Not Be Empty    ${pw['admin_password']}
    Should Not Contain    ${out}    ${pw['admin_password']}

Empty secret fields keep the stored values
    ${before} =    Secret hash    ${module_id}    OPENAI_API_KEY
    Run task    module/${module_id}/configure-module    {"host":"huginn.ci.test","lets_encrypt":false,"http2https":true,"smtp_host":"mail.ci.test","smtp_password":"","openai_api_key":"","invitation_code":""}    decode_json=${FALSE}
    ${after} =    Secret hash    ${module_id}    OPENAI_API_KEY
    Should Be Equal    ${before}    ${after}
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    Should Be True    ${cfg['smtp_password_set']} and ${cfg['invitation_code_set']}
    Wait Until Keyword Succeeds    60 times    10 seconds    Login page is served

The worker settings reach Huginn
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    # also the default for an instance updated from an earlier release
    Should Be Equal As Integers    ${cfg['delayed_job_max_runtime']}    15
    Should Be Equal    ${cfg['healthcheck_mode']}    restart
    Run task    module/${module_id}/configure-module    {"host":"huginn.ci.test","lets_encrypt":false,"http2https":true,"smtp_host":"mail.ci.test","delayed_job_max_runtime":20,"delayed_job_workers":2,"database_pool":25}    decode_json=${FALSE}
    Wait Until Keyword Succeeds    60 times    10 seconds    Login page is served
    ${env} =    Run on node    runagent -m ${module_id} podman exec huginn-app sh -c 'echo $DELAYED_JOB_MAX_RUNTIME $DATABASE_POOL'
    Should Be Equal As Strings    ${env.strip()}    20 25
    Wait Until Keyword Succeeds    30 times    10 seconds    Second worker runs

Out-of-range worker settings are refused
    ${out} =    Run task    module/${module_id}/configure-module    {"host":"huginn.ci.test","delayed_job_workers":9}    decode_json=${FALSE}    rc_expected=10
    Should Contain    ${out}    delayed_job_workers

The health check runs and reports
    ${enabled} =    Run on node    runagent -m ${module_id} systemctl --user is-enabled huginn-healthcheck.timer
    Should Be Equal As Strings    ${enabled.strip()}    enabled
    Run on node    runagent -m ${module_id} systemctl --user start huginn-healthcheck.service
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    Should Not Be Empty    ${cfg['health']['last_check']}
    Should Be True    '${cfg['health']['status']}' in ('ok', 'catching_up')

Secrets are stored in passwords.env only
    Secrets are kept out of the module environment    ${module_id}

*** Keywords ***
Login page is served
    ${out} =    Run on node    curl -fsSk -H 'Host: huginn.ci.test' https://127.0.0.1/users/sign_in
    Should Contain    ${out}    Huginn

Second worker runs
    ${n} =    Run on node    runagent -m ${module_id} podman exec huginn-app sh -c 'ps -eo args | grep -c "[d]elayed_job.*-i 2" || true'
    Should Be True    ${n.strip()} >= 1
