(defvar porg-project-root nil)
(defvar porg-ignore-patterns '("^\\.\\.?$" "\\.org$"))

(defun porg-should-ignore (filename)
  (catch 'loop
    (dolist (p porg-ignore-patterns)
      (if (string-match p filename)
	  (throw 'loop t)))))

(defun porg-inspect-dir (&optional dir)
  (interactive)
  (if (not dir)
      (setq dir porg-project-root))
  (dolist (f (directory-files-and-attributes dir))
    (let* ((name (car f))
	   (is_dir (nth 1 f))
	   (full-path (concat dir "/" name)))
      (unless (porg-should-ignore name)
	(if is_dir
	    (porg-inspect-dir full-path)
	  (porg-file-scraper full-path))))))

(defun porg-register-todo (file todo-str)
  (set-buffer porg-buffer)
  (goto-char 0)
  (let* ((flink (format "[[file:/%s::%s][%s]]" file todo-str todo-str))
	 (pattern (format " \\(TODO|DONE\\) %s" (regexp-quote flink)))
	 (todo (format "** TODO %s\n" flink)))
    (when (not (string-match pattern (buffer-string)))
      (if (not (re-search-forward "^\* TODOs" nil t))
	  (insert "* TODOs\n")
	(vertical-motion 1))
      (message file)
      (insert todo))))

(defun porg-file-scraper (file)
  (with-temp-buffer
    (insert-file-contents file)
    (while (re-search-forward "TODO \\(.*\\)$" nil t)
      (save-excursion
	(porg-register-todo file (match-string 1))))))

(defun porg-mode ()
  (interactive)
  (setq porg-project-root (file-name-directory buffer-file-name))
  (setq porg-buffer (current-buffer)))

(setq auto-mode-alist
      (append '((".project.org" . porg-mode))
	      auto-mode-alist))