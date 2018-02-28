class Event < ApplicationRecord
  SLOT_DURATION = 30.minutes.freeze
  PAGINATED_DAYS = 7.days.freeze

  scope :openings, -> { where(kind: 'opening') }
  scope :appointments, -> { where(kind: 'appointment') }

  def self.recurring_openings_for_weekday(weekday)
    openings
      .where(weekly_recurring: true)
      .where("strftime('%w', starts_at) = '?'", weekday)
  end

  def self.solely_opened_for_day(date)
    openings
      .where(weekly_recurring: [false, nil])
      .where('starts_at >= ? AND ends_at <= ?', date, date + 1.day)
  end

  def self.openings_for_day(date)
    recurring_openings_for_weekday(date.wday) + solely_opened_for_day(date)
  end

  def self.appointments_for_day(date)
    appointments
      .where(starts_at: date.beginning_of_day..date.end_of_day)
  end

  def self.availabilities(requested_date_time)
    _selected_days(requested_date_time).map do |date|
      { date: date, slots: available_slots_for_day(date) }
    end
  end

  def self.available_slots_for_day(date)
    opening_slots(date) - appointment_slots(date)
  end

  def self.opening_slots(date)
    openings_for_day(date).map(&:to_slots).flatten.uniq
  end

  def self.appointment_slots(date)
    appointments_for_day(date).map(&:to_slots).flatten.uniq
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
