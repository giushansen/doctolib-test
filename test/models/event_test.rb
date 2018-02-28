require 'test_helper'

class EventTest < ActiveSupport::TestCase
  def setup
    Event.delete_all
  end

  test 'Doctolib simple test example' do
    Event.create kind: 'opening', starts_at: DateTime.parse('2014-08-04 09:30'), ends_at: DateTime.parse('2014-08-04 12:30'), weekly_recurring: true
    Event.create kind: 'appointment', starts_at: DateTime.parse('2014-08-11 10:30'), ends_at: DateTime.parse('2014-08-11 11:30')

    availabilities = Event.availabilities DateTime.parse('2014-08-10')
    assert_equal Date.new(2014, 8, 10), availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]
    assert_equal Date.new(2014, 8, 11), availabilities[1][:date]
    assert_equal ['9:30', '10:00', '11:30', '12:00'], availabilities[1][:slots]
    assert_equal Date.new(2014, 8, 16), availabilities[6][:date]
    assert_equal 7, availabilities.length
  end

  test 'should open weekly ad vitam aeternam' do
    Event.create!(
      kind: 'opening',
      starts_at: DateTime.parse('Mon, 04 Aug 2014 09:30:00 +0000'),
      ends_at: DateTime.parse('Mon, 04 Aug 2014 12:30:00 +0000'),
      weekly_recurring: true
    )
    Event.create!(
      kind: 'appointment',
      starts_at: DateTime.parse('Mon, 06 Aug 2018 10:30:00 +0000'),
      ends_at: DateTime.parse('Mon, 06 Aug 2018 11:30:00 +0000')
    )

    availabilities = Event.availabilities DateTime.parse('2018-08-06')
    assert_equal Date.new(2018, 8, 6), availabilities[0][:date]
    assert_equal ['9:30', '10:00', '11:30', '12:00'], availabilities[0][:slots]
  end

  test 'should not open weekly by default' do
    Event.create!(
      kind: 'opening',
      starts_at: DateTime.parse('Mon, 04 Aug 2014 09:30:00 +0000'),
      ends_at: DateTime.parse('Mon, 04 Aug 2014 12:30:00 +0000')
    )
    Event.create!(
      kind: 'appointment',
      starts_at: DateTime.parse('Mon, 06 Aug 2018 10:30:00 +0000'),
      ends_at: DateTime.parse('Mon, 06 Aug 2018 11:30:00 +0000')
    )

    availabilities = Event.availabilities DateTime.parse('2018-08-06')
    assert_equal Date.new(2018, 8, 6), availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]
  end

  test 'should open for a specific day' do
    Event.create!(
      kind: 'opening',
      starts_at: DateTime.parse('Tue, 07 Aug 2018 10:30:00 +0000'),
      ends_at: DateTime.parse('Tue, 07 Aug 2018 11:30:00 +0000')
    )
    Event.create!(
      kind: 'appointment',
      starts_at: DateTime.parse('Tue, 07 Aug 2018 11:00:00 +0000'),
      ends_at: DateTime.parse('Tue, 07 Aug 2018 11:30:00 +0000')
    )

    availabilities = Event.availabilities DateTime.parse('2018-08-07')
    assert_equal Date.new(2018, 8, 7), availabilities[0][:date]
    assert_equal ['10:30'], availabilities[0][:slots]
  end
end
