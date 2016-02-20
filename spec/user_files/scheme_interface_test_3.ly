#(assert:string=? (lyp:this-file)
  (lyp:expand-path (lyp:join-path lyp:cwd "spec/user_files/scheme_interface_test_3.ly")))

#(assert:string=? (lyp:this-dir)
  (lyp:expand-path (lyp:join-path lyp:cwd "spec/user_files")))

