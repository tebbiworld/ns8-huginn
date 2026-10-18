<!--
  Copyright (C) 2026 tebbi
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="configureModule">
            <cv-text-input
              :label="$t('settings.host')"
              v-model.trim="host"
              :placeholder="$t('settings.host_placeholder')"
              :helper-text="$t('settings.host_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="$t(error.host)"
              ref="host"
            ></cv-text-input>
            <cv-toggle
              value="lets_encrypt"
              :label="$t('settings.lets_encrypt')"
              v-model="lets_encrypt"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="toggle"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <cv-toggle
              value="http2https"
              :label="$t('settings.http2https')"
              v-model="http2https"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="toggle"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <NsInlineNotification
              kind="info"
              :title="$t('settings.proxy_hint_title')"
              :description="$t('settings.proxy_hint_desc')"
              :showCloseButton="false"
              class="proxy-hint"
            />
            <cv-text-input
              :label="$t('settings.timezone')"
              v-model.trim="timezone"
              :placeholder="$t('settings.timezone_placeholder')"
              :helper-text="$t('settings.timezone_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="$t(error.timezone)"
              ref="timezone"
            ></cv-text-input>
            <h4 class="section-title">{{ $t("settings.email_title") }}</h4>
            <div class="section-help">{{ $t("settings.email_help") }}</div>
            <cv-text-input
              :label="$t('settings.smtp_host')"
              v-model.trim="smtp_host"
              :placeholder="$t('settings.smtp_host_placeholder')"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="smtp_host"
            ></cv-text-input>
            <cv-text-input
              :label="$t('settings.smtp_port')"
              type="number"
              v-model.number="smtp_port"
              :disabled="
                loading.getConfiguration ||
                loading.configureModule ||
                !smtp_host
              "
            ></cv-text-input>
            <cv-text-input
              :label="$t('settings.smtp_username')"
              v-model.trim="smtp_username"
              :disabled="
                loading.getConfiguration ||
                loading.configureModule ||
                !smtp_host
              "
            ></cv-text-input>
            <cv-text-input
              :label="$t('settings.smtp_password')"
              type="password"
              v-model="smtp_password"
              :placeholder="smtp_password_set ? $t('settings.secret_keep') : ''"
              :helper-text="
                smtp_password_set ? $t('settings.secret_is_set') : ''
              "
              :disabled="
                loading.getConfiguration ||
                loading.configureModule ||
                !smtp_host
              "
            ></cv-text-input>
            <cv-text-input
              :label="$t('settings.smtp_from')"
              v-model.trim="smtp_from"
              :placeholder="$t('settings.smtp_from_placeholder')"
              :disabled="
                loading.getConfiguration ||
                loading.configureModule ||
                !smtp_host
              "
            ></cv-text-input>
            <cv-toggle
              value="smtp_starttls"
              :label="$t('settings.smtp_starttls')"
              v-model="smtp_starttls"
              :disabled="
                loading.getConfiguration ||
                loading.configureModule ||
                !smtp_host
              "
              class="toggle"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <cv-toggle
              value="smtp_ssl_verify"
              :label="$t('settings.smtp_ssl_verify')"
              v-model="smtp_ssl_verify"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="toggle"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <div class="section-help">
              {{ $t("settings.smtp_ssl_verify_help") }}
            </div>
            <h4 class="section-title">{{ $t("settings.features_title") }}</h4>
            <div class="section-help">{{ $t("settings.features_help") }}</div>
            <cv-toggle
              value="enable_insecure_agents"
              :label="$t('settings.enable_insecure_agents')"
              v-model="enable_insecure_agents"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="toggle"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <NsInlineNotification
              kind="warning"
              :title="$t('settings.enable_insecure_agents')"
              :description="$t('settings.enable_insecure_agents_help')"
              :showCloseButton="false"
              class="feature-warning"
            />
            <cv-toggle
              value="enable_second_precision_schedule"
              :label="$t('settings.enable_second_precision_schedule')"
              v-model="enable_second_precision_schedule"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="toggle"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <div class="section-help">
              {{ $t("settings.enable_second_precision_schedule_help") }}
            </div>
            <h4 class="section-title">
              {{ $t("settings.registration_title") }}
            </h4>
            <div class="section-help">
              {{ $t("settings.registration_help") }}
            </div>
            <cv-text-input
              :label="$t('settings.invitation_code')"
              v-model.trim="invitation_code"
              :placeholder="
                invitation_code_set ? $t('settings.secret_keep') : ''
              "
              :helper-text="$t('settings.invitation_code_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="invitation_code"
            ></cv-text-input>
            <cv-toggle
              value="require_confirmed_email"
              :label="$t('settings.require_confirmed_email')"
              v-model="require_confirmed_email"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="toggle"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <div class="section-help">
              {{ $t("settings.require_confirmed_email_help") }}
            </div>
            <h4 class="section-title">{{ $t("settings.ai_title") }}</h4>
            <div class="section-help">{{ $t("settings.ai_help") }}</div>
            <cv-text-input
              :label="$t('settings.openai_api_key')"
              type="password"
              v-model="openai_api_key"
              :placeholder="
                openai_api_key_set
                  ? $t('settings.secret_keep')
                  : $t('settings.openai_api_key_placeholder')
              "
              :helper-text="
                openai_api_key_set ? $t('settings.secret_is_set') : ''
              "
              :disabled="
                loading.getConfiguration ||
                loading.configureModule ||
                openai_api_key_remove
              "
            ></cv-text-input>
            <cv-checkbox
              v-if="openai_api_key_set"
              value="openai_api_key_remove"
              :label="$t('settings.openai_api_key_remove')"
              v-model="openai_api_key_remove"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="toggle"
            />
            <cv-text-input
              :label="$t('settings.openai_base_url')"
              v-model.trim="openai_base_url"
              :placeholder="$t('settings.openai_base_url_placeholder')"
              :helper-text="$t('settings.openai_base_url_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
            ></cv-text-input>
            <NsInlineNotification
              v-if="admin_username"
              kind="info"
              :title="$t('settings.admin_credentials')"
              :description="
                admin_password
                  ? $t('settings.admin_credentials_desc', {
                      user: admin_username,
                      password: admin_password,
                    })
                  : $t('settings.admin_credentials_hidden', {
                      user: admin_username,
                    })
              "
              :actionLabel="
                admin_password || !admin_password_set
                  ? ''
                  : $t('settings.show_admin_password')
              "
              @action="getAdminPassword"
              :showCloseButton="false"
              class="admin-credentials"
            />
            <h4 class="section-title">{{ $t("settings.worker_title") }}</h4>
            <div class="section-help">{{ $t("settings.worker_help") }}</div>
            <NsInlineNotification
              v-if="health.status || health.live"
              :kind="healthKind"
              :title="$t('settings.health_' + healthStatus)"
              :description="healthText"
              :showCloseButton="false"
              class="admin-credentials"
            />
            <div
              v-if="health.stale_agents && health.stale_agents.length"
              class="section-help stale-agents"
            >
              {{ $t("settings.stale_agents") }}
              <ul>
                <li v-for="a in health.stale_agents" :key="a.id">
                  {{ a.name }} ({{ a.schedule }}):
                  {{ a.last_check_at || $t("settings.never") }}
                </li>
              </ul>
            </div>
            <cv-number-input
              :label="$t('settings.delayed_job_max_runtime')"
              v-model="delayed_job_max_runtime"
              :min="2"
              :max="60"
              :helper-text="$t('settings.delayed_job_max_runtime_helper')"
              :invalid-message="error.delayed_job_max_runtime"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="delayed_job_max_runtime"
              class="toggle"
            />
            <cv-number-input
              :label="$t('settings.delayed_job_workers')"
              v-model="delayed_job_workers"
              :min="1"
              :max="5"
              :helper-text="$t('settings.delayed_job_workers_helper')"
              :invalid-message="error.delayed_job_workers"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="delayed_job_workers"
              class="toggle"
            />
            <cv-number-input
              :label="$t('settings.delayed_job_sleep_delay')"
              v-model="delayed_job_sleep_delay"
              :min="1"
              :max="60"
              :invalid-message="error.delayed_job_sleep_delay"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="delayed_job_sleep_delay"
              class="toggle"
            />
            <cv-number-input
              :label="$t('settings.database_pool')"
              v-model="database_pool"
              :min="5"
              :max="100"
              :invalid-message="error.database_pool"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="database_pool"
              class="toggle"
            />
            <div class="bx--label toggle">{{ $t("settings.healthcheck_mode") }}</div>
            <cv-radio-group
              :legend="$t('settings.healthcheck_mode')"
              vertical
              class="toggle"
            >
              <cv-radio-button
                v-for="m in ['restart', 'quiet', 'off']"
                :key="m"
                name="healthcheck_mode"
                :value="m"
                v-model="healthcheck_mode"
                :label="$t('settings.healthcheck_mode_' + m)"
                :disabled="loading.getConfiguration || loading.configureModule"
              />
            </cv-radio-group>
            <template v-if="healthcheck_mode !== 'off'">
              <cv-number-input
                :label="$t('settings.healthcheck_minutes')"
                v-model="healthcheck_minutes"
                :min="10"
                :max="1440"
                :invalid-message="error.healthcheck_minutes"
                :disabled="loading.getConfiguration || loading.configureModule"
                ref="healthcheck_minutes"
                class="toggle"
              />
              <cv-number-input
                :label="$t('settings.healthcheck_backlog')"
                v-model="healthcheck_backlog"
                :min="1"
                :max="100000"
                :invalid-message="error.healthcheck_backlog"
                :disabled="loading.getConfiguration || loading.configureModule"
                ref="healthcheck_backlog"
                class="toggle"
              />
              <cv-text-input
                :label="$t('settings.healthcheck_mail_to')"
                v-model.trim="healthcheck_mail_to"
                :helper-text="$t('settings.healthcheck_mail_to_helper')"
                :invalid-message="error.healthcheck_mail_to"
                :disabled="loading.getConfiguration || loading.configureModule"
                ref="healthcheck_mail_to"
                class="toggle"
              />
            </template>
            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="loading.getConfiguration || loading.configureModule"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";

