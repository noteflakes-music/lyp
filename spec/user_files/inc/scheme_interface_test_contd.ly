#(assert:string=? (lyp:this-file)
  (lyp:expand-path (lyp:join-path lyp:cwd "spec/user_files/inc/scheme_interface_test_contd.ly")))

#(assert:string=? (lyp:this-dir)
  (lyp:expand-path (lyp:join-path lyp:cwd "spec/user_files/inc")))

\pinclude "../scheme_interface_test_3.ly"