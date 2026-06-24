# Datei: app/models/agents/payload_agent.rb

module Agents
  # Definition eines einfachen Zeit-basierten Agenten
  class PayloadAgent < Agent

    # Erlaubt Konfiguration ueber das Huginn-Frontend - hier koennte ein Fehler vorliegen
#    include FormConfigurable

    # Dieser Agent empfaengt keine Events von anderen
    cannot_receive_events!

    # Unterstützt die "Dry Run"-Funktion fuer Testlaeufe
    can_dry_run!

    # Standardzeitplan: kein automatischer Zeitplan
    default_schedule 'never'

    # Beschreibung fuer das Webinterface von Huginn
    description <<~MD
      Der PayloadAgent erzeugt ein einzelnes Event mit beliebig definierten Feldern als `payload`.

      Die Inhalte werden bei der Ausfuehrung interpretiert (Liquid-Templates moeglich) und koennen
      von empfangenden Agenten weiterverwendet werden.

      Mindestens ein Eintrag ist erforderlich.
    MD

    # Vorgabewerte fuer die initiale Anzeige im Optionsfeld
    def default_options
      {
          'option1' => 'Irgendein Text',
          'option2' => "Beispiel fuer liquid {{ 'now' | date: '%B' }}",
          'option3' => 'Automatisch generiert'
      }
    end

    # Validierung beim Speichern
    def validate_options
      errors.add(:base, "mindestens ein Feld muss gesetzt sein") if options.blank? || options.empty?
    end

    # Agent gilt als funktionierend, wenn ein Event erzeugt wurde
    def working?
      !recent_error_logs?
    end

    # Hauptfunktion des Agenten: Event mit Inhalt aus `payload` erzeugen
    def check
      create_event payload: interpolated
    end
  end
end
