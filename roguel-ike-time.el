;;; roguel-ike-time.el --- Time management

;; Copyright (C) 2014 Steven Rémot

;;; Author: Steven Rémot

;;; License:
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Contains time management class
;; Time management is currently implemented using a priority queue.

;; Each entity has a priority associated to it.
;; This priority first equals its speed.

;; In each iteration, the entity with the highest priority (E)
;; is choosen.  This one initiates an action, and return the
;; number of turns the action took (T).
;; The priority P of the entity is now P - T

;; For each other entity (EE), its priority PP is now :
;; PP + T / Speed(E) * Speed(EE)

;; This system can be generalized for every generic event if necesary.

;; The hero is a special case, as it suspends the algorithm
;; when the hero is the entity with the best priority, the
;; time management algorithm is suspended.

;; In order to be able to stop and resume the time management
;; algorithm anywhere, the algorithm is not implemented exactly
;; as introduced before.  When the algorithm asks the entity to
;; do an action, it also sends a callback to the entity.
;; At the end of its action, the entity must call the callback,
;; Returning it the number of turns the action took.  The callback
;; will update priorities and resume the algorithm.

;;; Code:

(require 'eieio)

;;;;;;;;;;;;;;
;; Generics ;;
;;;;;;;;;;;;;;

;; The objects handled by the time management system
;; must implemented these generics.

(defgeneric get-speed (object)
  "Return the speed of an object.")

(defgeneric do-action (object callback)
  "Do an action.
Must send the number of turns took by the action in the callback.")

;;;;;;;;;;;;;;;;;;;;
;; Priority queue ;;
;;;;;;;;;;;;;;;;;;;;

(defclass rlk--time-priority-queue ()
  ((objects :initarg :objects
            :initform ()
            :type list
            :protection :private
            :documentation "List of conses containing objects and given priorities."))
  "Priotity queue.
Handle objects with given priority.
Can update priorities, and retrieve object with higher priority.")

(defmethod insert-object ((self rlk--time-priority-queue) object)
  "Insert OBJECT with the initial priority set to its speed."
  (let ((object-cons (cons object (float (get-speed object))))
        (objects (oref self objects)))
    (add-to-list 'objects object-cons)
    (oset self objects objects)))

(defmethod remove-object ((self rlk--time-priority-queue) object)
  "Remove OBJECT from the priority queue."
  (let ((new-queue '()))
    (dolist (object-cons (oref self objects))
      (unless (equal (car object-cons) object)
        (add-to-list 'new-queue object-cons)))
    (oset self objects new-queue)))

(defmethod get-prioritized-object ((self rlk--time-priority-queue))
  "Return the object with the highest priority."
  (let ((prioritized-object nil)
        (max-priority 0))
    (dolist (object-cons (oref self objects))
      (let ((object (car object-cons))
            (priority (cdr object-cons)))
        (when (> priority max-priority)
          (setq max-priority priority)
          (setq prioritized-object object))))
    prioritized-object))

(defmethod update-priorities ((self rlk--time-priority-queue) updated-object turns-spent)
  "Update all priorities knowing that UPDATED-OBJECT has spent TURNS-SPENT turns."
  (dolist (object-cons (oref self objects))
    (let ((object (car object-cons)))
      (setf (cdr object-cons) (cond ((equal object updated-object)
                                     (- (cdr object-cons) (float turns-spent)))
                                    (t
                                     (+ (cdr object-cons)
                                        (* (/ (float turns-spent) (float (get-speed updated-object)))
                                           (float (get-speed object))))))))))

;;;;;;;;;;;;;;;;;;
;; Time manager ;;
;;;;;;;;;;;;;;;;;;

(defclass rlk--time-manager ()
  ((queue :type rlk--time-priority-queue
          :protection :private
          :documentation "Inner priority queue.")
   (current-object :initform nil
                   :protection :private
                   :documentation "The object currently doing an action."))
  "Time management algorithm.")

(defmethod initialize-instance :after ((self rlk--time-manager) slots)
  "Initialize priority queue."
  (oset self queue (rlk--time-priority-queue "Priority queue")))

(defmethod insert-object ((self rlk--time-manager) object)
  "Add an object to the priority queue."
  (insert-object (oref self queue) object))

(defmethod remove-object ((self rlk--time-manager) object)
  "Remove an object from the priority queue."
  (remove-object (oref self queue) object))

(defmethod resume-step ((self rlk--time-manager) turns-spent)
  "Updates priorities with current object and TURNS-SPENT, and initiate a new step."
  (update-priorities (oref self queue) (oref self current-object) turns-spent)
  (do-step self))

(defmethod get-resume-callback ((self rlk--time-manager))
  "Return a callback to call resume-step with SELF already binded."
  (apply-partially 'resume-step self))

(defmethod do-step ((self rlk--time-manager))
  "Ask an object to do an action, giving it the callback to resume the algorithm."
  (let ((object (get-prioritized-object (oref self queue))))
    (oset self current-object object)
    (do-action object (get-resume-callback self))))

(provide 'roguel-ike-time)
;;; roguel-ike-time.el ends here
