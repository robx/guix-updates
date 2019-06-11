(define-module (kakoune)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages text-editors))

(define-public kakoune-dev
  (package (inherit kakoune)
    (name "kakoune-dev")
    (version "2019.06.07-git")
    (source
     (origin
       (method git-fetch)
       (file-name (git-file-name name version))
       (uri
         (git-reference
           (url "https://github.com/mawww/kakoune.git")
           (commit "09e1ec97a9d7925c9d4411f4f274919aeea1bf75")))
       (sha256
        (base32 "05in7g7czdjz2xdk2ai963a9via3dlsx04pyy3gr32dn1zgg7na5"))))
    (native-inputs
     `(("asciidoc" ,asciidoc)
       ("pkg-config" ,pkg-config)
       ("gcc" ,gcc-7)))
    (arguments
     `(#:make-flags
       (list (string-append "PREFIX=" (assoc-ref %outputs "out")))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-source
           (lambda _
             ;; kakoune uses confstr with _CS_PATH to find out where to find
             ;; a posix shell, but this doesn't work in the build
             ;; environment. This substitution just replaces that result
             ;; with the "sh" path.
             (substitute* "src/shell_manager.cc"
               (("if \\(m_shell.empty\\(\\)\\)" line)
                (string-append "m_shell = \"" (which "sh")
                               "\";\n        " line)))
             #t))
         (add-after 'patch-source 'make-test-output-writable
           (lambda _
             ;; kakoune copies "in" files to a temporary directory and edits
             ;; them there, so they should be writable.
             (for-each (lambda (file) (chmod file #o644))
                       (find-files "test" "^in$"))
             #t))
         (add-before 'configure 'fixgcc7
           (lambda _
             (unsetenv "C_INCLUDE_PATH")
             (unsetenv "CPLUS_INCLUDE_PATH")
             #t))
         (delete 'configure)            ; no configure script
         ;; kakoune requires us to be in the src/ directory to build
         (add-before 'build 'chdir
           (lambda _ (chdir "src") #t)))))))
