;; source files
(set @m_files     (filelist "^objc/.*.m$"))
(set @nu_files 	  (filelist "^nu/.*nu$"))

(set SYSTEM ((NSString stringWithShellCommand:"uname") chomp))
(case SYSTEM
      ("Darwin"
               (set @cflags "-g -std=gnu99 -DDARWIN -I/usr/local/mysql/include/mysql")
               (set @ldflags "-framework Foundation -framework Nu -lmysqlclient -L/usr/local/mysql/lib/mysql"))
      ("Linux"
              (set @arch (list "i386"))
              (set @cflags "-g -DLINUX -I/usr/local/mysql/include -fconstant-string-class=NSConstantString ")
              (set @ldflags "-L/usr/local/lib -lNuFound -lNu -lmysqlclient -L/usr/local/mysql/lib/mysql"))
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
