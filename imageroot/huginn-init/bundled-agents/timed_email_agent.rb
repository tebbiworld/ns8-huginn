# Alle benutzerdefinierten Agenten befinden sich im Modul 'Agents'
module Agents
  # Definition eines einfachen Zeit-basierten Agenten
  class TimedEmailAgent < Agent

    # Dieser Agent empfaengt keine Events von anderen
    cannot_receive_events!

    # Standardzeitplan: Fuehrt einmal pro Stunde aus
    default_schedule "every_hour"

    # Beschreibung fuer das Webinterface von Huginn
    description <<-MD
      Dieser Agent erzeugt bei jeder Ausfuehrung ein Event mit
      headline, subject und message. Der EmailAgent uebernimmt
      den Versand und die Darstellung.
    MD

    # Standardwerte, die beim Erstellen im Webinterface angezeigt werden
    def default_options
      {
        'headline' => 'Erinnerung',
        'subject' => 'Hinweis',
        'message' => 'Dies ist eine automatisch gesendete Nachricht.'
      }
    end

    # Validierung: Stellt sicher, dass alle noetigen Felder gesetzt sind
    def validate_options
      errors.add(:base, "headline fehlt") unless options['headline'].present?
      errors.add(:base, "subject fehlt")  unless options['subject'].present?
      errors.add(:base, "message fehlt")     unless options['message'].present?
    end

    # Gibt true zurueck, wenn keine Fehler im Log aufgetreten sind
    def working?
      !recent_error_logs?
    end

    # Hauptfunktion: Wird gemaess Zeitplan automatisch aufgerufen
    def check
      # Eintrag ins Agenten-Log mit Zeitstempel (UTC)
      log("Check durchlaufen: #{Time.now.utc.iso8601}")

      # Event erzeugen mit drei definierten Feldern
      create_event(payload: {
        headline: options['headline'],
        subject:  options['subject'],
        message:  options['message']
      })
    end

  end
end
