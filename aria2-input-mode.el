;;; aria2-input-mode.el --- Major mode for Aria2 input files -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Omid Momenzadeh

;; Author: Omid Momenzadeh <omid.mnzadeh@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: tools

;; This file is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.

;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A major ode based on outline-mode for Aria2 input files.
;;
;; This mode provides syntax highlighting and basic auto-completion
;; for Aria2 input files.

;;; Code:

(require 'rx)

(defgroup aria2-input nil
  "Major mode Aria2 input files."
  :group 'tools)

(defconst aria2-input-keywords
  '("all-proxy"
    "all-proxy-passwd"
    "all-proxy-user"
    "allow-overwrite"
    "allow-piece-length-change"
    "always-resume"
    "async-dns"
    "auto-file-renaming"
    "bt-enable-hook-after-hash-check"
    "bt-enable-lpd"
    "bt-exclude-tracker"
    "bt-external-ip"
    "bt-force-encryption"
    "bt-hash-check-seed"
    "bt-load-saved-metadata"
    "bt-max-peers"
    "bt-metadata-only"
    "bt-min-crypto-level"
    "bt-prioritize-piece"
    "bt-remove-unselected-file"
    "bt-request-peer-speed-limit"
    "bt-require-crypto"
    "bt-save-metadata"
    "bt-seed-unverified"
    "bt-stop-timeout"
    "bt-tracker"
    "bt-tracker-connect-timeout"
    "bt-tracker-interval"
    "bt-tracker-timeout"
    "check-integrity"
    "checksum"
    "conditional-get"
    "connect-timeout"
    "content-disposition-default-utf8"
    "continue"
    "dir"
    "dry-run"
    "enable-http-keep-alive"
    "enable-http-pipelining"
    "enable-mmap"
    "enable-peer-exchange"
    "file-allocation"
    "follow-metalink"
    "follow-torrent"
    "force-save"
    "ftp-passwd"
    "ftp-pasv"
    "ftp-proxy"
    "ftp-proxy-passwd"
    "ftp-proxy-user"
    "ftp-reuse-connection"
    "ftp-type"
    "ftp-user"
    "gid"
    "hash-check-only"
    "header"
    "http-accept-gzip"
    "http-auth-challenge"
    "http-no-cache"
    "http-passwd"
    "http-proxy"
    "http-proxy-passwd"
    "http-proxy-user"
    "http-user"
    "https-proxy"
    "https-proxy-passwd"
    "https-proxy-user"
    "index-out"
    "lowest-speed-limit"
    "max-connection-per-server"
    "max-download-limit"
    "max-file-not-found"
    "max-mmap-limit"
    "max-resume-failure-tries"
    "max-tries"
    "max-upload-limit"
    "metalink-base-uri"
    "metalink-enable-unique-protocol"
    "metalink-language"
    "metalink-location"
    "metalink-os"
    "metalink-preferred-protocol"
    "metalink-version"
    "min-split-size"
    "no-file-allocation-limit"
    "no-netrc"
    "no-proxy"
    "out"
    "parameterized-uri"
    "pause"
    "pause-metadata"
    "piece-length"
    "proxy-method"
    "realtime-chunk-checksum"
    "referer"
    "remote-time"
    "remove-control-file"
    "retry-wait"
    "reuse-uri"
    "rpc-save-upload-metadata"
    "seed-ratio"
    "seed-time"
    "select-file"
    "split"
    "ssh-host-key-md"
    "stream-piece-selector"
    "timeout"
    "uri-selector"
    "use-head"
    "user-agent")
  "Aria2's supported keywords in Input Files as described in its manual.")

(defconst aria2-input-hash-rx-alist
  `(("sha-1"   . (repeat 40 xdigit))
    ("sha-224" . (repeat 56 xdigit))
    ("sha-256" . (repeat 64 xdigit))
    ("sha-384" . (repeat 96 xdigit))
    ("sha-512" . (repeat 128 xdigit))
    ("md5"     . (repeat 32 xdigit))
    ("adler32" . (repeat 8 xdigit)))
  "Aria2's supported hashing algorithms.")

(defvar aria2-input-keywords-rx
  (rx-to-string
   `(seq
     bol
     (1+ space)
     (group-n 1 bow (or ,@aria2-input-keywords) eow))))

(defvar aria2-input-hash-names-rx
  (rx-to-string
   `(seq
     "checksum="
     (group-n 1
       (or ,@(mapcar #'car aria2-input-hash-rx-alist)))
     eow)))

(defvar aria2-input-hash-values-rx
  (rx-to-string
   `(seq
     "checksum="
     (group-n 1
       (or ,@(mapcar
              (lambda (pair)
                (pcase-let ((`(,name . ,value) pair))
                  `(seq ,name "=" (group-n 2 ,value))))
              aria2-input-hash-rx-alist)))
     eol)))

(defvar aria2-input-keywords-lock
  `((,aria2-input-keywords-rx 1 font-lock-keyword-face)
    (,aria2-input-hash-names-rx 1 font-lock-builtin-face)
    (,aria2-input-hash-values-rx 2 font-lock-builtin-face)))

;;; Auto-completion

(defconst thing-at-point-kebab-regexp
  (rx (seq bow (1+ (in "-" letter digit))))
  "A regular expression mathing a kebab-case word.")

(put 'kebab 'bounds-of-thing-at-point
     (lambda ()
       (let ((thing (thing-at-point-looking-at
                     thing-at-point-kebab-regexp 500)))
         (if thing
             (let ((beginning (match-beginning 0))
                   (end (match-end 0)))
               (cons beginning end))))))

(put 'kebab 'thing-at-point
     (lambda ()
       (let ((boundary-pair (bounds-of-thing-at-point 'kebab)))
         (if boundary-pair
             (buffer-substring-no-properties
              (car boundary-pair) (cdr boundary-pair))))))

(defun aria2-input-completion ()
  "This is the function to be used for the hook `completion-at-point-functions'."
  (interactive)
  (pcase-let ((`(,start . ,end) (bounds-of-thing-at-point 'kebab)))
    (if (save-excursion
          (beginning-of-line)
          (looking-at (rx (seq bol (1+ space) "checksum="))))
        (list start end (mapcar #'car aria2-input-hash-rx-alist) . nil)
      (list start end aria2-input-keywords . nil))))

;;;###autoload
(define-derived-mode aria2-input-mode
  outline-mode "Aria2"
  "Major mode for Aria2's input files."
  (setq-local comment-start "#")
  (setq-local outline-regexp (rx (1+ (in "#" ?\f))))
  (add-hook 'completion-at-point-functions 'aria2-input-completion nil 'local)
  (font-lock-add-keywords 'aria2-input-mode aria2-input-keywords-lock)

  ;; Fontify the current buffer
  (when (bound-and-true-p font-lock-mode)
    (if (fboundp 'font-lock-flush)
        (font-lock-flush)
      (with-no-warnings (font-lock-fontify-buffer)))))

(provide 'aria2-input-mode)
;;; aria2-input-mode.el ends here
