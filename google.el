;;; google.el --- Google Search in Emacs.            -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Qiqi Jin

;; Author: Qiqi Jin <ginqi7@gmail.com>
;; Keywords: lisp

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(require 'websocket-bridge)

(setq google-ts-path
      (concat (file-name-directory load-file-name) "google.ts"))

(defcustom google-puppeteer-executable-path "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  "Executable path for puppeteer.")

(defcustom google-puppeteer-user-data-dir
  (file-truename "~/Library/Application Support/Google/Chrome/")
  "Browser user data dir for puppeteer.")

(defcustom google-puppeteer-debug nil
  "When it is t, it will close puppeteer headless mode for debug.")

(setq google-search-item "")
(setq google-search-results "")

(websocket-bridge-app-start "google" "deno run -A --unstable" google-ts-path)

(defun google ()
  "Google."
  (interactive)
  (google-search
   (read-string "Search In google: " nil google-search-item google-search-item)))


(defun google-search (str)
  "Google search STR."
  (if (string= str google-search-item)
      (google-show-results google-search-results)
    (setq google-search-item str)
    (websocket-bridge-call "google" "search" str)))

(defun google-restart ()
  "Restart google app."
  (interactive)
  (websocket-bridge-app-exit "google")
  (websocket-bridge-app-start "google" "deno run -A --unstable" google-ts-path))

(defun google-show-results (results)
  "Show google RESULTS."
  (setq google-search-results results)
  (let* ((results-vector
          (json-parse-string
           (replace-regexp-in-string "\n" "" results)))
         (results-list (append results-vector nil))
         (titles
          (mapcar (lambda (item) (gethash "title" item)) results-list))
         (selected-title
          (completing-read "Select Google result: " titles))
         (selected-item
          (car
           (seq-filter
            (lambda (item)
              (string= selected-title (gethash "title" item)))
            results-list))))
    (browse-url (gethash "link" selected-item))))

(provide 'google)
;;; google.el ends here
