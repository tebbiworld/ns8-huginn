<!--
  Copyright (C) 2026 tebbi
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title">
        <h2>{{ $t("agents.title") }}</h2>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <p class="page-description">{{ $t("agents.description") }}</p>
      </cv-column>
    </cv-row>

    <cv-row v-if="error.listCustomAgents">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.list-custom-agents')"
          :description="error.listCustomAgents"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>

    <!-- Upload -->
    <cv-row>
      <cv-column>
        <cv-tile light>
          <h4>{{ $t("agents.upload_title") }}</h4>
          <div class="upload-row">
            <input
              ref="fileInput"
              type="file"
              accept=".rb"
              @change="onFileChange"
              :disabled="loading.uploadCustomAgent"
            />
          </div>
          <div v-if="selectedName" class="selected-file">
            {{ $t("agents.selected_file") }}: <strong>{{ selectedName }}</strong>
          </div>
          <NsInlineNotification
            v-if="error.uploadCustomAgent"
            kind="error"
            :title="$t('action.upload-custom-agent')"
            :description="error.uploadCustomAgent"
            :showCloseButton="false"
          />
          <NsInlineNotification
            v-if="restartNotice"
            kind="info"
            :title="$t('agents.restart_title')"
            :description="$t('agents.restart_desc')"
            :showCloseButton="true"
            @close="restartNotice = false"
          />
          <NsButton
            kind="primary"
            :icon="Upload20"
            :loading="loading.uploadCustomAgent"
            :disabled="!selectedContent || loading.uploadCustomAgent"
            @click="uploadAgent"
            >{{ $t("agents.upload") }}</NsButton
          >
        </cv-tile>
      </cv-column>
    </cv-row>

    <!-- Installed agents -->
    <cv-row>
      <cv-column>
        <cv-tile light>
          <h4>{{ $t("agents.installed_title") }}</h4>
          <cv-skeleton-text
            v-if="loading.listCustomAgents"
            :paragraph="true"
            :line-count="3"
          ></cv-skeleton-text>
          <div v-else-if="!agents.length" class="empty">
            {{ $t("agents.no_agents") }}
          </div>
          <table v-else class="agents-table">
            <thead>
              <tr>
                <th>{{ $t("agents.file_name") }}</th>
                <th>{{ $t("agents.size") }}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="a in agents" :key="a.filename">
                <td>{{ a.filename }}</td>
                <td>{{ a.size }} B</td>
                <td class="actions-cell">
                  <NsButton
                    kind="danger--tertiary"
                    size="small"
                    :icon="TrashCan20"
                    :disabled="loading.removeCustomAgent"
                    @click="removeAgent(a.filename)"
                    >{{ $t("agents.remove") }}</NsButton
                  >
                </td>
              </tr>
            </tbody>
          </table>
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
  name: "CustomAgents",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
  ],
  pageTitle() {
    return this.$t("agents.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "agents",
      },
      urlCheckInterval: null,
      agents: [],
      selectedName: "",
      selectedContent: "",
      restartNotice: false,
      loading: {
        listCustomAgents: false,
        uploadCustomAgent: false,
        removeCustomAgent: false,
      },
      error: {
        listCustomAgents: "",
        uploadCustomAgent: "",
        removeCustomAgent: "",
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
    this.listAgents();
  },
  methods: {
    onFileChange(event) {
      this.error.uploadCustomAgent = "";
      const file = event.target.files && event.target.files[0];
      if (!file) {
        this.selectedName = "";
        this.selectedContent = "";
        return;
      }
      this.selectedName = file.name;
      const reader = new FileReader();
      reader.onload = (e) => {
        this.selectedContent = e.target.result;
      };
      reader.readAsText(file);
    },
    async listAgents() {
      this.loading.listCustomAgents = true;
      this.error.listCustomAgents = "";
      const taskAction = "list-custom-agents";
      const eventId = this.getUuid();
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.listAgentsAborted
      );
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.listAgentsCompleted
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
        this.error.listCustomAgents = this.getErrorMessage(err);
        this.loading.listCustomAgents = false;
      }
    },
    listAgentsAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.listCustomAgents = this.$t("error.generic_error");
      this.loading.listCustomAgents = false;
    },
    listAgentsCompleted(taskContext, taskResult) {
      this.loading.listCustomAgents = false;
      this.agents = (taskResult.output && taskResult.output.agents) || [];
    },
    async uploadAgent() {
      this.error.uploadCustomAgent = "";
      this.loading.uploadCustomAgent = true;
      const taskAction = "upload-custom-agent";
      const eventId = this.getUuid();
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.uploadAgentAborted
      );
      this.core.$root.$once(
        `${taskAction}-validation-failed-${eventId}`,
        this.uploadAgentValidationFailed
      );
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.uploadAgentCompleted
      );
      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            filename: this.selectedName,
            content: this.selectedContent,
          },
          extra: {
            title: this.$t("action." + taskAction),
            description: this.selectedName,
            eventId,
          },
        })
      );
      const err = res[0];
      if (err) {
        this.error.uploadCustomAgent = this.getErrorMessage(err);
        this.loading.uploadCustomAgent = false;
      }
    },
    uploadAgentAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.uploadCustomAgent = this.$t("error.generic_error");
      this.loading.uploadCustomAgent = false;
    },
    uploadAgentValidationFailed(validationErrors) {
      this.loading.uploadCustomAgent = false;
      for (const e of validationErrors) {
        if (e.error === "ruby_syntax_error") {
          this.error.uploadCustomAgent =
            this.$t("agents.ruby_syntax_error") + " " + (e.value || "");
        } else if (e.error === "invalid_file_name") {
          this.error.uploadCustomAgent = this.$t("agents.invalid_file_name");
        } else {
          this.error.uploadCustomAgent = this.$t("error.validation_error");
        }
      }
    },
    uploadAgentCompleted() {
      this.loading.uploadCustomAgent = false;
      this.restartNotice = true;
      this.selectedName = "";
      this.selectedContent = "";
      if (this.$refs.fileInput) {
        this.$refs.fileInput.value = "";
      }
      this.listAgents();
    },
    async removeAgent(filename) {
      this.error.removeCustomAgent = "";
      this.loading.removeCustomAgent = true;
      const taskAction = "remove-custom-agent";
      const eventId = this.getUuid();
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.removeAgentAborted
      );
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.removeAgentCompleted
      );
      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: { filename },
          extra: {
            title: this.$t("action." + taskAction),
            description: filename,
            eventId,
          },
        })
      );
      const err = res[0];
      if (err) {
        this.error.removeCustomAgent = this.getErrorMessage(err);
        this.loading.removeCustomAgent = false;
      }
    },
    removeAgentAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.loading.removeCustomAgent = false;
    },
    removeAgentCompleted() {
      this.loading.removeCustomAgent = false;
      this.restartNotice = true;
      this.listAgents();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.page-description {
  margin-bottom: $spacing-05;
}
.upload-row {
  margin: $spacing-05 0;
}
.selected-file {
  margin-bottom: $spacing-05;
}
.agents-table {
  width: 100%;
  border-collapse: collapse;
  th,
  td {
    text-align: left;
    padding: $spacing-03 $spacing-05;
    border-bottom: 1px solid $ui-03;
  }
}
.actions-cell {
  text-align: right;
}
.empty {
  color: $text-02;
  margin: $spacing-05 0;
}
</style>
