class Schedule.Rules.DailyRule extends Schedule.Rule

  aligned: (time, base) =>
    [time, base] = [new Date(time), new Date(base)]
    return false unless ((new Date(base)).at(hour: 0, minute: 0, second: 0) - (new Date(time)).at(hour: 0, minute: 0, second: 0)) % @interval == 0
    return false unless time.getHours() == base.getHours() && time.getMinutes() == base.getMinutes() && time.getSeconds() == base.getSeconds()

    true

  freq: =>
    'daily'

  step: =>
    {length: @interval, unit: 'days', seconds: (@interval * 86400)}

  toString: =>
    sup = super()
    string = if @interval > 1 then "Every #{@interval} days" else "Daily"
    string += ", #{sup}" if sup

    string

  _potentialNext: (current, base) =>
    candidate = super(current, base)

    rem = ((new Date(base)).at(hour: 0, minute: 0, second: 0) - (new Date(candidate)).at(hour: 0, minute: 0, second: 0)) % @interval

    return candidate if rem == 0

    (new Date(candidate)).add(rem).days().at(hour: 0, minute: 0, second: 0)

  _potential_previous: (current, base) =>
    candidate = super(current, base)

    rem = ((new Date(base)).at(hour: 0, minute: 0, second: 0) - (new Date(candidate)).at(hour: 0, minute: 0, second: 0)) % @interval

    return candidate if rem == 0

    (new Date(candidate)).add(rem - @interval).days().at(hour: 0, minute: 0)

  _align: (time, base) =>
    time = (new Date(time)).at(hour: 0, minute: 0, second: 0).add(hours: base.getHours(), minutes: base.getMinutes(), seconds: base.getSeconds())

