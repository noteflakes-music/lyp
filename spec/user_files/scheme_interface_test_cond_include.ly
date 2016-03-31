#(assert:string=? (lyp:this-file)
  (lyp:expand-path (lyp:join-path lyp:cwd "spec/user_files/scheme_interface_test_cond_include.ly")))

#(set! cond-include #t)