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
              <template slot="text-left">{{ $t("settings.disabled") }}</template>
              <template slot="text-right">{{ $t("settings.enabled") }}</template>
            </cv-toggle>
            <cv-toggle
              value="http2https"
              :label="$t('settings.http2https')"
              v-model="http2https"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="toggle"
            >
              <template slot="text-left">{{ $t("settings.disabled") }}</template>
              <template slot="text-right">{{ $t("settings.enabled") }}</template>
            </cv-toggle>
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
              <template slot="text-left">{{ $t("settings.disabled") }}</template>
              <template slot="text-right">{{ $t("settings.enabled") }}</template>
            </cv-toggle>
            <NsInlineNotification
              v-if="admin_username"
              kind="info"
              :title="$t('settings.admin_credentials')"
              :description="
                $t('settings.admin_credentials_desc', {
                  user: admin_username,
                  password: admin_password,
                })
              "
              :showCloseButton="false"
              class="admin-credentials"
            />
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
      smtp_from: "",
      admin_username: "",
      admin_password: "",
      loading: {
        getConfiguration: false,
        configureModule: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        host: "",
        timezone: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
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
      this.smtp_password = config.smtp_password || "";
      this.smtp_starttls =
        config.smtp_starttls === undefined ? true : !!config.smtp_starttls;
      this.smtp_from = config.smtp_from || "";
      this.admin_username = config.admin_username || "";
      this.admin_password = config.admin_password || "";

      this.focusElement("host");
    },
    validateConfigureModule() {
      this.clearErrors(this);
      let isValidationOk = true;

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
          this.error[field] = this.$t("settings." + validationError.error);

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
            smtp_from: this.smtp_from,
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
</style>
