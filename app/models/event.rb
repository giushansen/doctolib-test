class Event < ApplicationRecord
  SLOT_DURATION = 30.minutes.freeze
  PAGINATED_DAYS = 7.days.freeze

  scope :openings, -> { where(kind: 'opening') }
  scope :appointments, -> { where(kind: 'appointment') }

  def self.recurring_openings
    openings
      .select(:starts_at, :ends_at, :weekly_recurring)
      .where(weekly_recurring: true)
      .group(%i[starts_at ends_at])
  end

  def self.solely_opened_for_week(date)
    openings
      .select(:starts_at, :ends_at, :weekly_recurring)
      .where('starts_at >= ? AND ends_at <= ?', date, date + PAGINATED_DAYS)
  end

  def self.openings_for_week(date)
    (recurring_openings + solely_opened_for_week(date))
      .to_a
  end

  def self.appointments_for_week(date)
    appointments
      .select(:starts_at, :ends_at)
      .where(starts_at: date..(date + PAGINATED_DAYS))
      .to_a
  end

  def self.availabilities(requested_date_time)
    openings = openings_for_week(requested_date_time)
    appointments = appointments_for_week(requested_date_time)

    _selected_days(requested_date_time).map do |date|
      { date: date, slots: available_slots_for_day(date, openings, appointments) }
    end
  end

  def self.available_slots_for_day(date, openings, appointments)
    opening_slots_for_day(date, openings) - appointment_slots_for_day(date, appointments)
  end

  def self.opening_slots_for_day(date, openings)
    openings
      .select do |opening|
        opening.starts_at.to_date == date.to_date ||
          (opening.weekly_recurring == true && opening.starts_at.wday == date.wday)
      end
      .map(&:to_slots)
      .flatten
      .uniq
  end

  def self.appointment_slots_for_day(date, appointments)
    appointments
      .select do |appointment|
        appointment.starts_at.to_date == date.to_date
      end
      .map(&:to_slots)
      .flatten
      .uniq
  end

  def to_slots
    slots = []
    i = starts_at
    while i <= (ends_at - SLOT_DURATION)
      slots << i.strftime('%k:%M').strip
      i += SLOT_DURATION
    end
    slots
  end

  def self._selected_days(requested_date_time)
    first_day = requested_date_time.to_date
    last_day = first_day + PAGINATED_DAYS
    first_day...last_day
  end

  private_class_method :_selected_days
end
