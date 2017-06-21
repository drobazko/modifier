# to run the script
ruby runner.rb

The code does the following:
1. Retrieves list of files from a file storage (e.g. workspace)
2. Gets a file with the most recent date fetched from a file name using the template 
3. Sorts the file rows by value in Click column
4. Merges and modifies file content:
  - if a single file is passed, the app makes only conversion of values according to the rules
  - if rows with the same Unique ID have the same row number in passed files, the app combines (according to the rules) values of rows with the same Unique ID 
  - if set of files are passed and rows with the same Unique ID have different row numbers in files, the app combines rows assuming that rows with the less Unique ID would be included in result file first.
