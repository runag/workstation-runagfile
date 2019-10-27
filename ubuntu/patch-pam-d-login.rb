lines = STDIN.each_line.to_a

last_auth = lines.rindex{|line| line =~ /^auth/ }

lines[0 .. last_auth].each {|line| puts line }

puts "auth       optional   pam_gnome_keyring.so"

after_auth = lines[last_auth+1 .. -1]

last_session = after_auth.rindex{|line| line =~ /^session/ }

after_auth[0 .. last_session].each {|line| puts line }

puts "session    optional   pam_gnome_keyring.so auto_start"

after_auth[last_session+1 .. -1].each {|line| puts line }
