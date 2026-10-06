# Validates LLM-generated SQL before execution.
#
# Ensures the SQL is a safe, read-only SELECT statement that only
# references allowlisted tables and contains no injection vectors.
# Ported from fantasy-hof's QuerySqlValidator (minus league scoping —
# this app is single-league).
#
# Usage:
#   QuerySqlValidator.validate!("SELECT * FROM games LIMIT 10")
class QuerySqlValidator
  class InvalidQueryError < StandardError; end

  MAX_SQL_LENGTH = 5000

  ALLOWED_TABLES = QuerySchemaBuilder::ALLOWED_TABLES

  FORBIDDEN_KEYWORDS = %w[
    INSERT UPDATE DELETE DROP ALTER TRUNCATE
    CREATE GRANT REVOKE COPY EXECUTE
  ].freeze

  SYSTEM_CATALOG_PATTERNS = [
    /\bpg_catalog\b/i,
    /\bpg_\w+/i,
    /\binformation_schema\b/i
  ].freeze

  def self.validate!(sql)
    new(sql).validate!
  end

  def initialize(sql)
    @sql = sql.to_s
  end

  def validate!
    check_length
    check_select_only
    check_forbidden_keywords
    check_no_semicolons
    check_no_system_catalogs
    check_allowed_tables
    @sql
  end

  private

  def check_length
    return if @sql.length <= MAX_SQL_LENGTH

    raise InvalidQueryError, "SQL exceeds maximum length of #{MAX_SQL_LENGTH} characters"
  end

  def check_select_only
    normalized = @sql.gsub(%r{/\*.*?\*/}m, "").strip
    return if normalized.match?(/\A(SELECT|WITH)\b/i)

    raise InvalidQueryError, "Only SELECT statements are allowed"
  end

  def check_forbidden_keywords
    # Strip string literals so values like 'drop' don't trigger false positives
    sql_without_strings = @sql.gsub(/'[^']*'/, "''")

    FORBIDDEN_KEYWORDS.each do |keyword|
      next unless sql_without_strings.match?(/\b#{keyword}\b/i)

      raise InvalidQueryError, "Forbidden keyword detected: #{keyword}"
    end
  end

  def check_no_semicolons
    return unless @sql.include?(";")

    raise InvalidQueryError, "Semicolons are not allowed (prevents multi-statement injection)"
  end

  def check_no_system_catalogs
    SYSTEM_CATALOG_PATTERNS.each do |pattern|
      next unless @sql.match?(pattern)

      raise InvalidQueryError, "System catalog references are not allowed"
    end
  end

  def check_allowed_tables
    referenced = extract_table_references
    disallowed = referenced - ALLOWED_TABLES
    return if disallowed.empty?

    raise InvalidQueryError, "Disallowed table(s) referenced: #{disallowed.join(', ')}"
  end

  # SQL functions whose syntax embeds FROM/IN keywords — e.g.
  # EXTRACT(YEAR FROM CURRENT_DATE), SUBSTRING(s FROM 2), TRIM(LEADING FROM s),
  # POSITION(a IN b) — must not have their bodies mistaken for table
  # references. Handles one level of nested parens.
  FROM_BEARING_FUNCTIONS = /\b(?:EXTRACT|SUBSTRING|TRIM|OVERLAY|POSITION)\s*\([^()]*(?:\([^()]*\)[^()]*)*\)/i.freeze

  def extract_table_references
    tables = Set.new
    cte_names = extract_cte_names
    scannable = @sql.gsub(FROM_BEARING_FUNCTIONS, " ")

    # Match FROM and JOIN clauses
    scannable.scan(/\b(?:FROM|JOIN)\s+(\w+)/i) do |match|
      tables.add(match[0].downcase)
    end

    (tables - cte_names).to_a
  end

  def extract_cte_names
    names = Set.new
    # Match CTE definitions: WITH name AS (...) or , name AS (...)
    @sql.scan(/(?:\bWITH\s+|,\s*)(\w+)\s+AS\s*\(/i) do |match|
      names.add(match[0].downcase)
    end
    names
  end
end
