#(begin
  (assert:string=? (lyp:this-file)
   (lyp:expand-path (lyp:join-path lyp:cwd "spec/user_files/scheme_interface_test_3.ly")))
  (assert:string=? (lyp:this-dir)
   (lyp:expand-path (lyp:join-path lyp:cwd "spec/user_files")))
  
  (module-define! (current-module) 'test:temp1 0)
  (lyp:finalize (lambda () (module-define! (current-module) 'test:temp1 1)))

  (lyp:call-finalizers)
  (assert:eq? (module-ref (current-module) 'test:temp1) 1)
)

