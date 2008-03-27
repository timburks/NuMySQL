;; source files
(set @m_files     (filelist "^objc/.*.m$"))
(set @nu_files 	  (filelist "^nu/.*nu$"))

(set mysql_cflags ((NSString stringWithShellCommand:"mysql_config --cflags") chomp))
(set mysql_libs   ((NSString stringWithShellCommand:"mysql_config --libs") chomp))

(set SYSTEM ((NSString stringWithShellCommand:"uname") chomp))
(case SYSTEM
      ("Darwin"
               (set @cflags "-g -std=gnu99 -DDARWIN #{mysql_cflags}")
               (set @ldflags "-framework Foundation -framework Nu #{mysql_libs}"))
      ("Linux"
              (set @arch (list "i386"))
              (set @cflags "-g -std=gnu99 -DLINUX -fconstant-string-class=NSConstantString #{mysql_cflags}")
              (set @ldflags "-L/usr/local/lib -lNuFound -lNu #{mysql_libs}"))
      (else nil))

;; framework description
(set @framework "NuMySQL")
(set @framework_identifier "nu.programming.numysql")
(set @framework_creator_code "????")

(compilation-tasks)
(framework-tasks)

(task "clobber" => "clean" is
      (SH "rm -rf #{@framework_dir}"))

(task "default" => "framework")

(task "doc" is (SH "nudoc"))

(task "install" => "framework" is
      (SH "sudo rm -rf /Library/Frameworks/#{@framework}.framework")
      (SH "ditto #{@framework}.framework /Library/Frameworks/#{@framework}.framework"))

(task "test" => "framework" is
      (SH "nutest test/test_*.nu"))
