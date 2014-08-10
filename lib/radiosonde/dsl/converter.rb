class Radiosonde::DSL::Converter
  class << self
    def convert(exported, opts = {})
      self.new(exported, opts).convert
    end
  end # of class methods

  def initialize(exported, options = {})
    @exported = exported
    @options = options
  end

  def convert
    @exported.each.map {|alarm_name, alarm_attrs|
      output_alarm(alarm_name, alarm_attrs)
    }.join("\n")
  end

  private

  def output_alarm(name, attrs)
    name = name.inspect
    description = attrs[:description].inspect
    namespace = attrs[:namespace].inspect
    metric_name = attrs[:metric_name].inspect
    dimensions = format_dimensions(attrs)
    period = attrs[:period].inspect
    statistic =  Radiosonde::DSL::Statistic.normalize(attrs[:statistic]).inspect
    threshold = format_threshold(attrs)
    actions_enabled = attrs[:actions_enabled].inspect
    alarm_actions = attrs[:alarm_actions].inspect
    ok_actions = attrs[:ok_actions].inspect
    insufficient_data_actions = attrs[:insufficient_data_actions].inspect

    <<-EOS
alarm #{name} do
  description #{description}
  namespace #{namespace}
  metric_name #{metric_name}
  dimensions #{dimensions}
  period #{period}
  statistic #{statistic}
  threshold #{threshold}
  actions_enabled #{actions_enabled}
  alarm_actions #{alarm_actions}
  ok_actions #{ok_actions}
  insufficient_data_actions #{insufficient_data_actions}
end
    EOS
  end

  def format_dimensions(attrs)
    dimensions = attrs[:dimensions]
    names = dimensions.map {|i| i[:name] }

    if duplicated?(names)
      dimensions.inspect
    else
      dimension_hash = {}

      dimensions.each do |dimension|
        name = dimension[:name]
        value = dimension[:value]
        dimension_hash[name] = value
      end

      unbrace(dimension_hash.inspect)
    end
  end

  def format_threshold(attrs)
    threshold = attrs[:threshold]
    operator = attrs[:comparison_operator]
    operator = Radiosonde::DSL::ComparisonOperator.normalize(operator)

    [
      operator.inspect,
      threshold.inspect,
    ].join(', ')
  end

  def output_actions(attrs, opts = {})
    prefix = opts[:prefix]
    enabled = attrs[:actions_enabled].inspect
    alarm_actions = attrs[:alarm_actions].inspect
    ok_actions = attrs[:ok_actions].inspect
    insufficient_data_actions = attrs[:insufficient_data_actions].inspect

    [
      'actions {',
      "  :enabled => #{enabled},",
      "  :alarm => #{alarm_actions},",
      "  :ok => #{ok_actions},",
      "  :insufficient => #{insufficient_data_actions},",
      '}',
    ].join("\n#{prefix}")
  end

  private

  def unbrace(str)
    str.sub(/\A\s*\{/, '').sub(/\}\s*\z/, '')
  end

  def duplicated?(list)
    list.length != list.uniq.length
  end
end
