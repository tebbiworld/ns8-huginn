*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Test Cases ***
Seed a probe row
    Run on node    runagent -m ${module_id} podman exec huginn-db sh -c 'mariadb -u root --password="$MARIADB_ROOT_PASSWORD" huginn -e "CREATE TABLE ci_probe (note varchar(32)); INSERT INTO ci_probe VALUES (\\"pre-backup\\");"'

Back up the module
    ${repo}    ${path} =    Back up the module to the cluster repository    ${module_id}
    Set Global Variable    ${BACKUP_REPO}    ${repo}
    Set Global Variable    ${BACKUP_PATH}    ${path}

Restore into a new instance
    ${rid} =    Restore the module from the cluster repository    ${BACKUP_REPO}    ${BACKUP_PATH}
    Set Global Variable    ${restored_id}    ${rid}
    Should Not Be Equal    ${restored_id}    ${module_id}

The restored instance has data, settings and secrets
    ${out} =    Wait Until Keyword Succeeds    40 times    10 seconds
    ...    Run on node    runagent -m ${restored_id} podman exec huginn-db sh -c 'mariadb -u root --password="$MARIADB_ROOT_PASSWORD" -N huginn -e "SELECT note FROM ci_probe"'
    Should Contain    ${out}    pre-backup
    ${orig} =    Run task    module/${module_id}/get-configuration    {}
    ${cfg} =    Run task    module/${restored_id}/get-configuration    {}
    Should Be Equal    ${cfg['smtp_host']}    ${orig['smtp_host']}
    Should Be Equal As Integers    ${cfg['delayed_job_workers']}    ${orig['delayed_job_workers']}
    FOR    ${key}    IN    SMTP_MANUAL_PASSWORD    SEED_PASSWORD    INVITATION_CODE
        ${a} =    Secret hash    ${module_id}    ${key}
        ${b} =    Secret hash    ${restored_id}    ${key}
        Should Be Equal    ${a}    ${b}
    END
    # the readable agent export travels with the backup
    ${n} =    Run on node    runagent -m ${restored_id} bash -c 'grep -c "\"schema_version\"" "$AGENT_STATE_DIR/agents-export/agents.json" || true'
    Should Be True    ${n.strip()} >= 1
    Secrets are kept out of the module environment    ${restored_id}
