(function() {
  Date.parseISO8601 = function(string) {
    var i, minutes, parts, regex, _i, _len, _ref;
    regex = /^(\d{4}|[+\-]\d{6})(?:-(\d{2})(?:-(\d{2}))?)?(?:T(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{3}))?)?(?:(Z)|([+\-])(\d{2})(?::(\d{2}))?)?)?$/;
    if (!(parts = regex.exec(string))) {
      return null;
    }
    _ref = [1, 4, 5, 6, 7, 10, 11];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      i = _ref[_i];
      parts[i] = +parts[i] || 0;
    }
    parts[2] = (+parts[2] || 1) - 1;
    parts[3] = +parts[3] || 1;
    if (parts[8] !== 'Z' && (parts[9] != null)) {
      minutes = parts[10] * 60 + parts[11];
      if (parts[9] === '+') {
        minutes = -minutes;
      }
      parts[5] += minutes;
    }
    return new Date(Date.UTC.apply(Date, parts.slice(1, 8)));
  };

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    _this = this;

  window.Schedule = (function() {
    function Schedule(startTime, rule) {
      this.toString = __bind(this.toString, this);
      this.toJSON = __bind(this.toJSON, this);
      this.toObject = __bind(this.toObject, this);
      this.suboccurrencesBetween = __bind(this.suboccurrencesBetween, this);
      this.occurrencesBetween = __bind(this.occurrencesBetween, this);
      this.occurrences = __bind(this.occurrences, this);
      this.previousOccurrence = __bind(this.previousOccurrence, this);
      this.nextOccurrence = __bind(this.nextOccurrence, this);
      this.first = __bind(this.first, this);
      this.setEndTime = __bind(this.setEndTime, this);
      this.rule = __bind(this.rule, this);
      this.setRule = __bind(this.setRule, this);
      if (rule != null) {
        this.occurrence = new Schedule.Occurrence(rule, startTime);
      }
      this.startTime = this.occurrence ? this.occurrence.startTime : startTime;
    }

    Schedule.prototype.setRule = function(rule) {
      this.occurrence = rule != null ? null : new Schedule.Occurrence(rule, this.startTime);
      return this.occurrence.duration = this.endTime ? this.endTime - this.startTime : 0;
    };

    Schedule.prototype.rule = function() {
      if (this.occurrence != null) {
        return this.occurrence.rule;
      } else {
        return null;
      }
    };

    Schedule.prototype.setEndTime = function(time) {
      if (time < this.startTime) {
        throw "End time is before start time";
      }
      this.endTime = time;
      if (this.occurrence != null) {
        this.occurrence.duration = time - this.startTime;
      }
      return time;
    };

    Schedule.prototype.first = function(n) {
      if (this.occurrence == null) {
        return [this.startTime];
      }
      return this.occurrence.nextOccurrences(n, this.startTime);
    };

    Schedule.prototype.nextOccurrence = function(time) {
      if (this.occurrence == null) {
        return (this.startTime < time ? null : this.startTime);
      }
      return this.occurrence.nextOccurrence(time);
    };

    Schedule.prototype.previousOccurrence = function(time) {
      if (this.occurrence == null) {
        return (this.startTime >= time ? null : this.startTime);
      }
      return this.occurrence.previousOccurrence(time);
    };

    Schedule.prototype.occurrences = function(endTime) {
      if ((endTime == null) && this.occurrence && this.occurrence.rule.isInfinite()) {
        throw "You have to specify end time for an infinite schedule occurrence listing";
      }
      if (endTime != null) {
        return this.occurrencesBetween(this.startTime, endTime);
      } else {
        if (this.occurrence == null) {
          return [this.startTime];
        }
        return this.occurrence.all();
      }
    };

    Schedule.prototype.occurrencesBetween = function(t1, t2) {
      if (this.occurrence == null) {
        return (this.startTime < t1 || this.startTime >= t2 ? [] : [this.startTime]);
      }
      return this.occurrence.occurrencesBetween(t1, t2);
    };

    Schedule.prototype.suboccurrencesBetween = function(t1, t2) {
      if (this.endTime == null) {
        throw "Schedule must have an end time to compute suboccurrences";
      }
      if (this.occurrence == null) {
        return [
          Schedule.Suboccurrence.find({
            occurrence: [this.startTime, this.endTime],
            interval: [t1, t2]
          })
        ];
      }
      return this.occurrence.suboccurrencesBetween(t1, t2);
    };

    Schedule.prototype.toObject = function() {
      var o;
      o = this.occurrence != null ? this.occurrence.toObject() : {};
      o.start = this.startTime;
      if (this.endTime != null) {
        o.end = this.endTime;
      }
      return o;
    };

    Schedule.prototype.toJSON = function() {
      return JSON.stringify(this.toObject());
    };

    Schedule.prototype.toString = function() {
      return this.rule().toString();
    };

    return Schedule;

  })();

  Schedule.fromObject = function(object) {
    var endTime, rule, s, startTime;
    startTime = object.start;
    endTime = object.end;
    rule = object.freq && object.interval ? Schedule.Rule.fromObject(object) : null;
    s = new Schedule(startTime, rule);
    s.setEndTime(endTime);
    return s;
  };

  Schedule.fromJSON = function(json) {
    var o;
    o = JSON.parse(json);
    if (o.start != null) {
      o.start = Date.parseISO8601(o.start);
    }
    if (o.end != null) {
      o.end = Date.parseISO8601(o.end);
    }
    if (o.stop != null) {
      o.stop = Date.parseISO8601(o.stop);
    }
    return Schedule.fromObject(o);
  };

  Schedule.Rules = {};

  Schedule.Filters = {};

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  Schedule.Rule = (function() {
    function Rule(interval) {
      if (interval == null) {
        interval = 1;
      }
      this._minStep = __bind(this._minStep, this);
      this._potentialPrevious = __bind(this._potentialPrevious, this);
      this._potentialNext = __bind(this._potentialNext, this);
      this.toString = __bind(this.toString, this);
      this.toJSON = __bind(this.toJSON, this);
      this.toObject = __bind(this.toObject, this);
      this.step = __bind(this.step, this);
      this.freq = __bind(this.freq, this);
      this.aligned = __bind(this.aligned, this);
      this.previous = __bind(this.previous, this);
      this.next = __bind(this.next, this);
      this.match = __bind(this.match, this);
      this.isInfinite = __bind(this.isInfinite, this);
      this.isFinite = __bind(this.isFinite, this);
      this.filters = __bind(this.filters, this);
      this.yearday = __bind(this.yearday, this);
      this.yeardays = __bind(this.yeardays, this);
      this.monthday = __bind(this.monthday, this);
      this.monthdays = __bind(this.monthdays, this);
      this.weekday = __bind(this.weekday, this);
      this.weekdays = __bind(this.weekdays, this);
      this.month = __bind(this.month, this);
      this.months = __bind(this.months, this);
      this.stop = __bind(this.stop, this);
      this.count = __bind(this.count, this);
      this.interval = interval;
      this._filters = [];
      this._filterMap = {};
    }

    Rule.prototype.count = function(n) {
      if (!n) {
        return this._count;
      }
      this._count = n;
      return this;
    };

    Rule.prototype.stop = function(t) {
      if (!t) {
        return this._stop;
      }
      this._stop = t;
      return this;
    };

    Rule.prototype.months = function() {
      var f, months;
      months = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (this._filterMap.month != null) {
        throw "Months filter already set";
      }
      f = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Schedule.Filters.MonthsFilter, months, function(){});
      this._filters.push(f);
      this._filterMap.months = f;
      return this;
    };

    Rule.prototype.month = function() {
      var months;
      months = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.months.apply(this, months);
    };

    Rule.prototype.weekdays = function() {
      var f, weekdays;
      weekdays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (this._filterMap.weekdays != null) {
        throw "weekdays filter already set";
      }
      weekdays = [this].concat(weekdays);
      f = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Schedule.Filters.WeekdaysFilter, weekdays, function(){});
      this._filters.push(f);
      this._filterMap.weekdays = f;
      return this;
    };

    Rule.prototype.weekday = function() {
      var weekdays;
      weekdays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.weekdays.apply(this, weekdays);
    };

    Rule.prototype.monthdays = function() {
      var f, monthdays;
      monthdays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (this._filterMap.monthdays != null) {
        throw "monthdays filter already set";
      }
      f = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Schedule.Filters.MonthdaysFilter, monthdays, function(){});
      this._filters.push(f);
      this._filterMap.monthdays = f;
      return this;
    };

    Rule.prototype.monthday = function() {
      var monthdays;
      monthdays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.monthdays.apply(this, monthdays);
    };

    Rule.prototype.yeardays = function() {
      var f, yeardays;
      yeardays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (this._filterMap.yeardays != null) {
        throw "yeardays filter already set";
      }
      f = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Schedule.Filters.YeardaysFilter, yeardays, function(){});
      this._filters.push(f);
      this._filterMap.yeardays = f;
      return this;
    };

    Rule.prototype.yearday = function() {
      var yeardays;
      yeardays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return yeardays.apply(null, yeardays);
    };

    Rule.prototype.filters = function(kind) {
      if (kind == null) {
        return this._filters;
      }
      return this._filterMap[kind];
    };

    Rule.prototype.isFinite = function() {
      return (this.count() != null) || (this.stop() != null);
    };

    Rule.prototype.isInfinite = function() {
      return !this.isFinite();
    };

    Rule.prototype.match = function(time, base) {
      var filter, _i, _len, _ref;
      _ref = this._filters;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        filter = _ref[_i];
        if (!filter.match(time)) {
          return false;
        }
      }
      return this.aligned(time, base);
    };

    Rule.prototype.next = function(time, base) {
      var MAX_ITERATIONS, current, minStep, potNext;
      current = new Date(time);
      minStep = this._minStep();
      MAX_ITERATIONS = 1000;
      while (!(this.match(current, base) && current > time)) {
        if (!(MAX_ITERATIONS-- > 0)) {
          throw "Maximum iterations reached when getting next rule occurrence...";
        }
        potNext = this._align(this._potentialNext(current, base), base);
        if (Date.equals(potNext, current)) {
          potNext.add(minStep.length)[minStep.unit]();
        }
        current = potNext;
      }
      return current;
    };

    Rule.prototype.previous = function(time, base) {
      var MAX_ITERATIONS, current, minStep, potNext;
      current = new Date(time);
      minStep = this._minStep();
      MAX_ITERATIONS = 1000;
      while (!(this.match(current, base) && current < time)) {
        if (!(MAX_ITERATIONS-- > 0)) {
          throw "Maximum iterations reached when getting previous occurrence...";
        }
        potNext = this._align(this._potentialPrevious(current, base), base);
        if (Date.equals(potNext, current)) {
          potNext.add(-minStep.length)[minStep.unit]();
        }
        current = potNext;
      }
      return current;
    };

    Rule.prototype.aligned = function(time, base) {};

    Rule.prototype.freq = function() {};

    Rule.prototype.step = function() {};

    Rule.prototype.toObject = function() {
      var object;
      object = {
        freq: this.freq(),
        interval: this.interval
      };
      if (this.count() != null) {
        object.count = this.count();
      }
      if (this.stop() != null) {
        object.stop = this.stop();
      }
      if (this.filters('weekdays') != null) {
        object.weekdays = this.filters('weekdays').weekdays.concat(this.filters('weekdays').orderedWeekdays);
      }
      if (this.filters('monthdays') != null) {
        object.monthdays = this.filters('monthdays').monthdays;
      }
      if (this.filters('yeardays') != null) {
        object.yeardays = this.filters('yeardays').yeardays;
      }
      if (this.filters('months') != null) {
        object.months = this.filters('months').months;
      }
      return object;
    };

    Rule.prototype.toJSON = function() {
      return JSON.stringify(this.toObject());
    };

    Rule.prototype.toString = function() {
      var dayNames, monthNames, strings;
      dayNames = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];
      monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
      strings = [];
      if (this.filters('months')) {
        strings.push(this.filters('months').toString());
      }
      if (this.filters('weekdays')) {
        strings.push(this.filters('weekdays').toString());
      }
      if (this.filters('monthdays')) {
        strings.push(this.filters('monthdays').toString());
      }
      if (this.filters('yeardays')) {
        strings.push(this.filters('yeardays').toString());
      }
      if (this.count()) {
        strings.push("end after " + (this.count()) + " times");
      }
      if (this.stop()) {
        strings.push("until " + monthNames[this.stop().getMonth()] + " " + (this.stop().getDate()) + ", " + (this.stop().getFullYear()));
      }
      return strings.join(", ");
    };

    Rule.prototype._potentialNext = function(current, base) {
      var fNext, filter;
      fNext = (function() {
        var _i, _len, _ref, _results;
        _ref = this.filters();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          filter = _ref[_i];
          _results.push(filter.next(current));
        }
        return _results;
      }).call(this);
      if (fNext.length > 0) {
        return new Date(Math.max.apply(Math, fNext));
      } else {
        return current;
      }
    };

    Rule.prototype._potentialPrevious = function(current, base) {
      var fNext, filter;
      fNext = (function() {
        var _i, _len, _ref, _results;
        _ref = this.filters();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          filter = _ref[_i];
          _results.push(filter.previous(current));
        }
        return _results;
      }).call(this);
      if (fNext.length > 0) {
        return new Date(Math.max.apply(Math, fNext));
      } else {
        return current;
      }
    };

    Rule.prototype._align = function(time, base) {
      throw "" + (typeof this) + ".align should be overriden and return a time in the period of time parameter, aligned to base";
    };

    Rule.prototype._minStep = function() {
      var filter, i, steps, _i, _ref;
      if (this.__minStep != null) {
        return this.__minStep;
      }
      steps = (function() {
        var _i, _len, _ref, _results;
        _ref = this.filters();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          filter = _ref[_i];
          _results.push(filter.step());
        }
        return _results;
      }).call(this);
      steps.push(this.step());
      this.__minStep = steps[0];
      for (i = _i = 1, _ref = steps.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
        if (steps[i].seconds < this.__minStep.seconds) {
          this.__minStep = steps[i];
        }
      }
      return this.__minStep;
    };

    return Rule;

  })();

  Schedule.Rule.daily = function(interval) {
    if (interval == null) {
      interval = 1;
    }
    return new Schedule.Rules.DailyRule(interval);
  };

  Schedule.Rule.yearly = function(interval) {
    if (interval == null) {
      interval = 1;
    }
    return new Schedule.Rules.YearlyRule(interval);
  };

  Schedule.Rule.weekly = function(interval) {
    if (interval == null) {
      interval = 1;
    }
    return new Schedule.Rules.WeeklyRule(interval);
  };

  Schedule.Rule.monthly = function(interval) {
    if (interval == null) {
      interval = 1;
    }
    return new Schedule.Rules.MonthlyRule(interval);
  };

  Schedule.Rule.fromObject = function(object) {
    var rule;
    if (!(object.freq && object.interval)) {
      throw "Bad object format";
    }
    rule = Schedule.Rule[object.freq](+object.interval);
    if (object.count != null) {
      rule.count(object.count);
    }
    if (object.stop != null) {
      rule.stop(object.stop);
    }
    if (object.weekdays != null) {
      rule.weekdays.apply(rule, object.weekdays);
    }
    if (object.monthdays != null) {
      rule.monthdays.apply(rule, object.monthdays);
    }
    if (object.yeardays != null) {
      rule.yeardays.apply(rule, object.yeardays);
    }
    if (object.months != null) {
      rule.months.apply(rule, object.months);
    }
    return rule;
  };

  Schedule.Rule.fromJSON = function(json) {
    var o;
    o = JSON.parse(json);
    if (o.stop) {
      o.stop = Date.parseISO8601(o.stop);
    }
    return Schedule.Rule.fromObject(o);
  };

}).call(this);

