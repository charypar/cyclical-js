class Schedule.Filters.WeekdaysFilter
  
  WEEKDAYS: {
    su: 0, sun: 0, sunday: 0,
    mo: 1, mon: 1, monday: 1,
    tu: 2, tue: 2, tuesday: 2,
    we: 3, wed: 3, wednesday: 3,
    th: 4, thu: 4, thursday: 4,
    fr: 5, fri: 5, friday: 5,
    sa: 6, sat: 6, saturday: 6
  }
  
  WEEKDAY_NAMES: ['su', 'mo', 'tu', 'we', 'th', 'fr', 'sa']

  constructor: (weekdays...) ->
    @rule = weekdays.shift() if weekdays[0] instanceof Schedule.Rule 
    
    throw "Specify at least one weekday" if weekdays.length < 1
    @orderedWeekdays = {}

    if weekdays[weekdays.length-1] instanceof Object
      throw "No recurrence rule given for ordered weekdays filter" unless @rule?
      
      for day, orders of weekdays[weekdays.length-1]
        day = unless isNaN(parseFloat(day)) then day else @WEEKDAYS[day]
        orders = [orders] unless orders.length?

        @orderedWeekdays[@WEEKDAY_NAMES[day]] = orders.sort()

      weekdays = weekdays.slice(0, -1)
    
    @weekdays = ((unless isNaN(parseFloat(w)) then w else @WEEKDAYS[w]) for w in weekdays)
    @weekdays.sort()

  match: (date) =>
    return true if @weekdays.indexOf(date.getDay()) >= 0
    
    day = @WEEKDAY_NAMES[date.getDay()]
    return false unless @orderedWeekdays[day]?

    [first, occ, max] = @_orderInInterval(date)
    
    return (@orderedWeekdays[day].indexOf(occ) >= 0 || @orderedWeekdays[day].indexOf(occ - max - 1) >= 0)

  step: =>
    {length: 1, unit: 'day', seconds: 846000}

  # FIXME - this can probably be calculated
  next: (date) =>
    date = new Date(date)
    MAX_ITERATIONS = 10000
    until @match(date)
      throw "Maximum iterations reached in WeekdaysFilter.next" unless MAX_ITERATIONS-- > 0
      date.add(1).day()

    date

  previous: (date) =>
    date = new Date(date)
    MAX_ITERATIONS = 10000
    until @match(date)
      throw "Maximum iterations reached in WeekdaysFilter.previous" unless MAX_ITERATIONS-- > 0
      date.add(-1).day()

    date

  # FIXME
  _orderInInterval: (date) =>
    janfirst = (new Date(date)).set(month: 0, day: 1)
    
    if @rule instanceof Schedule.Rules.YearlyRule
      first = (7 + date.getDay() - janfirst.getDay()) % 7 + 1
      
      yday = Math.ceil((date -  janfirst) / 1000 / 60 / 60 / 24) + 1
      occ = ~~((yday - first) / 7) + 1
      
      eoy = (new Date(date)).add(1).year().set(month: 0, day: 1).add(-1).day()
      eyday = Math.ceil((eoy - janfirst) / 1000 / 60 / 60 / 24) + 1
      max = ~~((eyday - first) / 7) + 1      
    else if @rule instanceof Schedule.Rules.MonthlyRule
      first = (7 + date.getDay() - (new Date(date)).set(day: 1).getDay()) % 7 + 1
      occ = ~~((date.getDate() - first) / 7) + 1
      max = ~~(((new Date(date)).add(1).month().set(day: 1).add(-1).day().getDate() - first) / 7) + 1
    else
      throw "Ordered weekdays filter only supports monthy and yearly rules. (#{@rule.class} given)"

    [first, occ, max]
  
  toString: =>
    dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    
    wdays = _.map @weekdays, (w) -> dayNames[w]

    owdays = _.map @orderedWeekdays, (ord, d) =>
      "#{_.map(ord, (o) -> "#{o}.").join(", ")} #{dayNames[@WEEKDAYS[d]]}"
      
    days = wdays.concat(owdays)
    last = days.pop()

    if days.length > 0
      "on #{days.join(", ")} and #{last}"
    else
      "on #{last}"    