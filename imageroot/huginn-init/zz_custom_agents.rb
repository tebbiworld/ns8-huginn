# Copyright (C) 2026 tebbi
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Load user-provided custom Huginn agents from a mounted directory.
#
# The NS8 module mounts a writable volume at /app/custom_agents and lets the
# administrator upload agent .rb files through the web UI. Each file is
# required individually inside an after_initialize hook (so the base Agent
# class is already loaded) and wrapped in a rescue, so that a single broken
# agent logs an error instead of preventing Huginn from booting.

Rails.application.config.after_initialize do
  custom_dir = ENV.fetch("CUSTOM_AGENTS_DIR", "/app/custom_agents")
  next unless Dir.exist?(custom_dir)

  Dir.glob(File.join(custom_dir, "*.rb")).sort.each do |file|
    begin
      require file
      Rails.logger.info("[custom-agents] loaded #{File.basename(file)}")
    rescue StandardError, ScriptError => e
      Rails.logger.error("[custom-agents] FAILED #{File.basename(file)}: #{e.class}: #{e.message}")
    end
  end
end
