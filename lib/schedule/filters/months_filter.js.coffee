class Schedule.Filters.MonthsFilter

  MONTH_NAMES: {
    jan: 1, january: 1,
    feb: 2, february: 2,
    mar: 3, march: 3,
    apr: 4, april: 4,
    may: 5,
    jun: 6, june: 6,
    jul: 7, july: 7,
    aug: 8, august: 8,
    sep: 9, sept: 9, september: 9,
    oct: 10, october: 10,
    nov: 11, november: 11,
    dec: 12, december: 12
  }

  constructor: (months...) ->
    throw "Specify at least one month" if months.length < 1

    @months = ((unless isNaN(parseFloat(month)) then month else @MONTH_NAMES[month]) for month in months)
    @months = @months.sort()

  match: (date) =>
    @months.indexOf(date.getMonth() + 1) >= 0

  step: ->
    {length: 1, unit: 'month', seconds: 2592000}

  next: (date) =>
    return date if @match(date)

    month = null
    for m in @months
      month = m if (m > date.getMonth() + 1)

    if month?
      (new Date(date)).set(month: 0, day: 1).add(month - 1).months().at(hour: date.getHours(), minute: date.getMinutes(), second: date.getSeconds())
    else
      d = (new Date(date)).set(month: 0, day: 1).add(1).year().add(@months[0] - 1).months()
      d.at(hour: date.getHours(), minute: date.getMinutes(), second: date.getSeconds())

  previous: (date) =>
    return date if match(date)

    month = null
    for m in @months.reverse()
      month = m if (m < date.getMonth() + 1)

    if month?
      d = (new Date(date)).set(month: 0, day: 1).add(month).months().add(-1).day()
      d.at(hour: date.getHours(), minute: date.getMinutes(), second: date.getSeconds())
    else
      d = (new Date(date)).set(month: 0, day: 1).add(-1).year().add(@months.last).months().add(-1).day()
      d.at(hour: date.getHours(), minute: date.getMinutes(), second: date.getSeconds())

  toString: =>
    monthNames = [null, "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    months = _.map @months, (m) -> monthNames[m]
    last = months.pop()

    if months.length > 0
      "in #{months.join(", ")} and #{last}"
    else
      "in #{last}"
