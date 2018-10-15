require 'elasticquerybuilder/version'

module ElasticQueryBuilder
  class Engine
    attr_reader :criteria
    def initialize
      @criteria = { query: {} }
      @keyword = ''
    end

    # opts = [{field,value,operation},{field,value,operation}]
    def must
      @keyword = 'must'
      self
    end

    def term(opts)
      term = {}
      prev = @keyword.to_sym
      if @criteria[:query].include? :bool
        @criteria[:query][:bool][prev] = [] unless @criteria[:query][:bool].include? prev
        bool_query = true
      else
        bool_query = false
        @criteria[:query] = []
      end
      opts.each do |option, _value|
        val = option[:value]
        term[option[:field]] = val
      end
      if bool_query
        @criteria[:query][:bool][prev].push(term: term)
      else
        if opts.count > 1
          @criteria[:query].push(term: term)
        else
          @criteria[:query] = { term: {} }
          @criteria[:query][:term] = term
        end
      end
      self
    end

    def terms(opts)
      term = {}
      prev = @keyword.to_sym
      if @criteria[:query].include? :bool
        @criteria[:query][:bool][prev] = [] unless @criteria[:query][:bool].include? prev
        bool_query = true
      else
        bool_query = false
        @criteria[:query] = []
      end
      opts.each do |option, _value|
        val = handle_operation('in', option[:value])
        term[option[:field]] = val
      end
      if bool_query
        @criteria[:query][:bool][prev].push(terms: term)
      else
        if opts.count > 1
          @criteria[:query].push(terms: term)
        else
          @criteria[:query] = { terms: {} }
          @criteria[:query][:terms] = term
        end
      end
      self
    end

    def wildcard(opts)
      wildcard = {}
      prev = @keyword.to_sym
      if @criteria[:query].include? :bool
        @criteria[:query][:bool][prev] = [] unless @criteria[:query][:bool].include? prev
        bool_query = true
      else
        bool_query = false
        @criteria[:query] = []
      end
      opts.each do |option, _value|
        val = if !option.include? :operation
                option[:value]
              else
                handle_operation(option[:operation], option[:value])
              end
        wildcard[option[:field]] = val
      end
      if bool_query
        @criteria[:query][:bool][prev].push(wildcard: wildcard)
      else
        if opts.count > 1
          @criteria[:query].push(wildcard: wildcard)
        else
          @criteria[:query] = { wildcard: {} }
          @criteria[:query][:wildcard] = wildcard
        end
      end
      self
    end

    def match_on_single_field(opts)
      match = {}
      prev = @keyword.to_sym
      if @criteria[:query].include? :bool
        @criteria[:query][:bool][prev] = [] unless @criteria[:query][:bool].include? prev
        bool_query = true
      else
        bool_query = false
        @criteria[:query] = []
      end
      opts.each do |option, _value|
        val = if !option.include? :operation
                option[:value]
              else
                handle_operation(option[:operation], option[:value])
              end
        match[option[:field]] = val
      end
      if bool_query
        @criteria[:query][:bool][prev].push(match: match)
      else
        if opts.count > 1
          @criteria[:query].push(match: match)
        else
          @criteria[:query] = { match: {} }
          @criteria[:query][:match] = match
        end
      end
      self
    end

    def should
      @keyword = 'should'
      self
    end

    def bool
      @criteria[:query] = { bool: {} }
      self
    end

    # TODO: single wildcard or match not in bool clause
    # commit when should and must combination working
    # provide to_searchkick method which allows a formatted criteria to be sent through a relevant model
    # push version 0.05 to rubygems

    private

      def handle_operation(operation, value)
        case operation
        when 'eq' then ''
        when 'in' then value.split(',').map(&:to_i)
        when 'wildcard-left' then '*' + value
        when 'wildcard-right' then value + '*'
        when 'wildcard' then '*' + value + '*'
        end
      end
  end
end
