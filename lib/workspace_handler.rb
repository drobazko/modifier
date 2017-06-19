require 'csv'
require 'date'

class WorkspaceHandler
  DEFAULT_CSV_OPTIONS = { col_sep: '|', headers: :first_row }
  EXTENDED_CSV_OPTIONS = DEFAULT_CSV_OPTIONS.merge({ row_sep: "\r\n" })
  LINES_PER_FILE = 120000

  def initialize(base_folder: "#{Dir.pwd}/data", index_column: 'Clicks')
    @base_folder = base_folder
    @index_column = index_column
  end

  def latest_file
    @file_path = Dir["#{@base_folder}/project_*_*_performancedata.txt"]
      .map{|v| v =~ /(\d+-\d+-\d+)\_\D/; { fname: v, date: DateTime.parse($1) } }
      .sort_by{|v| v[:date]}
      .last[:fname]
    self
  end

  def parse(file_path)
    CSV.read(file_path, DEFAULT_CSV_OPTIONS)
  end

  def lazy_read
    Enumerator.new do |yielder|
      CSV.foreach(@file_path, DEFAULT_CSV_OPTIONS) do |row|
        yielder.yield(row)
      end
    end
  end

  def write(content, headers, file_path)
    CSV.open(file_path, 'wb', EXTENDED_CSV_OPTIONS) do |csv|
      csv << headers
      content.each do |row|
        csv << row
      end
    end
  end

  def sort
    output = "#{@file_path}.sorted"
    content_as_table = parse(@file_path)

    headers = content_as_table.headers
    index_of_key = headers.index(@index_column)
    content = content_as_table.sort_by { |a| -a[index_of_key].to_i }
    write(content, headers, output)
    @file_path = output
    self
  end

  def output_with_pagination(merged_data)
    done = false
    file_index = 0
    while not done do
      CSV.open("#{base_file_path}_#{file_index}.txt", 'wb', EXTENDED_CSV_OPTIONS) do |csv|
        headers_written = false
        line_count = 0
        while line_count < LINES_PER_FILE
          begin
            merged = merged_data.next
            if not headers_written
              csv << merged.keys
              headers_written = true
              line_count += 1
            end
            csv << merged
            line_count += 1
          rescue StopIteration
            done = true
            break
          end
        end
        file_index += 1
      end
    end
  end

  private

  def base_file_path
    @file_path.gsub(/\.txt|\.sorted/, '')
  end
end
