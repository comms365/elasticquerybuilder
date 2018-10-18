require 'elasticquerybuilder/version'
require 'elasticquerybuilder/modals'

module ElasticQueryBuilder
  # main class that generates elastic criteria
  class Engine
    attr_reader :criteria
    def initialize
      @criteria = { query: {} }
      @modal = ''
    end

    # opts = [{field,value,operation},{field,value,operation}]
    def must
      @modal = ElasticQueryBuilder::Modals.must
      self
    end

    # used for matching strings
    def term(opts)
      setup_query('term', opts)
    end

    # used for matching a value within an array
    def terms(opts, default_operator = 'in')
      setup_query('terms', opts, default_operator)
    end

    # used for wildcards. supports whole wildcard, left and right matching
    def wildcard(opts, default_operator = 'wildcard')
      setup_query('wildcard', opts, default_operator)
    end

    def single_match(opts)
      setup_query('match', opts)
    end

    def should
      @modal = ElasticQueryBuilder::Modals.should
      self
    end

    def bool
      @criteria[:query] = { bool: {} }
      self
    end

    private

      def handle_operation(operation, value)
        case operation
        when 'eq' then value
        when 'in' then value.split(',').map(&:to_i)
        when 'wildcard-left' then '*' + value
        when 'wildcard-right' then value + '*'
        when 'wildcard' then '*' + value + '*'
        end
      end

      def populate_data(opts, default_operator)
        data = {}
        opts.each do |option, _value|
          val = if !option.include? :operation
                  handle_operation(default_operator, option[:value])
                else
                  handle_operation(option[:operation], option[:value])
                end
          data[option[:field]] = val
        end
        data
      end

      def setup_query(key, opts, default_operator = 'eq')
        prev = @modal.to_sym
        formulate_query_structure(prev, key, opts, default_operator)
        self
      end

      def formulate_query_structure(prev, key, opts, default_operator)
        if @criteria[:query].include? :bool
          @criteria[:query][:bool][prev] = [] unless @criteria[:query][:bool].include? prev
          bool_query = true
        else
          bool_query = false
          @criteria[:query] = []
        end
        after_formulate_query_structure(prev, bool_query, key, opts, default_operator)
      end

      def after_formulate_query_structure(prev, bool_query, key, opts, default_operator)
        data = populate_data(opts, default_operator)
        if bool_query
          @criteria[:query][:bool][prev].push(key.to_sym => data)
        elsif opts.count > 1
          @criteria[:query].push(key.to_sym => data)
        else
          @criteria[:query] = { key.to_sym => {} }
          @criteria[:query][key.to_sym] = data
        end
        bool_query
      end
  end
end
