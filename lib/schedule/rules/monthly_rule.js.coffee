class Schedule.Rules.MonthlyRule extends Schedule.Rule

  # check if time is aligned to a base time, including interval check  
  aligned: (time, base) =>
    return false unless ((12 * base.getFullYear() + base.getMonth()) - (12 * time.getFullYear() + time.getMonth())) % @interval == 0
    return false unless time.getHours() == base.getHours() && time.getMinutes() == base.getMinutes() && time.getSeconds() == base.getSeconds()
    return false unless base.getDate() == time.getDate() || @_monthdayFilters()

    true

  freq: =>
    'monthly'

  # default step of the rule
  step: =>
    {length: @interval, unit: 'months', seconds: @interval * 2592000}

  toString: =>
    sup = super()
    string = if @interval > 1 then "Every #{@interval} months" else "Every month"
    string += ", #{sup}" if sup

    string


  _potentialNext: (current, base) =>
    candidate = super(current, base)

    rem = ((12 * base.getFullYear() + base.getMonth()) - (12 * candidate.getFullYear() + candidate.getMonth())) % @interval
    return candidate if rem == 0
    
    rem += @interval if rem < 0
    (new Date(candidate)).add(rem).months().set(day: 1).at(hour: 0, minute: 0, second: 0)

  _potentialPrevious: (current, base) =>
    candidate = super(current, base)

    rem = ((12 * base.getFullYear() + base.getMonth()) - (12 * candidate.getFullYear() + candidate.getMonth())) % @interval
    return candidate if rem == 0

    rem += @interval if rem < 0

    (new Date(candidate)).add(rem - @interval + 1).months().set(day: 1).add(-1).day().at(hour: 0, minute: 0, second: 0)

  _align: (time, base) =>
    time = (new Date(time)).set(day: 1).add(base.getDate() - 1).days() unless time.getDate() == base.getDate() || @_monthdayFilters()
    time = time.at(hour: 0, minute: 0, second: 0).add(hours: base.getHours(), minutes: base.getMinutes(), seconds: base.getSeconds())

  _monthdayFilters: =>
    @filters('weekdays')? || @filters('monthdays')? || @filters('yeardays')? || @filters('weeks')? || @filters('months')?
