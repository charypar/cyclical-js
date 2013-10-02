class Schedule.Rules.WeeklyRule extends Schedule.Rule

  # check if time is aligned to a base time, including interval check
  aligned: (time, base) =>
    base_mm = (new Date(base)).add(-base.getDay()).days().at(hour: 0, minute: 0, second: 0)
    time_mm = (new Date(time)).add(-time.getDay()).days().at(hour: 0, minute: 0, second: 0)

    return false unless (~~((base_mm - time_mm) / 604800000) % @interval) == 0 # 604800000 = 7.days
    return false unless time.getHours() == base.getHours() && time.getMinutes() == base.getMinutes() && time.getSeconds() == base.getSeconds()

    return false unless base.getDay() == time.getDay() || @_weekdayFilters()

    # wow, passed every test
    true

  freq: =>
    'weekly'

  # default step of the rule
  step: =>
    {length: @interval, unit: 'weeks', seconds: (@interval * 604800000)}

  toString: =>
    sup = super()
    string = if @interval > 1 then "Every #{@interval} weeks" else "Weekly"
    string += ", #{sup}" if sup

    string

  _potentialNext: (current, base) =>
    candidate = super(current, base)

    base_mm = (new Date(base)).add(-base.getDay()).days().at(hour: 0, minute: 0, second: 0)
    candidate_mm = (new Date(candidate)).add(-candidate.getDay()).days().at(hour: 0, minute: 0, second: 0)

    rem = (~~((base_mm - candidate_mm) / 604800000)) % @interval
    return candidate if rem == 0

    rem += @interval if rem < 0 # thanks very much, JS...

    next = (new Date(candidate).add(rem).weeks())
    next.add(-next.getDay()).days().at(hour: 0, minute: 0, second: 0)

  _potentialPrevious: (current, base) =>
    candidate = super(current, base)

    base_mm = (new Date(base)).add(-base.getDay()).days().at(hour: 0, minute: 0, second: 0)
    candidate_mm = (new Date(candidate)).add(-candidate.getDay()).days().at(hour: 0, minute: 0, second: 0)

    rem = (~~((base_mm - candidate_mm) / 604800000)) % @interval
    return candidate if rem == 0

    rem += @interval if rem < 0 # thanks very much, JS...

    next = (new Date(candidate)).add(rem).weeks().add(-@interval).weeks()
    next.add(-next.getDay()).days().at(hour: 0, minute: 0, second: 0).add(1).week().add(-1).second()

  _align: (time, base) =>
    time = (new Date(time)).add(-time.getDay()).days().at(hour: 0, minute: 0, second: 0).add(base.getDay()).days() unless time.getDay() == base.getDay() || @_weekdayFilters()

    time = (new Date(time)).at(hour: 0, minute: 0, second: 0).add(hours: base.getHours(), minutes: base.getMinutes(), seconds: base.getSeconds())

  _weekdayFilters: =>
    @filters('weekdays')? || @filters('monthdays')? || @filters('yeardays')? || @filters('yeardays')? || @filters('weeks')? || @filters('months')?
