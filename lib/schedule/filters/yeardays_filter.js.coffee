
class Schedule.Filters.YeardaysFilter
    
  constructor: (yeardays...) ->
    throw "Specify at least one day of the month" if yeardays.length < 1

    @yeardays = yeardays.sort()
  
  match: (date) =>
    eoy = (new Date(date)).set(month: 0, day: 1).add(1).year().add(-1).day() # huh...
    last = @yearDay(eoy)
    
    (@yeardays.indexOf(@yearDay(date)) >= 0) || (@yeardays.indexOf(@yearDay(date) - last - 1) >= 0)
  
  step: () =>
    {length: 1, unit: 'day', seconds: 86400}
  
  # FIXME - traverse the days directly
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
    
  yearDay: (date) =>
    date = new Date(date)
    janFirst = (new Date(date)).set(month: 0, day: 1)
    
    Math.ceil((date - janFirst) / 86400000) + 1

  toString: =>
    days = _.map @yeardays, (d) -> "#{d}."
    last = days.pop()
    
    if days.length > 0
      "on #{days.join(", ")} and #{last} day"
    else
      "on #{last} day"
