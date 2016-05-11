;;; highlight-test.el --- syntax highlighting test for fluentd-mode

;; Copyright (C) 2016 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'ert)

(ert-deftest tag-and-values-highlight ()
  "highlighting one tag and values"
  (with-fluenntd-temp-buffer
    "
   <source>
     type forward
     port 24224
   </source>
"
    (forward-cursor-on "<source>")
    (should (face-at-cursor-p 'fluentd-tag))

    (forward-cursor-on "type")
    (should (face-at-cursor-p 'fluentd-parameter-name))
    (forward-cursor-on "forward")
    (should (face-at-cursor-p 'fluentd-parameter-value))

    (forward-cursor-on "port")
    (should (face-at-cursor-p 'fluentd-parameter-name))
    (forward-cursor-on "24224")
    (should (face-at-cursor-p 'fluentd-parameter-value))

    (forward-cursor-on "</source>")
    (should (face-at-cursor-p 'fluentd-tag))))

(ert-deftest tag-parameter-highlight ()
  "highlighting one tag and values"
  (with-fluenntd-temp-buffer
    "
<match myapp.access>
  type file
  path /var/log/fluent/access
</match>
"
    (forward-cursor-on "<match")
    (should (face-at-cursor-p 'fluentd-tag))

    (forward-cursor-on "myapp\\.access")
    (should (face-at-cursor-p 'fluentd-tag-parameter))))

;;; highlight-test.el ends here
