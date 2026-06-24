# Copyright (C) 2026 tebbi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Load user-provided and bundled custom Huginn agents.
#
# Huginn builds its list of usable agent types (Agent::TYPES) by scanning the
# app/models/agents directory at boot, so agents that merely live elsewhere are
# rejected as "not a valid type". To support agents from mounted directories
# without overlaying the built-in agents folder, we:
#
#   1. require every .rb in the bundled and custom agent directories
#      (each individually wrapped in a rescue, so a single broken agent only
#      logs an error instead of preventing Huginn from booting), and
#   2. register every freshly loaded Agents::* class in Agent::TYPES so the web
#      UI offers it and Agent.valid_type? accepts it.
#
# The directories are mounted by the NS8 module:
#   /app/bundled_agents  read-only agents shipped with the module
#   /app/custom_agents   agents uploaded by the administrator

Rails.application.config.after_initialize do
  next unless defined?(Agent::TYPES)

  dirs = [
    ENV.fetch("BUNDLED_AGENTS_DIR", "/app/bundled_agents"),
    ENV.fetch("CUSTOM_AGENTS_DIR", "/app/custom_agents"),
  ]

  dirs.each do |dir|
    next unless Dir.exist?(dir)
    Dir.glob(File.join(dir, "*.rb")).sort.each do |file|
      begin
        require file
        Rails.logger.info("[custom-agents] required #{File.basename(file)}")
      rescue StandardError, ScriptError => e
        Rails.logger.error("[custom-agents] FAILED #{File.basename(file)}: #{e.class}: #{e.message}")
      end
    end
  end

  # Register any agent class that was loaded from the directories above.
  Agent.descendants.each do |klass|
    name = klass.name
    next unless name && name.start_with?("Agents::")
    Agent::TYPES << name unless Agent::TYPES.include?(name)
  end
end
