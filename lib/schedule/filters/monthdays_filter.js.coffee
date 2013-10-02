class Schedule.Filters.MonthdaysFilter

  constructor: (monthdays...) ->
    throw "Specify at least one day of the month" if monthdays.length < 1

    @monthdays = monthdays.sort (a, b) -> a - b # really don't understand WHY this is needed, simple sort should do the same thing...

  match: (date) =>
    last = (new Date(date)).add(1).month().set(day: 1).add(-1).day().getDate()
    (@monthdays.indexOf(date.getDate()) >= 0 || @monthdays.indexOf(date.getDate() - last - 1) >= 0)

  step: =>
    {length: 1, unit: 'day', seconds: 86400}

  # FIXME - this can probably be calculated
  next: (date) =>
    date = new Date(date)
    until @match(date)
      date.add(1).day()

    date

  previous: (date) =>
    date = new Date(date)
    until @match(date)
      date.add(-1).day()

    date

  toString: =>
    days = _.map @monthdays, (d) -> "#{d}."
    last = days.pop()

    if days.length > 0
      "on #{days.join(", ")} and #{last} day"
    else
      "on #{last} day"
