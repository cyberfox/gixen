desc "Run a simple coverage analysis."
task :coverage do
  system("rcov --sort coverage -x '/Library' -x _test_ -I test/ test/*.rb")
end