(function() {
  var _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Schedule.Rules.DailyRule = (function(_super) {
    __extends(DailyRule, _super);

    function DailyRule() {
      this._align = __bind(this._align, this);
      this._potential_previous = __bind(this._potential_previous, this);
      this._potentialNext = __bind(this._potentialNext, this);
      this.toString = __bind(this.toString, this);
      this.step = __bind(this.step, this);
      this.freq = __bind(this.freq, this);
      this.aligned = __bind(this.aligned, this);
      _ref = DailyRule.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    DailyRule.prototype.aligned = function(time, base) {
      var _ref1;
      _ref1 = [new Date(time), new Date(base)], time = _ref1[0], base = _ref1[1];
      if (((new Date(base)).at({
        hour: 0,
        minute: 0,
        second: 0
      }) - (new Date(time)).at({
        hour: 0,
        minute: 0,
        second: 0
      })) % this.interval !== 0) {
        return false;
      }
      if (!(time.getHours() === base.getHours() && time.getMinutes() === base.getMinutes() && time.getSeconds() === base.getSeconds())) {
        return false;
      }
      return true;
    };

    DailyRule.prototype.freq = function() {
      return 'daily';
    };

    DailyRule.prototype.step = function() {
      return {
        length: this.interval,
        unit: 'days',
        seconds: this.interval * 86400
      };
    };

    DailyRule.prototype.toString = function() {
      var string, sup;
      sup = DailyRule.__super__.toString.call(this);
      string = this.interval > 1 ? "Every " + this.interval + " days" : "Daily";
      if (sup) {
        string += ", " + sup;
      }
      return string;
    };

    DailyRule.prototype._potentialNext = function(current, base) {
      var candidate, rem;
      candidate = DailyRule.__super__._potentialNext.call(this, current, base);
      rem = ((new Date(base)).at({
        hour: 0,
        minute: 0,
        second: 0
      }) - (new Date(candidate)).at({
        hour: 0,
        minute: 0,
        second: 0
      })) % this.interval;
      if (rem === 0) {
        return candidate;
      }
      return (new Date(candidate)).add(rem).days().at({
        hour: 0,
        minute: 0,
        second: 0
      });
    };

    DailyRule.prototype._potential_previous = function(current, base) {
      var candidate, rem;
      candidate = DailyRule.__super__._potential_previous.call(this, current, base);
      rem = ((new Date(base)).at({
        hour: 0,
        minute: 0,
        second: 0
      }) - (new Date(candidate)).at({
        hour: 0,
        minute: 0,
        second: 0
      })) % this.interval;
      if (rem === 0) {
        return candidate;
      }
      return (new Date(candidate)).add(rem - this.interval).days().at({
        hour: 0,
        minute: 0
      });
    };

    DailyRule.prototype._align = function(time, base) {
      return time = (new Date(time)).at({
        hour: 0,
        minute: 0,
        second: 0
      }).add({
        hours: base.getHours(),
        minutes: base.getMinutes(),
        seconds: base.getSeconds()
      });
    };

    return DailyRule;

  })(Schedule.Rule);

}).call(this);

(function() {
  var _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Schedule.Rules.MonthlyRule = (function(_super) {
    __extends(MonthlyRule, _super);

    function MonthlyRule() {
      this._monthdayFilters = __bind(this._monthdayFilters, this);
      this._align = __bind(this._align, this);
      this._potentialPrevious = __bind(this._potentialPrevious, this);
      this._potentialNext = __bind(this._potentialNext, this);
      this.toString = __bind(this.toString, this);
      this.step = __bind(this.step, this);
      this.freq = __bind(this.freq, this);
      this.aligned = __bind(this.aligned, this);
      _ref = MonthlyRule.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    MonthlyRule.prototype.aligned = function(time, base) {
      if (((12 * base.getFullYear() + base.getMonth()) - (12 * time.getFullYear() + time.getMonth())) % this.interval !== 0) {
        return false;
      }
      if (!(time.getHours() === base.getHours() && time.getMinutes() === base.getMinutes() && time.getSeconds() === base.getSeconds())) {
        return false;
      }
      if (!(base.getDate() === time.getDate() || this._monthdayFilters())) {
        return false;
      }
      return true;
    };

    MonthlyRule.prototype.freq = function() {
      return 'monthly';
    };

    MonthlyRule.prototype.step = function() {
      return {
        length: this.interval,
        unit: 'months',
        seconds: this.interval * 2592000
      };
    };

    MonthlyRule.prototype.toString = function() {
      var string, sup;
      sup = MonthlyRule.__super__.toString.call(this);
      string = this.interval > 1 ? "Every " + this.interval + " months" : "Every month";
      if (sup) {
        string += ", " + sup;
      }
      return string;
    };

    MonthlyRule.prototype._potentialNext = function(current, base) {
      var candidate, rem;
      candidate = MonthlyRule.__super__._potentialNext.call(this, current, base);
      rem = ((12 * base.getFullYear() + base.getMonth()) - (12 * candidate.getFullYear() + candidate.getMonth())) % this.interval;
      if (rem === 0) {
        return candidate;
      }
      if (rem < 0) {
        rem += this.interval;
      }
      return (new Date(candidate)).add(rem).months().set({
        day: 1
      }).at({
        hour: 0,
        minute: 0,
        second: 0
      });
    };

    MonthlyRule.prototype._potentialPrevious = function(current, base) {
      var candidate, rem;
      candidate = MonthlyRule.__super__._potentialPrevious.call(this, current, base);
      rem = ((12 * base.getFullYear() + base.getMonth()) - (12 * candidate.getFullYear() + candidate.getMonth())) % this.interval;
      if (rem === 0) {
        return candidate;
      }
      if (rem < 0) {
        rem += this.interval;
      }
      return (new Date(candidate)).add(rem - this.interval + 1).months().set({
        day: 1
      }).add(-1).day().at({
        hour: 0,
        minute: 0,
        second: 0
      });
    };

    MonthlyRule.prototype._align = function(time, base) {
      if (!(time.getDate() === base.getDate() || this._monthdayFilters())) {
        time = (new Date(time)).set({
          day: 1
        }).add(base.getDate() - 1).days();
      }
      return time = time.at({
        hour: 0,
        minute: 0,
        second: 0
      }).add({
        hours: base.getHours(),
        minutes: base.getMinutes(),
        seconds: base.getSeconds()
      });
    };

    MonthlyRule.prototype._monthdayFilters = function() {
      return (this.filters('weekdays') != null) || (this.filters('monthdays') != null) || (this.filters('yeardays') != null) || (this.filters('weeks') != null) || (this.filters('months') != null);
    };

    return MonthlyRule;

  })(Schedule.Rule);

}).call(this);

(function() {
  var _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Schedule.Rules.WeeklyRule = (function(_super) {
    __extends(WeeklyRule, _super);

    function WeeklyRule() {
      this._weekdayFilters = __bind(this._weekdayFilters, this);
      this._align = __bind(this._align, this);
      this._potentialPrevious = __bind(this._potentialPrevious, this);
      this._potentialNext = __bind(this._potentialNext, this);
      this.toString = __bind(this.toString, this);
      this.step = __bind(this.step, this);
      this.freq = __bind(this.freq, this);
      this.aligned = __bind(this.aligned, this);
      _ref = WeeklyRule.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    WeeklyRule.prototype.aligned = function(time, base) {
      var base_mm, time_mm;
      base_mm = (new Date(base)).add(-base.getDay()).days().at({
        hour: 0,
        minute: 0,
        second: 0
      });
      time_mm = (new Date(time)).add(-time.getDay()).days().at({
        hour: 0,
        minute: 0,
        second: 0
      });
      if ((~~((base_mm - time_mm) / 604800000) % this.interval) !== 0) {
        return false;
      }
      if (!(time.getHours() === base.getHours() && time.getMinutes() === base.getMinutes() && time.getSeconds() === base.getSeconds())) {
        return false;
      }
      if (!(base.getDay() === time.getDay() || this._weekdayFilters())) {
        return false;
      }
      return true;
    };

    WeeklyRule.prototype.freq = function() {
      return 'weekly';
    };

    WeeklyRule.prototype.step = function() {
      return {
        length: this.interval,
        unit: 'weeks',
        seconds: this.interval * 604800000
      };
    };

    WeeklyRule.prototype.toString = function() {
      var string, sup;
      sup = WeeklyRule.__super__.toString.call(this);
      string = this.interval > 1 ? "Every " + this.interval + " weeks" : "Weekly";
      if (sup) {
        string += ", " + sup;
      }
      return string;
    };

    WeeklyRule.prototype._potentialNext = function(current, base) {
      var base_mm, candidate, candidate_mm, next, rem;
      candidate = WeeklyRule.__super__._potentialNext.call(this, current, base);
      base_mm = (new Date(base)).add(-base.getDay()).days().at({
        hour: 0,
        minute: 0,
        second: 0
      });
      candidate_mm = (new Date(candidate)).add(-candidate.getDay()).days().at({
        hour: 0,
        minute: 0,
        second: 0
      });
      rem = (~~((base_mm - candidate_mm) / 604800000)) % this.interval;
      if (rem === 0) {
        return candidate;
      }
      if (rem < 0) {
        rem += this.interval;
      }
      next = new Date(candidate).add(rem).weeks();
      return next.add(-next.getDay()).days().at({
        hour: 0,
        minute: 0,
        second: 0
      });
    };

    WeeklyRule.prototype._potentialPrevious = function(current, base) {
      var base_mm, candidate, candidate_mm, next, rem;
      candidate = WeeklyRule.__super__._potentialPrevious.call(this, current, base);
      base_mm = (new Date(base)).add(-base.getDay()).days().at({
        hour: 0,
        minute: 0,
        second: 0
      });
      candidate_mm = (new Date(candidate)).add(-candidate.getDay()).days().at({
        hour: 0,
        minute: 0,
        second: 0
      });
      rem = (~~((base_mm - candidate_mm) / 604800000)) % this.interval;
      if (rem === 0) {
        return candidate;
      }
      if (rem < 0) {
        rem += this.interval;
      }
      next = (new Date(candidate)).add(rem).weeks().add(-this.interval).weeks();
      return next.add(-next.getDay()).days().at({
        hour: 0,
        minute: 0,
        second: 0
      }).add(1).week().add(-1).second();
    };

    WeeklyRule.prototype._align = function(time, base) {
      if (!(time.getDay() === base.getDay() || this._weekdayFilters())) {
        time = (new Date(time)).add(-time.getDay()).days().at({
          hour: 0,
          minute: 0,
          second: 0
        }).add(base.getDay()).days();
      }
      return time = (new Date(time)).at({
        hour: 0,
        minute: 0,
        second: 0
      }).add({
        hours: base.getHours(),
        minutes: base.getMinutes(),
        seconds: base.getSeconds()
      });
    };

    WeeklyRule.prototype._weekdayFilters = function() {
      return (this.filters('weekdays') != null) || (this.filters('monthdays') != null) || (this.filters('yeardays') != null) || (this.filters('yeardays') != null) || (this.filters('weeks') != null) || (this.filters('months') != null);
    };

    return WeeklyRule;

  })(Schedule.Rule);

}).call(this);

(function() {
  var _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Schedule.Rules.YearlyRule = (function(_super) {
    __extends(YearlyRule, _super);

    function YearlyRule() {
      this._monthFilters = __bind(this._monthFilters, this);
      this._dayFilters = __bind(this._dayFilters, this);
      this._align = __bind(this._align, this);
      this._potentialPrevious = __bind(this._potentialPrevious, this);
      this._potentialNext = __bind(this._potentialNext, this);
      this.toString = __bind(this.toString, this);
      this.freq = __bind(this.freq, this);
      this.aligned = __bind(this.aligned, this);
      _ref = YearlyRule.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    YearlyRule.prototype.aligned = function(time, base) {
      if ((base.getFullYear() - time.getFullYear()) % this.interval !== 0) {
        return false;
      }
      if (!(time.getHours() === base.getHours() && time.getMinutes() === base.getMinutes() && time.getSeconds() === base.getSeconds())) {
        return false;
      }
      if (!(time.getDate() === base.getDate() || this._dayFilters())) {
        return false;
      }
      if (!(time.getMonth() === base.getMonth() || this._monthFilters())) {
        return false;
      }
      return true;
    };

    YearlyRule.prototype.freq = function() {
      return 'yearly';
    };

    YearlyRule.prototype.step = function() {
      return {
        length: this.interval,
        unit: 'years',
        seconds: this.interval * 31536000
      };
    };

    YearlyRule.prototype.toString = function() {
      var string, sup;
      sup = YearlyRule.__super__.toString.call(this);
      string = this.interval > 1 ? "Every " + this.interval + " years" : "Every year";
      if (sup) {
        string += ", " + sup;
      }
      return string;
    };

    YearlyRule.prototype._potentialNext = function(current, base) {
      var candidate, years;
      candidate = YearlyRule.__super__._potentialNext.call(this, current, base);
      if ((base.getFullYear() - candidate.getFullYear()) % this.interval === 0) {
        return candidate;
      }
      years = (base.getFullYear() - candidate.getFullYear()) % this.interval;
      if (years < 0) {
        years += this.interval;
      }
      return (new Date(candidate)).add(years).years().set({
        month: 0,
        day: 1
      });
    };

    YearlyRule.prototype._potentialPrevious = function(current, base) {
      var candidate, years;
      candidate = YearlyRule.__super__._potentialPrevious.call(this, current, base);
      if ((base.getFullYear() - candidate.getFullYear()) % this.interval === 0) {
        return candidate;
      }
      years = (base.getFullYear() - candidate.getFullYear()) % this.interval;
      if (years < 0) {
        years += this.interval;
      }
      return (new Date(candidate)).add(years - this.interval).years().set({
        month: 0,
        day: 1
      });
    };

    YearlyRule.prototype._align = function(time, base) {
      var day, mon;
      day = (this._dayFilters() ? time.getDate() : base.getDate());
      mon = (this._monthFilters() ? time.getMonth() : base.getMonth());
      time = (new Date(time)).set({
        month: 0,
        day: 1
      }).add(mon).months().add(day - 1).days();
      return time.at({
        hour: 0,
        minute: 0,
        second: 0
      }).add({
        hours: base.getHours(),
        minutes: base.getMinutes(),
        seconds: base.getSeconds()
      });
    };

    YearlyRule.prototype._dayFilters = function() {
      return (this.filters('weekdays') != null) || (this.filters('monthdays') != null) || (this.filters('yeardays') != null);
    };

    YearlyRule.prototype._monthFilters = function() {
      return (this.filters('weekdays') != null) || (this.filters('yeardays') != null) || (this.filters('weeks') != null) || (this.filters('months') != null);
    };

    return YearlyRule;

  })(Schedule.Rule);

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  Schedule.Filters.MonthdaysFilter = (function() {
    function MonthdaysFilter() {
      var monthdays;
      monthdays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.toString = __bind(this.toString, this);
      this.previous = __bind(this.previous, this);
      this.next = __bind(this.next, this);
      this.step = __bind(this.step, this);
      this.match = __bind(this.match, this);
      if (monthdays.length < 1) {
        throw "Specify at least one day of the month";
      }
      this.monthdays = monthdays.sort(function(a, b) {
        return a - b;
      });
    }

    MonthdaysFilter.prototype.match = function(date) {
      var last;
      last = (new Date(date)).add(1).month().set({
        day: 1
      }).add(-1).day().getDate();
      return this.monthdays.indexOf(date.getDate()) >= 0 || this.monthdays.indexOf(date.getDate() - last - 1) >= 0;
    };

    MonthdaysFilter.prototype.step = function() {
      return {
        length: 1,
        unit: 'day',
        seconds: 86400
      };
    };

    MonthdaysFilter.prototype.next = function(date) {
      date = new Date(date);
      while (!this.match(date)) {
        date.add(1).day();
      }
      return date;
    };

    MonthdaysFilter.prototype.previous = function(date) {
      date = new Date(date);
      while (!this.match(date)) {
        date.add(-1).day();
      }
      return date;
    };

    MonthdaysFilter.prototype.toString = function() {
      var days, last;
      days = _.map(this.monthdays, function(d) {
        return "" + d + ".";
      });
      last = days.pop();
      if (days.length > 0) {
        return "on " + (days.join(", ")) + " and " + last + " day";
      } else {
        return "on " + last + " day";
      }
    };

    return MonthdaysFilter;

  })();

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  Schedule.Filters.MonthsFilter = (function() {
    MonthsFilter.prototype.MONTH_NAMES = {
      jan: 1,
      january: 1,
      feb: 2,
      february: 2,
      mar: 3,
      march: 3,
      apr: 4,
      april: 4,
      may: 5,
      jun: 6,
      june: 6,
      jul: 7,
      july: 7,
      aug: 8,
      august: 8,
      sep: 9,
      sept: 9,
      september: 9,
      oct: 10,
      october: 10,
      nov: 11,
      november: 11,
      dec: 12,
      december: 12
    };

    function MonthsFilter() {
      var month, months;
      months = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.toString = __bind(this.toString, this);
      this.previous = __bind(this.previous, this);
      this.next = __bind(this.next, this);
      this.match = __bind(this.match, this);
      if (months.length < 1) {
        throw "Specify at least one month";
      }
      this.months = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = months.length; _i < _len; _i++) {
          month = months[_i];
          _results.push(!isNaN(parseFloat(month)) ? month : this.MONTH_NAMES[month]);
        }
        return _results;
      }).call(this);
      this.months = this.months.sort();
    }

    MonthsFilter.prototype.match = function(date) {
      return this.months.indexOf(date.getMonth() + 1) >= 0;
    };

    MonthsFilter.prototype.step = function() {
      return {
        length: 1,
        unit: 'month',
        seconds: 2592000
      };
    };

    MonthsFilter.prototype.next = function(date) {
      var d, m, month, _i, _len, _ref;
      if (this.match(date)) {
        return date;
      }
      month = null;
      _ref = this.months;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        m = _ref[_i];
        if (m > date.getMonth() + 1) {
          month = m;
        }
      }
      if (month != null) {
        return (new Date(date)).set({
          month: 0,
          day: 1
        }).add(month - 1).months().at({
          hour: date.getHours(),
          minute: date.getMinutes(),
          second: date.getSeconds()
        });
      } else {
        d = (new Date(date)).set({
          month: 0,
          day: 1
        }).add(1).year().add(this.months[0] - 1).months();
        return d.at({
          hour: date.getHours(),
          minute: date.getMinutes(),
          second: date.getSeconds()
        });
      }
    };

    MonthsFilter.prototype.previous = function(date) {
      var d, m, month, _i, _len, _ref;
      if (match(date)) {
        return date;
      }
      month = null;
      _ref = this.months.reverse();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        m = _ref[_i];
        if (m < date.getMonth() + 1) {
          month = m;
        }
      }
      if (month != null) {
        d = (new Date(date)).set({
          month: 0,
          day: 1
        }).add(month).months().add(-1).day();
        return d.at({
          hour: date.getHours(),
          minute: date.getMinutes(),
          second: date.getSeconds()
        });
      } else {
        d = (new Date(date)).set({
          month: 0,
          day: 1
        }).add(-1).year().add(this.months.last).months().add(-1).day();
        return d.at({
          hour: date.getHours(),
          minute: date.getMinutes(),
          second: date.getSeconds()
        });
      }
    };

    MonthsFilter.prototype.toString = function() {
      var last, monthNames, months;
      monthNames = [null, "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
      months = _.map(this.months, function(m) {
        return monthNames[m];
      });
      last = months.pop();
      if (months.length > 0) {
        return "in " + (months.join(", ")) + " and " + last;
      } else {
        return "in " + last;
      }
    };

    return MonthsFilter;

  })();

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  Schedule.Filters.WeekdaysFilter = (function() {
    WeekdaysFilter.prototype.WEEKDAYS = {
      su: 0,
      sun: 0,
      sunday: 0,
      mo: 1,
      mon: 1,
      monday: 1,
      tu: 2,
      tue: 2,
      tuesday: 2,
      we: 3,
      wed: 3,
      wednesday: 3,
      th: 4,
      thu: 4,
      thursday: 4,
      fr: 5,
      fri: 5,
      friday: 5,
      sa: 6,
      sat: 6,
      saturday: 6
    };

    WeekdaysFilter.prototype.WEEKDAY_NAMES = ['su', 'mo', 'tu', 'we', 'th', 'fr', 'sa'];

    function WeekdaysFilter() {
      var day, orders, w, weekdays, _ref;
      weekdays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.toString = __bind(this.toString, this);
      this._orderInInterval = __bind(this._orderInInterval, this);
      this.previous = __bind(this.previous, this);
      this.next = __bind(this.next, this);
      this.step = __bind(this.step, this);
      this.match = __bind(this.match, this);
      if (weekdays[0] instanceof Schedule.Rule) {
        this.rule = weekdays.shift();
      }
      if (weekdays.length < 1) {
        throw "Specify at least one weekday";
      }
      this.orderedWeekdays = {};
      if (weekdays[weekdays.length - 1] instanceof Object) {
        if (this.rule == null) {
          throw "No recurrence rule given for ordered weekdays filter";
        }
        _ref = weekdays[weekdays.length - 1];
        for (day in _ref) {
          orders = _ref[day];
          day = !isNaN(parseFloat(day)) ? day : this.WEEKDAYS[day];
          if (orders.length == null) {
            orders = [orders];
          }
          this.orderedWeekdays[this.WEEKDAY_NAMES[day]] = orders.sort();
        }
        weekdays = weekdays.slice(0, -1);
      }
      this.weekdays = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = weekdays.length; _i < _len; _i++) {
          w = weekdays[_i];
          _results.push(!isNaN(parseFloat(w)) ? w : this.WEEKDAYS[w]);
        }
        return _results;
      }).call(this);
      this.weekdays.sort();
    }

    WeekdaysFilter.prototype.match = function(date) {
      var day, first, max, occ, _ref;
      if (this.weekdays.indexOf(date.getDay()) >= 0) {
        return true;
      }
      day = this.WEEKDAY_NAMES[date.getDay()];
      if (this.orderedWeekdays[day] == null) {
        return false;
      }
      _ref = this._orderInInterval(date), first = _ref[0], occ = _ref[1], max = _ref[2];
      return this.orderedWeekdays[day].indexOf(occ) >= 0 || this.orderedWeekdays[day].indexOf(occ - max - 1) >= 0;
    };

    WeekdaysFilter.prototype.step = function() {
      return {
        length: 1,
        unit: 'day',
        seconds: 846000
      };
    };

    WeekdaysFilter.prototype.next = function(date) {
      var MAX_ITERATIONS;
      date = new Date(date);
      MAX_ITERATIONS = 10000;
      while (!this.match(date)) {
        if (!(MAX_ITERATIONS-- > 0)) {
          throw "Maximum iterations reached in WeekdaysFilter.next";
        }
        date.add(1).day();
      }
      return date;
    };

    WeekdaysFilter.prototype.previous = function(date) {
      var MAX_ITERATIONS;
      date = new Date(date);
      MAX_ITERATIONS = 10000;
      while (!this.match(date)) {
        if (!(MAX_ITERATIONS-- > 0)) {
          throw "Maximum iterations reached in WeekdaysFilter.previous";
        }
        date.add(-1).day();
      }
      return date;
    };

    WeekdaysFilter.prototype._orderInInterval = function(date) {
      var eoy, eyday, first, janfirst, max, occ, yday;
      janfirst = (new Date(date)).set({
        month: 0,
        day: 1
      });
      if (this.rule instanceof Schedule.Rules.YearlyRule) {
        first = (7 + date.getDay() - janfirst.getDay()) % 7 + 1;
        yday = Math.ceil((date - janfirst) / 1000 / 60 / 60 / 24) + 1;
        occ = ~~((yday - first) / 7) + 1;
        eoy = (new Date(date)).add(1).year().set({
          month: 0,
          day: 1
        }).add(-1).day();
        eyday = Math.ceil((eoy - janfirst) / 1000 / 60 / 60 / 24) + 1;
        max = ~~((eyday - first) / 7) + 1;
      } else if (this.rule instanceof Schedule.Rules.MonthlyRule) {
        first = (7 + date.getDay() - (new Date(date)).set({
          day: 1
        }).getDay()) % 7 + 1;
        occ = ~~((date.getDate() - first) / 7) + 1;
        max = ~~(((new Date(date)).add(1).month().set({
          day: 1
        }).add(-1).day().getDate() - first) / 7) + 1;
      } else {
        throw "Ordered weekdays filter only supports monthy and yearly rules. (" + this.rule["class"] + " given)";
      }
      return [first, occ, max];
    };

    WeekdaysFilter.prototype.toString = function() {
      var dayNames, days, last, owdays, wdays,
        _this = this;
      dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];
      wdays = _.map(this.weekdays, function(w) {
        return dayNames[w];
      });
      owdays = _.map(this.orderedWeekdays, function(ord, d) {
        return "" + (_.map(ord, function(o) {
          return "" + o + ".";
        }).join(", ")) + " " + dayNames[_this.WEEKDAYS[d]];
      });
      days = wdays.concat(owdays);
      last = days.pop();
      if (days.length > 0) {
        return "on " + (days.join(", ")) + " and " + last;
      } else {
        return "on " + last;
      }
    };

    return WeekdaysFilter;

  })();

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  Schedule.Filters.YeardaysFilter = (function() {
    function YeardaysFilter() {
      var yeardays;
      yeardays = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.toString = __bind(this.toString, this);
      this.yearDay = __bind(this.yearDay, this);
      this.previous = __bind(this.previous, this);
      this.next = __bind(this.next, this);
      this.step = __bind(this.step, this);
      this.match = __bind(this.match, this);
      if (yeardays.length < 1) {
        throw "Specify at least one day of the month";
      }
      this.yeardays = yeardays.sort();
    }

    YeardaysFilter.prototype.match = function(date) {
      var eoy, last;
      eoy = (new Date(date)).set({
        month: 0,
        day: 1
      }).add(1).year().add(-1).day();
      last = this.yearDay(eoy);
      return (this.yeardays.indexOf(this.yearDay(date)) >= 0) || (this.yeardays.indexOf(this.yearDay(date) - last - 1) >= 0);
    };

    YeardaysFilter.prototype.step = function() {
      return {
        length: 1,
        unit: 'day',
        seconds: 86400
      };
    };

    YeardaysFilter.prototype.next = function(date) {
      date = new Date(date);
      while (!this.match(date)) {
        date.add(1).day();
      }
      return date;
    };

    YeardaysFilter.prototype.previous = function(date) {
      date = new Date(date);
      while (!this.match(date)) {
        date.add(-1).day();
      }
      return date;
    };

    YeardaysFilter.prototype.yearDay = function(date) {
      var janFirst;
      date = new Date(date);
      janFirst = (new Date(date)).set({
        month: 0,
        day: 1
      });
      return Math.ceil((date - janFirst) / 86400000) + 1;
    };

    YeardaysFilter.prototype.toString = function() {
      var days, last;
      days = _.map(this.yeardays, function(d) {
        return "" + d + ".";
      });
      last = days.pop();
      if (days.length > 0) {
        return "on " + (days.join(", ")) + " and " + last + " day";
      } else {
        return "on " + last + " day";
      }
    };

    return YeardaysFilter;

  })();

}).call(this);

