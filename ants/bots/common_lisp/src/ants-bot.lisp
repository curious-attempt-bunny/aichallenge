;;;; ants-bot.lisp
;;;;
;;;;  author: Erik Winkels (aerique@xs4all.nl)
;;;; created: 2011-03-01
;;;; license: Apache Software License
;;;;   notes: tested on SBCL 1.0.45.debian

(in-package :ants-bot)


;;; Main Program

;; This MAIN is used on the competition server.
(defun main (&key (log nil) (state (make-instance 'state)) (verbose nil))
  (let ((*state* state)
        (*verbose* verbose))
    (cond ((and log *verbose*)
           (setf (slot-value *state* 'log-stream)
                 (open log :direction :output :if-exists :append
                           :if-does-not-exist :create)))
          (*verbose*
           (setf (slot-value *state* 'log-stream) *debug-io*)))
    (logmsg "~&=== New Match: " (current-date-time-string) " ===~%")
    (handler-bind ((sb-sys:interactive-interrupt #'interrupted-by-user))
      (loop while (handler-case (peek-char nil (input *state*) nil)
                    (sb-int:simple-stream-error nil))
            for end-of-game-p = (parse-game-state)
            when end-of-game-p do (loop-finish)
            do (logmsg "--- turn: " (turn *state*) " ---~%")
               (logmsg "~&[start] " (current-date-time-string) "~%")
               (bot-think)
               (end-of-turn)
               (logmsg "~&[  end] move took " (turn-time-used) " seconds ("
                       (turn-time-remaining) " left).~%")))))


;; This MAIN is called when you use the Makefile locally.
(defun main-for-local (&key (log "ants-bot.log") (verbose t))
  (main :log log :verbose verbose))


;; TODO fix proxy-bot for Ant Wars
;; This MAIN is for the Slime REPL with bin/play-proxy-game.sh.
(defun main-for-proxybot (&key (log "ants-bot-proxied.log") (verbose t))
  (let ((socket (make-instance 'inet-socket :type :stream :protocol :tcp))
        client input output stream)
    (handler-bind ((address-in-use-error #'address-in-use))
      (socket-bind socket #(127 0 0 1) 41807)
      (socket-listen socket 0)
      (format *debug-io* "Waiting for connection...~%")
      (force-output)
      (setf client (socket-accept socket)
            stream (socket-make-stream client :input t :output t
                                       :element-type 'character
                                       :buffering :line)
            input stream
            output stream)
      (format *debug-io* "Connected. Playing game...~%")
      (force-output))
    (unwind-protect
         (main :state (make-instance 'state :input input :output output)
               :log log :verbose verbose)
      (socket-close client)
      (socket-close socket)
      (format *debug-io* "Game finished. Connection closed...~%"))))