export default {
  name: "Settings",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
  ],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      urlCheckInterval: null,
      host: "",
      lets_encrypt: false,
      http2https: false,
      timezone: "UTC",
      smtp_host: "",
      smtp_port: 587,
      smtp_username: "",
      smtp_password: "",
      smtp_starttls: true,
      smtp_ssl_verify: true,
      smtp_from: "",
      enable_insecure_agents: false,
      enable_second_precision_schedule: false,
      invitation_code: "",
      require_confirmed_email: false,
      openai_api_key: "",
      openai_base_url: "",
      admin_username: "",
      admin_password: "",
      admin_password_set: false,
      smtp_password_set: false,
      invitation_code_set: false,
      openai_api_key_set: false,
      openai_api_key_remove: false,
      delayed_job_max_runtime: 15,
      delayed_job_sleep_delay: 10,
      database_pool: 20,
      delayed_job_workers: 1,
      healthcheck_mode: "restart",
      healthcheck_minutes: 30,
      healthcheck_backlog: 20,
      healthcheck_mail_to: "",
      health: {},
      loading: {
        getConfiguration: false,
        configureModule: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        host: "",
        timezone: "",
        delayed_job_max_runtime: "",
        delayed_job_sleep_delay: "",
        database_pool: "",
        delayed_job_workers: "",
        healthcheck_minutes: "",
        healthcheck_backlog: "",
        healthcheck_mail_to: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    healthStatus() {
      const s = this.health.status || (this.health.live ? "ok" : "unknown");
      return [
        "ok",
        "catching_up",
        "hung",
        "restarted",
        "app_not_running",
        "db_unreachable",
      ].includes(s)
        ? s
        : "unknown";
    },
    healthKind() {
      return (
        {
          ok: "success",
          catching_up: "info",
          restarted: "warning",
          hung: "error",
        }[this.healthStatus] || "info"
      );
    },
    healthText() {
      const h = this.health;
      let t = this.$t("settings.health_numbers", {
        backlog: h.backlog || 0,
        minutes: this.healthcheck_minutes,
        queued: h.queued_jobs || 0,
        failed: h.failed_jobs || 0,
      });
      if (h.last_restart) {
        t +=
          " " +
          this.$t("settings.health_last_restart", {
            time: h.last_restart.time,
            mode: this.$t("settings.healthcheck_mode_" + h.last_restart.mode),
          });
      }
      if (h.last_check)
        t +=
          " " + this.$t("settings.health_last_check", { time: h.last_check });
      return t;
    },
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  created() {
    this.getConfiguration();
  },
  methods: {
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getConfigurationAborted
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getConfigurationCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      this.loading.getConfiguration = false;
      const config = taskResult.output;

      this.host = config.host || "";
      this.lets_encrypt = !!config.lets_encrypt;
      this.http2https = !!config.http2https;
      this.timezone = config.timezone || "UTC";
      this.smtp_host = config.smtp_host || "";
      this.smtp_port = config.smtp_port || 587;
      this.smtp_username = config.smtp_username || "";
      this.smtp_password = "";
      this.smtp_password_set = !!config.smtp_password_set;
      this.smtp_starttls =
        config.smtp_starttls === undefined ? true : !!config.smtp_starttls;
      this.smtp_ssl_verify =
        config.smtp_ssl_verify === undefined ? true : !!config.smtp_ssl_verify;
      this.smtp_from = config.smtp_from || "";
      this.enable_insecure_agents = !!config.enable_insecure_agents;
      this.enable_second_precision_schedule =
        !!config.enable_second_precision_schedule;
      this.invitation_code = "";
      this.invitation_code_set = !!config.invitation_code_set;
      this.require_confirmed_email = !!config.require_confirmed_email;
      this.openai_api_key = "";
      this.openai_api_key_set = !!config.openai_api_key_set;
      this.openai_api_key_remove = false;
      this.openai_base_url = config.openai_base_url || "";
      this.admin_username = config.admin_username || "";
      this.admin_password = "";
      this.admin_password_set = !!config.admin_password_set;
      for (const k of [
        "delayed_job_max_runtime",
        "delayed_job_sleep_delay",
        "database_pool",
        "delayed_job_workers",
        "healthcheck_minutes",
        "healthcheck_backlog",
      ]) {
        if (typeof config[k] === "number") this[k] = config[k];
      }
      this.healthcheck_mode = config.healthcheck_mode || "restart";
      this.healthcheck_mail_to = config.healthcheck_mail_to || "";
      this.health = config.health || {};

      this.focusElement("host");
    },
    validateConfigureModule() {
      this.clearErrors(this);
      let isValidationOk = true;

      const ranges = {
        delayed_job_max_runtime: [2, 60],
        delayed_job_sleep_delay: [1, 60],
        database_pool: [5, 100],
        delayed_job_workers: [1, 5],
        healthcheck_minutes: [10, 1440],
        healthcheck_backlog: [1, 100000],
      };
      for (const [k, [lo, hi]] of Object.entries(ranges)) {
        const v = Number(this[k]);
        if (!Number.isInteger(v) || v < lo || v > hi) {
          this.error[k] = this.$t("settings.out_of_range", {
            min: lo,
            max: hi,
          });
          if (isValidationOk) {
            this.focusElement(k);
            isValidationOk = false;
          }
        }
      }
      if (
        this.healthcheck_mail_to &&
        !/^[^@\s]+@[^@\s]+$/.test(this.healthcheck_mail_to)
      ) {
        this.error.healthcheck_mail_to = this.$t("settings.invalid_email");
        if (isValidationOk) {
          this.focusElement("healthcheck_mail_to");
          isValidationOk = false;
        }
      }
      if (!this.host) {
        this.error.host = "common.required";
        if (isValidationOk) {
          this.focusElement("host");
          isValidationOk = false;
        }
      }
      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusAlreadySet = false;

      for (const validationError of validationErrors) {
        const field = validationError.field;

        if (field !== "(root)") {
          // set i18n error message
          // JSON schema range errors (e.g. "<field>_number_lte") share one text
          const error = /_number_(lte|gte|lt|gt)$/.test(validationError.error)
            ? "value_out_of_range"
            : validationError.error;
          this.error[field] = this.$t("settings." + error);

          if (!focusAlreadySet) {
            this.focusElement(field);
            focusAlreadySet = true;
          }
        }
      }
    },
    async configureModule() {
      const isValidationOk = this.validateConfigureModule();
      if (!isValidationOk) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.configureModuleAborted
      );

      // register to task validation
      this.core.$root.$once(
        `${taskAction}-validation-failed-${eventId}`,
        this.configureModuleValidationFailed
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.configureModuleCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            host: this.host,
            lets_encrypt: this.lets_encrypt,
            http2https: this.http2https,
            timezone: this.timezone || "UTC",
            smtp_host: this.smtp_host,
            smtp_port: this.smtp_port || 587,
            smtp_username: this.smtp_username,
            smtp_password: this.smtp_password,
            smtp_starttls: this.smtp_starttls,
            smtp_ssl_verify: this.smtp_ssl_verify,
            smtp_from: this.smtp_from,
            enable_insecure_agents: this.enable_insecure_agents,
            enable_second_precision_schedule:
              this.enable_second_precision_schedule,
            invitation_code: this.invitation_code,
            require_confirmed_email: this.require_confirmed_email,
            openai_api_key: this.openai_api_key,
            openai_api_key_remove: this.openai_api_key_remove,
            openai_base_url: this.openai_base_url,
            delayed_job_max_runtime: Number(this.delayed_job_max_runtime),
            delayed_job_sleep_delay: Number(this.delayed_job_sleep_delay),
            database_pool: Number(this.database_pool),
            delayed_job_workers: Number(this.delayed_job_workers),
            healthcheck_mode: this.healthcheck_mode,
            healthcheck_minutes: Number(this.healthcheck_minutes),
            healthcheck_backlog: Number(this.healthcheck_backlog),
            healthcheck_mail_to: this.healthcheck_mail_to,
          },
          extra: {
            title: this.$t("settings.configure_instance", {
              instance: this.instanceName,
            }),
            description: this.$t("common.processing"),
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
        return;
      }
    },
    async getAdminPassword() {
      const taskAction = "get-admin-password";
      const eventId = this.getUuid();
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        (taskContext, taskResult) => {
          this.admin_password = taskResult.output.admin_password || "";
        }
      );
      await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("settings.show_admin_password"),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;

      // reload configuration
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.toggle {
  margin-top: $spacing-06;
}
.section-title {
  margin-top: $spacing-07;
}
.section-help {
  margin-bottom: $spacing-05;
  color: $text-02;
}
.admin-credentials {
  margin-top: $spacing-06;
}
.feature-warning {
  margin-top: $spacing-05;
}
.proxy-hint {
  margin-top: $spacing-06;
}
.stale-agents {
  margin-top: $spacing-05;
}
</style>
