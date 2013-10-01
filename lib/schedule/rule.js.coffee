#= require schedule/filters/months_filter
#= require schedule/filters/weekdays_filter
#= require schedule/filters/monthdays_filter
#= require schedule/filters/yeardays_filter

# Rules describe the basic recurrence patterns (frequency and interval) and hold the set of rules (called filters)
# that a candidate date must match to be included into the recurrence set.
# Rules can align a date to a closest date (in the past or in the future) matching all the filters with respect to
# selected start date of the recurrence. 
class Schedule.Rule
  constructor: (interval = 1) ->
    @interval = interval
    
    @_filters = []
    @_filterMap = {}

  # rule specification DSL
    
  count: (n) =>
    return @_count unless n

    @_count = n
    this

  stop: (t) =>
    return @_stop unless t

    @_stop = t
    this

  months: (months...) =>
    throw "Months filter already set" if @_filterMap.month?

    f = new Schedule.Filters.MonthsFilter(months...)
    @_filters.push(f)
    @_filterMap.months = f

    this
  
  month: (months...) =>
    @months(months...)

  weekdays: (weekdays...) =>
    throw "weekdays filter already set" if @_filterMap.weekdays?
    weekdays = [this].concat(weekdays)

    f = new Schedule.Filters.WeekdaysFilter(weekdays...)
    @_filters.push(f)
    @_filterMap.weekdays = f

    this

  weekday: (weekdays...) =>
    @weekdays(weekdays...)

  monthdays: (monthdays...) =>
    throw "monthdays filter already set" if @_filterMap.monthdays?

    f = new Schedule.Filters.MonthdaysFilter(monthdays...)
    @_filters.push(f)
    @_filterMap.monthdays = f

    this
  
  monthday: (monthdays...) =>
    @monthdays(monthdays...)

  yeardays: (yeardays...) =>
    throw "yeardays filter already set" if @_filterMap.yeardays?

    f = new Schedule.Filters.YeardaysFilter(yeardays...)
    @_filters.push(f)
    @_filterMap.yeardays = f

    this

  yearday: (yeardays...) =>
    yeardays(yeardays...)


  filters: (kind) =>
    return @_filters unless kind?

    @_filterMap[kind]

  # rule API

  isFinite: =>
    @count()? || @stop()?

  isInfinite: =>
    !@isFinite()
    
  # returns true if time is aligned to the recurrence pattern and matches all the filters
  match: (time, base) =>
    for filter in @_filters
      return false unless filter.match(time)
      
    return @aligned(time, base)

  # get next date matching the rule (not checking limits). Returns next occurrence even if +time+ matches the rule.
  next: (time, base) =>
    current = new Date(time)
    minStep = @_minStep()
    MAX_ITERATIONS = 1000
    
    until @match(current, base) && current > time
      throw "Maximum iterations reached when getting next rule occurrence..." unless MAX_ITERATIONS-- > 0
      
      potNext = @_align(@_potentialNext(current, base), base)
      potNext.add(minStep.length)[minStep.unit]() if Date.equals(potNext, current)
      current = potNext

    current

  # get previous date matching the rule (not checking limits). Returns next occurrence even if +time+ matches the rule.
  previous: (time, base) =>
    current = new Date(time)
    minStep = @_minStep()
    MAX_ITERATIONS = 1000

    until @match(current, base) && current < time 
      throw "Maximum iterations reached when getting previous occurrence..." unless MAX_ITERATIONS-- > 0
      
      potNext = @_align(@_potentialPrevious(current, base), base)
      potNext.add(-minStep.length)[minStep.unit]() if Date.equals(potNext, current)

      current = potNext

    current

  # basic building blocks of the computations

  aligned: (time, base) =>
    # for subclass to override

  freq: =>
    # for subclass to override

  step: =>
    # for subclass to override

  toObject: =>
    object = {freq: @freq(), interval: @interval}
    
    object.count = @count() if @count()?
    object.stop = @stop() if @stop()?
        
    object.weekdays = @filters('weekdays').weekdays.concat(@filters('weekdays').orderedWeekdays) if @filters('weekdays')?
    object.monthdays = @filters('monthdays').monthdays if @filters('monthdays')?
    object.yeardays = @filters('yeardays').yeardays if @filters('yeardays')?
    object.months = @filters('months').months if @filters('months')?

    object

  toJSON: =>
    JSON.stringify(@toObject())

  toString: =>
    dayNames = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    strings = []
    
    strings.push @filters('months').toString() if @filters('months')
    strings.push @filters('weekdays').toString() if @filters('weekdays')
    strings.push @filters('monthdays').toString() if @filters('monthdays')
    strings.push @filters('yeardays').toString() if @filters('yeardays')
    
    strings.push "end after #{@count()} times" if @count()
    
    strings.push "until #{monthNames[@stop().getMonth()]} #{@stop().getDate()}, #{@stop().getFullYear()}" if @stop()

    strings.join(", ")
    
  # protected api

  # Next comes the heart of all the calculations

  # Find a potential next date matching the rule as a maximum of next
  # valid dates from all the filters. Subclasses should add a check of
  # recurrence pattern match
  _potentialNext: (current, base) =>
    fNext = (filter.next(current) for filter in @filters())
    if fNext.length > 0 then new Date(Math.max(fNext...)) else current

  # Find a potential previous date matching the rule as a minimum of previous
  # valid dates from all the filters. Subclasses should add a check of
  # recurrence pattern match 
  _potentialPrevious: (current, base) =>
    fNext = (filter.previous(current) for filter in @filters())
    if fNext.length > 0 then new Date(Math.max(fNext...)) else current

  # Should return a time aligned to the base in the rule interval resolution, e.g.: 
  # - in a daily rule a time on the same day with a correct hour, minute and second
  # - in a weekly rule a time in the same week with a correct weekday, hour, minute and second 
  _align: (time, base) ->
    throw "#{typeof this}.align should be overriden and return a time in the period of time parameter, aligned to base"
  
  # Minimal step of all the filters and the recurrence rule. This allows the 
  # next/previous calculation to move a sane amount of time forward when all 
  # the filters and the rule match but the candidate is before/after the 
  # requested time (which is caused by date alignment)
  _minStep: =>
    return @__minStep if @__minStep?
    
    steps = (filter.step() for filter in @filters())
    steps.push(@step())

    @__minStep = steps[0]
    for i in [1...steps.length]
      @__minStep = steps[i] if steps[i].seconds < @__minStep.seconds
      
    @__minStep


# factory methods

Schedule.Rule.daily = (interval = 1) ->
  new Schedule.Rules.DailyRule(interval)

Schedule.Rule.yearly = (interval = 1) ->
  new Schedule.Rules.YearlyRule(interval)

Schedule.Rule.weekly = (interval = 1) ->
  new Schedule.Rules.WeeklyRule(interval)

Schedule.Rule.monthly = (interval = 1) ->
  new Schedule.Rules.MonthlyRule(interval)

Schedule.Rule.fromObject = (object) ->
  throw "Bad object format" unless object.freq && object.interval

  rule = Schedule.Rule[object.freq](+object.interval)

  rule.count(object.count) if object.count?
  rule.stop(object.stop) if object.stop?

  rule.weekdays(object.weekdays...) if object.weekdays?
  rule.monthdays(object.monthdays...) if object.monthdays?
  rule.yeardays(object.yeardays...) if object.yeardays?
  rule.months(object.months...) if object.months?

  rule

Schedule.Rule.fromJSON = (json) ->
  o = JSON.parse(json)
  o.stop = Date.parseISO8601(o.stop) if o.stop

  Schedule.Rule.fromObject(o)
