class Schedule.Rules.YearlyRule extends Schedule.Rule

  # check if time is aligned to a base time, including interval check  
  aligned: (time, base) =>
    return false unless (base.getFullYear() - time.getFullYear()) % @interval == 0
    return false unless time.getHours() == base.getHours() && time.getMinutes() == base.getMinutes() && time.getSeconds() == base.getSeconds()
    return false unless time.getDate() == base.getDate() || @_dayFilters()
    return false unless time.getMonth() == base.getMonth() || @_monthFilters()

    # wow, passed every test
    true

  freq: =>
    'yearly'

  # default step of the rule
  step: ->
    {length: @interval, unit: 'years', seconds:  @interval * 31536000}

  toString: =>
    sup = super()
    string = if @interval > 1 then "Every #{@interval} years" else "Every year"
    string += ", #{sup}" if sup

    string


  # closest valid date
  _potentialNext: (current, base) =>
    candidate = super(current, base)
    return candidate if (base.getFullYear() - candidate.getFullYear()) % @interval == 0
    
    years = ((base.getFullYear() - candidate.getFullYear()) % @interval)
    years += @interval if years < 0
    
    (new Date(candidate)).add(years).years().set(month: 0, day: 1)

  _potentialPrevious: (current, base) =>
    candidate = super(current, base)
    return candidate if (base.getFullYear() - candidate.getFullYear()) % @interval == 0

    years = ((base.getFullYear() - candidate.getFullYear()) % @interval)
    years += @interval if years < 0

    (new Date(candidate)).add(years - @interval).years().set(month: 0, day: 1)

  _align: (time, base) =>
    day = (if @_dayFilters() then time.getDate() else base.getDate())
    mon = (if @_monthFilters() then time.getMonth() else base.getMonth())

    time = (new Date(time)).set(month: 0, day: 1).add(mon).months().add(day - 1).days() 

    time.at(hour: 0, minute: 0, second: 0).add(hours: base.getHours(), minutes: base.getMinutes(), seconds: base.getSeconds()) 
    
  _dayFilters: =>
    @filters('weekdays')? || @filters('monthdays')? || @filters('yeardays')?

  _monthFilters: =>
    @filters('weekdays')? || @filters('yeardays')? || @filters('weeks')? || @filters('months')?