(function() {
  Schedule.Suboccurrence = (function() {
    function Suboccurrence(attrs) {
      this.start = attrs.start;
      this.end = attrs.end;
      this.isOccurrenceStart = attrs.isOccurrenceStart;
      this.isOccurrenceEnd = attrs.isOccurrenceEnd;
    }

    return Suboccurrence;

  })();

  Schedule.Suboccurrence.find = function(attrs) {
    var interval, occurrence, suboccurrence;
    if ((occurrence = attrs.occurrence).length == null) {
      throw "Missing occurrence";
    }
    if ((interval = attrs.interval).length == null) {
      throw "Missing interval";
    }
    if (occurrence[1] <= interval[0] || occurrence[0] >= interval[2]) {
      return null;
    }
    suboccurrence = {};
    if (occurrence[0] < interval[0]) {
      suboccurrence.start = interval[0];
      suboccurrence.isOccurrenceStart = false;
    } else {
      suboccurrence.start = occurrence[0];
      suboccurrence.isOccurrenceStart = true;
    }
    if (occurrence[1] > interval[1]) {
      suboccurrence.end = interval[1];
      suboccurrence.isOccurrenceEnd = false;
    } else {
      suboccurrence.end = occurrence[1];
      suboccurrence.isOccurrenceEnd = true;
    }
    return new Schedule.Suboccurrence(suboccurrence);
  };

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Schedule.Occurrence = (function() {
    function Occurrence(rule, startTime) {
      this._initLoop = __bind(this._initLoop, this);
      this._listOccurrences = __bind(this._listOccurrences, this);
      this.toObject = __bind(this.toObject, this);
      this.all = __bind(this.all, this);
      this.suboccurrencesBetween = __bind(this.suboccurrencesBetween, this);
      this.occurrencesBetween = __bind(this.occurrencesBetween, this);
      this.previousOccurrences = __bind(this.previousOccurrences, this);
      this.previousOccurrence = __bind(this.previousOccurrence, this);
      this.nextOccurrences = __bind(this.nextOccurrences, this);
      this.nextOccurrence = __bind(this.nextOccurrence, this);
      this.rule = rule;
      this.startTime = this.rule.match(startTime, startTime) ? startTime : this.rule.next(startTime, startTime);
    }

    Occurrence.prototype.nextOccurrence = function(after) {
      return this.nextOccurrences(1, after)[0];
    };

    Occurrence.prototype.nextOccurrences = function(n, after) {
      var time;
      if ((this.rule.stop() != null) && after > this.rule.stop()) {
        return [];
      }
      time = (after <= this.startTime ? this.startTime : after);
      if (!this.rule.match(time, this.startTime)) {
        time = this.rule.next(time, this.startTime);
      }
      return this._listOccurrences(time, function() {
        return (n -= 1) >= 0;
      });
    };

    Occurrence.prototype.previousOccurrence = function(before) {
      return this.previousOccurrences(1, before)[0];
    };

    Occurrence.prototype.previousOccurrences = function(n, before) {
      var time;
      if (before <= this.startTime) {
        return [];
      }
      time = ((this.rule.stop() == null) || before < this.rule.stop() ? before : this.rule.stop());
      time = this.rule.previous(time, this.startTime);
      return this._listOccurrences(time, 'back', function() {
        return (n -= 1) >= 0;
      }).reverse();
    };

    Occurrence.prototype.occurrencesBetween = function(t1, t2) {
      var time;
      if (!(t2 > t1)) {
        throw "Empty time interval";
      }
      if (t2 <= this.startTime || (this.rule.stop() != null) && t1 >= this.rule.stop()) {
        return [];
      }
      time = (t1 <= this.startTime ? this.startTime : t1);
      if (!this.rule.match(time, this.startTime)) {
        time = this.rule.next(time, this.startTime);
      }
      return this._listOccurrences(time, function(t) {
        return t < t2;
      });
    };

    Occurrence.prototype.suboccurrencesBetween = function(t1, t2) {
      var occ, occurrences, _i, _len, _results;
      occurrences = this.occurrencesBetween(new Date(t1 - this.duration), t2);
      _results = [];
      for (_i = 0, _len = occurrences.length; _i < _len; _i++) {
        occ = occurrences[_i];
        _results.push(Schedule.Suboccurrence.find({
          occurrence: [occ, new Date(+occ + this.duration)],
          interval: [t1, t2]
        }));
      }
      return _results;
    };

    Occurrence.prototype.all = function() {
      var n, rule;
      if (this.rule.stop() != null) {
        rule = this.rule;
        return this._listOccurrences(this.startTime, function(t) {
          return t < rule.stop();
        });
      } else {
        n = this.rule.count();
        return this._listOccurrences(this.startTime, function() {
          return (n -= 1) >= 0;
        });
      }
    };

    Occurrence.prototype.toObject = function() {
      return this.rule.toObject();
    };

    Occurrence.prototype._listOccurrences = function(from, direction_or_func, func) {
      var MAX_ITERATIONS, current, direction, n, results, _ref;
      if (!this.rule.match(from, this.startTime)) {
        throw "From " + from + " not matching the rule " + this.rule + " and start time " + this.startTime;
      }
      if (func != null) {
        direction = direction_or_func;
      } else {
        direction = 'forward';
        func = direction_or_func;
      }
      results = [];
      _ref = this._initLoop(from, direction), n = _ref[0], current = _ref[1];
      MAX_ITERATIONS = 10000;
      while (true) {
        if (!(MAX_ITERATIONS-- > 0)) {
          throw "Maximum iterations reached when listing occurrences...";
        }
        if (!((current >= this.startTime) && ((this.rule.stop() == null) || current < this.rule.stop()) && ((this.rule.count() == null) || (n -= 1) >= 0))) {
          return results;
        }
        if (!func(current)) {
          return results;
        }
        results.push(current);
        if (direction === 'forward') {
          current = this.rule.next(current, this.startTime);
        } else {
          current = this.rule.previous(current, this.startTime);
        }
      }
    };

    Occurrence.prototype._initLoop = function(from, direction) {
      var current, n;
      if (this.rule.count() == null) {
        return [0, from];
      }
      if (direction === 'forward') {
        n = 0;
        current = this.startTime;
        while (current < from) {
          n += 1;
          current = this.rule.next(current, this.startTime);
        }
        return [this.rule.count() - n, current];
      } else {
        n = 0;
        current = this.startTime;
        while (current < from && (n += 1) < this.rule.count()) {
          current = this.rule.next(current, this.startTime);
        }
        return [this.rule.count(), current];
      }
    };

    return Occurrence;

  })();

}).call(this);
